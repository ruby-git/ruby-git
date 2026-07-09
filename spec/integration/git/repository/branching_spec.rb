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

  describe '#checkout_file' do
    before do
      write_file('README.md', "# Modified\n")
    end

    it 'restores the file to the HEAD version' do
      described_instance.checkout_file('HEAD', 'README.md')
      content = File.read(File.join(repo.dir.to_s, 'README.md'))
      expect(content).to eq("# Hello\n")
    end

    it 'returns a String' do
      result = described_instance.checkout_file('HEAD', 'README.md')
      expect(result).to be_a(String)
    end
  end

  describe '#checkout' do
    context 'checking out an existing branch' do
      before do
        repo.branch('new-branch').create
      end

      it 'switches to that branch' do
        described_instance.checkout('new-branch')
        expect(described_instance.current_branch).to eq('new-branch')
      end
    end

    context 'creating and checking out a new branch' do
      it 'creates and switches to the new branch' do
        described_instance.checkout('feature', new_branch: true, start_point: 'HEAD')
        expect(described_instance.current_branch).to eq('feature')
      end
    end

    context 'when the repository has no commits' do
      let(:unborn_repo_dir) { Dir.mktmpdir('unborn_repo') }
      let(:unborn_repo) do
        r = Git.init(unborn_repo_dir, initial_branch: 'master')
        r.config_set('user.email', 'test@example.com')
        r.config_set('user.name', 'Test User')
        r.config_set('commit.gpgsign', 'false')
        r
      end
      let(:unborn_instance) { Git::Repository.new(execution_context: unborn_repo.execution_context) }

      after { FileUtils.rm_rf(unborn_repo_dir) }

      it 'raises Git::FailedError' do
        expect { unborn_instance.checkout('master') }
          .to raise_error(Git::FailedError, /master/)
      end
    end
  end

  describe '#checkout_index' do
    before do
      write_file('indexed.txt', "indexed content\n")
      repo.add('indexed.txt')
    end

    context 'with all: true' do
      it 'returns a String' do
        result = described_instance.checkout_index(all: true, force: true)
        expect(result).to be_a(String)
      end
    end

    context 'with path_limiter' do
      it 'returns a String' do
        result = described_instance.checkout_index(path_limiter: 'indexed.txt', force: true)
        expect(result).to be_a(String)
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

      it 'returns false for a combined remote/branch name' do
        expect(described_instance.remote_branch?('origin/main')).to be(false)
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

  describe '#branch_new' do
    context 'without a start_point' do
      it 'creates the branch from the current HEAD' do
        head_sha = repo.revparse('HEAD')
        described_instance.branch_new('new-feature')
        expect(described_instance.local_branch?('new-feature')).to be(true)
        expect(repo.revparse('new-feature')).to eq(head_sha)
      end

      it 'returns nil' do
        expect(described_instance.branch_new('new-feature')).to be_nil
      end
    end

    context 'with a start_point' do
      # let! eagerly captures the SHA before the inner before block adds a second commit
      let!(:initial_sha) { repo.log(1).execute.first.sha }

      before do
        write_file('CHANGES.md', "changes\n")
        repo.add('CHANGES.md')
        repo.commit('Second commit')
      end

      it 'creates the branch at the given start_point' do
        described_instance.branch_new('from-initial', initial_sha)
        expect(described_instance.local_branch?('from-initial')).to be(true)
        expect(repo.revparse('from-initial')).to eq(initial_sha)
      end
    end

    context 'when the branch already exists' do
      before { described_instance.branch_new('duplicate') }

      it 'raises Git::FailedError' do
        expect { described_instance.branch_new('duplicate') }.to raise_error(Git::FailedError, /duplicate/)
      end
    end
  end

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

    context 'when deleting multiple branches at once' do
      it 'deletes all named branches and returns a String' do
        result = described_instance.branch_delete('branch-1', 'branch-2')
        expect(result).to be_a(String)
        expect(result).to include('branch-1')
        expect(result).to include('branch-2')
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

    context 'when the commit is on the current branch' do
      it 'returns a non-empty String' do
        result = described_instance.branch_contains(sha)
        expect(result).to be_a(String)
        expect(result).not_to be_empty
      end
    end

    context 'when a non-matching branch pattern is supplied' do
      it 'returns an empty string' do
        result = described_instance.branch_contains(sha, 'nonexistent-pattern')
        expect(result).to eq('')
      end
    end

    context 'when branch_name is nil (treated as no pattern)' do
      it 'returns a non-empty String (same branches as omitting branch_name)' do
        result = described_instance.branch_contains(sha, nil)
        expect(result).to be_a(String)
        expect(result).not_to be_empty
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #branches_all
  # ---------------------------------------------------------------------------
  #
  # branches_all delegates parsing to Git::Parsers::Branch.parse_list, which
  # means the integration tests verify the end-to-end Ruby return value against
  # real git output.

  describe '#branches_all' do
    context 'when only a local branch exists' do
      it 'returns an Array of Git::BranchInfo' do
        result = described_instance.branches_all
        expect(result).to be_an(Array)
        expect(result).to all(be_a(Git::BranchInfo))
      end

      it 'includes the current branch' do
        current = described_instance.current_branch
        refnames = described_instance.branches_all.map(&:refname)
        expect(refnames).to include(current)
      end

      it 'marks exactly one branch as current' do
        result = described_instance.branches_all
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
        result = described_instance.branches_all
        expect(result).to be_an(Array)
        expect(result).to all(be_a(Git::BranchInfo))
        expect(result.any?(&:remote?)).to be(true)
      end

      it 'includes both local and remote-tracking branches' do
        refnames = described_instance.branches_all.map(&:refname)
        expect(refnames).to include('main')
        expect(refnames.any? { |r| r.start_with?('remotes/origin/') }).to be(true)
      end
    end

    context 'when in detached HEAD state' do
      before do
        sha = repo.log(1).execute.first.sha
        repo.checkout(sha)
      end

      it 'returns an Array of Git::BranchInfo' do
        result = described_instance.branches_all
        expect(result).to be_an(Array)
        expect(result).to all(be_a(Git::BranchInfo))
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #update_ref
  # ---------------------------------------------------------------------------

  describe '#update_ref' do
    before do
      repo.branch('feature').create
      write_file('CHANGES.md', "changes\n")
      repo.add('CHANGES.md')
      repo.commit('Second commit')
    end

    it 'points the branch ref at the given commit SHA' do
      new_sha = repo.revparse('HEAD')
      described_instance.update_ref('feature', new_sha)
      expect(repo.revparse('refs/heads/feature')).to eq(new_sha)
    end

    it 'returns a Git::CommandLine::Result' do
      result = described_instance.update_ref('feature', repo.revparse('HEAD'))
      expect(result).to be_a(Git::CommandLine::Result)
    end
  end

  # ---------------------------------------------------------------------------
  # #branch (factory)
  # ---------------------------------------------------------------------------

  describe '#branch' do
    it 'returns a Git::Branch for the given name' do
      result = described_instance.branch('main')
      expect(result).to be_a(Git::Branch)
      expect(result.full).to eq('main')
    end

    it 'defaults to the current branch when no name is given' do
      result = described_instance.branch
      expect(result).to be_a(Git::Branch)
      expect(result.full).to eq(described_instance.current_branch)
    end
  end

  # ---------------------------------------------------------------------------
  # #current_branch_state
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
