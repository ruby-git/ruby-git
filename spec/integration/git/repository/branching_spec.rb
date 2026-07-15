# frozen_string_literal: true

require 'spec_helper'
require 'git/repository'
require 'git/repository/branching'

RSpec.describe Git::Repository::Branching, :integration do
  include_context 'in an empty repository'

  let(:described_instance) { Git::Repository.new(execution_context: execution_context) }

  # Create an initial commit so we have a proper HEAD
  before do
    write_file('README.md', "# Hello\n")
    repo.add('README.md')
    repo.commit('Initial commit')
  end

  describe '#current_branch' do
    context 'when on the default branch' do
      it 'returns the current branch name (a non-empty string)' do
        branch_name = described_instance.current_branch
        expect(branch_name).to be_a(String)
        expect(branch_name).not_to be_empty
      end
    end

    context 'in detached HEAD state' do
      before do
        sha = repo.log(1).execute.first.sha
        repo.checkout(sha)
      end

      it "returns 'HEAD'" do
        expect(described_instance.current_branch).to eq('HEAD')
      end
    end

    context 'when the repository has no commits (unborn branch)' do
      let(:unborn_repo_dir) { Dir.mktmpdir('unborn_repo') }
      let(:unborn_repo) do
        r = Git.init(unborn_repo_dir, initial_branch: 'new-branch')
        r.config_set('user.email', 'test@example.com')
        r.config_set('user.name', 'Test User')
        r
      end
      let(:unborn_instance) { Git::Repository.new(execution_context: unborn_repo.execution_context) }

      after { FileUtils.rm_rf(unborn_repo_dir) }

      it 'returns the initial branch name' do
        expect(unborn_instance.current_branch).to eq('new-branch')
      end
    end
  end

  describe '#local_branch?' do
    context 'when the branch exists locally' do
      it 'returns true' do
        expect(described_instance.local_branch?('main')).to be(true)
      end
    end

    context 'when the branch does not exist locally' do
      it 'returns false' do
        expect(described_instance.local_branch?('nonexistent')).to be(false)
      end
    end
  end

  describe '#remote_branch?' do
    context 'when no remotes are configured' do
      it 'returns false for any branch name' do
        expect(described_instance.remote_branch?('main')).to be(false)
      end
    end

    context 'when a remote is configured and a branch has been pushed' do
      let(:bare_dir) { Dir.mktmpdir('bare_repo') }

      after { FileUtils.rm_rf(bare_dir) }

      before do
        Git.init(bare_dir, bare: true)
        repo.remote_add('origin', bare_dir)
        repo.push('origin', 'main')
      end

      it 'returns true for the short branch name' do
        expect(described_instance.remote_branch?('main')).to be(true)
      end

      it 'returns false for the combined remote/branch name' do
        expect(described_instance.remote_branch?('origin/main')).to be(false)
      end
    end
  end

  describe '#branch?' do
    context 'when the branch exists locally' do
      it 'returns true' do
        expect(described_instance.branch?('main')).to be(true)
      end
    end

    context 'when the branch does not exist locally or remotely' do
      it 'returns false' do
        expect(described_instance.branch?('nonexistent')).to be(false)
      end
    end

    context 'when the branch exists only as a remote-tracking branch' do
      let(:bare_dir) { Dir.mktmpdir('bare_repo') }

      after { FileUtils.rm_rf(bare_dir) }

      before do
        Git.init(bare_dir, bare: true)
        repo.remote_add('origin', bare_dir)
        repo.push('origin', 'main')
        # Push a second branch to the remote, then delete it locally so it only
        # exists as a remote-tracking branch
        repo.branch('remote-only').create
        repo.push('origin', 'remote-only')
        repo.branch('remote-only').delete
      end

      it 'returns true' do
        expect(described_instance.branch?('remote-only')).to be(true)
      end
    end

    context '4.x backward-compatibility: combined remote/branch name' do
      let(:bare_dir) { Dir.mktmpdir('bare_repo') }

      after { FileUtils.rm_rf(bare_dir) }

      before do
        Git.init(bare_dir, bare: true)
        repo.remote_add('origin', bare_dir)
        repo.push('origin', 'main')
      end

      it 'returns false for origin/main (remote branches matched by short name only)' do
        expect(described_instance.branch?('origin/main')).to be(false)
      end
    end

    context '4.x backward-compatibility: local branch with slashes' do
      before do
        repo.branch('topic/main').create
        repo.checkout('topic/main')
        repo.branch('main').delete
      end

      it 'returns false for main when only topic/main exists (exact-name matching, no suffix matching)' do
        expect(described_instance.branch?('main')).to be(false)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #branch_new
  # ---------------------------------------------------------------------------

  # ---------------------------------------------------------------------------
  # #branch_delete
  # ---------------------------------------------------------------------------
  #
  # branch_delete is a single-command delegator with one piece of facade-owned
  # post-processing: it raises Git::Error (not Git::FailedError) when the
  # command exits with status 1. The scenarios below verify the end-to-end Ruby
  # behavior that the command's own integration tests cannot exercise in
  # isolation.

  describe '#branch_delete' do
    before do
      repo.branch('to-delete').create
      repo.branch('branch-1').create
      repo.branch('branch-2').create
    end

    context 'when deleting a single merged branch' do
      it 'returns a String that names the deleted branch' do
        result = described_instance.branch_delete('to-delete')
        expect(result).to be_a(String)
        expect(result).to include('to-delete')
      end
    end

    context 'when deleting an unmerged branch (force: true is the default)' do
      before do
        current = described_instance.current_branch
        repo.checkout('to-delete')
        write_file('unmerged.txt', "unmerged work\n")
        repo.add('unmerged.txt')
        repo.commit('Unmerged commit')
        repo.checkout(current)
      end

      it 'deletes the branch without error and returns a String' do
        result = described_instance.branch_delete('to-delete')
        expect(result).to be_a(String)
        expect(result).to include('to-delete')
      end
    end

    context 'when the branch does not exist' do
      it 'raises Git::Error' do
        expect { described_instance.branch_delete('nonexistent-branch') }
          .to raise_error(Git::Error, /nonexistent-branch/)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #change_head_branch
  # ---------------------------------------------------------------------------
  #
  # change_head_branch is a single-command delegator. Integration tests verify
  # both the unborn-branch initialization workflow (no prior commits) and the
  # post-commit case (HEAD symbolic ref rewired to a new refs/heads/ entry).

  describe '#change_head_branch' do
    context 'with an unborn repository (no commits)' do
      let(:unborn_repo_dir) { Dir.mktmpdir('unborn_repo') }
      let(:unborn_repo) { Git.init(unborn_repo_dir) }
      let(:unborn_execution_context) { unborn_repo.execution_context }
      let(:unborn_instance) { Git::Repository.new(execution_context: unborn_execution_context) }

      after { FileUtils.rm_rf(unborn_repo_dir) }

      it 'changes HEAD to point at the given branch name' do
        unborn_instance.change_head_branch('my-branch')
        expect(unborn_instance.current_branch).to eq('my-branch')
      end
    end

    context 'with a repository that already has commits' do
      it 'rewrites the HEAD symbolic ref to refs/heads/<branch_name>' do
        described_instance.change_head_branch('other')
        head_content = File.read(File.join(repo_dir, '.git', 'HEAD')).strip
        expect(head_content).to eq('ref: refs/heads/other')
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #branch_contains
  # ---------------------------------------------------------------------------
  #
  # branch_contains is a single-command delegator; however, the facade owns
  # the pattern-vs-no-pattern argument pre-processing (nil/empty branch_name
  # omits the positional arg), which real git exercises end-to-end.

  describe '#branch_contains' do
    let(:sha) { repo.revparse('HEAD') }

    context 'when branch_name is nil (treated as no pattern)' do
      it 'returns a non-empty String (same branches as omitting branch_name)' do
        result = described_instance.branch_contains(sha, nil)
        expect(result).to be_a(String)
        expect(result).not_to be_empty
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #branch_list
  # ---------------------------------------------------------------------------
  #
  # branch_list delegates parsing to Git::Parsers::Branch.parse_list, which
  # means the integration tests verify the end-to-end Ruby return value against
  # real git output.

  describe '#branch_list' do
    context 'when only a local branch exists' do
      it 'returns an Array of Git::BranchInfo' do
        result = described_instance.branch_list
        expect(result).to be_an(Array)
        expect(result).to all(be_a(Git::BranchInfo))
      end

      it 'includes the current branch' do
        current = described_instance.current_branch
        short_names = described_instance.branch_list.map(&:short_name)
        expect(short_names).to include(current)
      end

      it 'marks exactly one branch as current' do
        result = described_instance.branch_list
        current_branches = result.select(&:current)
        expect(current_branches.length).to eq(1)
      end
    end

    context 'when a remote-tracking branch exists' do
      let(:bare_dir) { Dir.mktmpdir('bare_repo') }

      after { FileUtils.rm_rf(bare_dir) }

      before do
        Git.init(bare_dir, bare: true)
        repo.remote_add('origin', bare_dir)
        repo.push('origin', 'main')
      end

      it 'returns an Array of Git::BranchInfo that includes the remote-tracking branch' do
        result = described_instance.branch_list
        expect(result).to be_an(Array)
        expect(result).to all(be_a(Git::BranchInfo))
        expect(result.any?(&:remote?)).to be(true)
      end

      it 'includes both local and remote-tracking branches' do
        branches = described_instance.branch_list
        expect(branches.map(&:short_name)).to include('main')
        expect(branches.any?(&:remote?)).to be(true)
      end
    end

    context 'when in detached HEAD state' do
      before do
        sha = repo.log(1).execute.first.sha
        repo.checkout(sha)
      end

      it 'returns an Array of Git::BranchInfo' do
        result = described_instance.branch_list
        expect(result).to be_an(Array)
        expect(result).to all(be_a(Git::BranchInfo))
      end
    end

    context 'when a local branch has a configured upstream (issue #1270)' do
      let(:bare_dir) { Dir.mktmpdir('bare_repo') }

      after { FileUtils.rm_rf(bare_dir) }

      before do
        Git.init(bare_dir, bare: true)
        repo.remote_add('origin', bare_dir)
        repo.branch('foo').create
        repo.checkout('foo')
        repo.push('origin', 'foo:bar')
        repo.config_set('branch.foo.remote', 'origin')
        repo.config_set('branch.foo.merge', 'refs/heads/bar')
      end

      it 'returns a BranchInfo whose upstream is the raw upstream refname string' do
        foo = described_instance.branch_list.find { |b| b.short_name == 'foo' }
        expect(foo.upstream).to eq('refs/remotes/origin/bar')
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #update_ref
  # ---------------------------------------------------------------------------

  # ---------------------------------------------------------------------------
  # #branch (factory): upstream data is not populated by git.branch(name) —
  # use git.branch_list to obtain BranchInfo with upstream tracking data.
  # ---------------------------------------------------------------------------

  #
  # current_branch_state calls both ShowCurrent and RevParse, so integration
  # tests confirm the multi-command orchestration produces the correct HeadState
  # value across all three possible HEAD states.

  describe '#current_branch_state' do
    context 'when HEAD is on an active branch (has commits)' do
      it 'returns HeadState with state :active' do
        result = described_instance.current_branch_state
        expect(result).to be_a(Git::Repository::Branching::HeadState)
        expect(result.state).to eq(:active)
      end

      it 'returns the current branch name as the name attribute' do
        result = described_instance.current_branch_state
        expect(result.name).to eq(described_instance.current_branch)
      end
    end

    context 'in detached HEAD state (checked out at a commit SHA directly)' do
      before do
        sha = repo.log(1).execute.first.sha
        repo.checkout(sha)
      end

      it 'returns HeadState with state :detached and name HEAD' do
        result = described_instance.current_branch_state
        expect(result.state).to eq(:detached)
        expect(result.name).to eq('HEAD')
      end
    end

    context 'on an unborn branch (repository initialized with no commits)' do
      let(:unborn_repo_dir) { Dir.mktmpdir('unborn_repo') }
      let(:unborn_repo) { Git.init(unborn_repo_dir) }
      let(:unborn_execution_context) { unborn_repo.execution_context }
      let(:unborn_instance) { Git::Repository.new(execution_context: unborn_execution_context) }

      after { FileUtils.rm_rf(unborn_repo_dir) }

      it 'returns HeadState with state :unborn' do
        result = unborn_instance.current_branch_state
        expect(result.state).to eq(:unborn)
      end

      it 'returns the initial branch name (not HEAD)' do
        result = unborn_instance.current_branch_state
        expect(result.name).not_to eq('HEAD')
        expect(result.name).to be_a(String)
        expect(result.name).not_to be_empty
      end
    end
  end
end
