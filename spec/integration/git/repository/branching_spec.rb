# frozen_string_literal: true

require 'spec_helper'
require 'git/repository'
require 'git/repository/branching'

RSpec.describe Git::Repository::Branching, :integration do
  include_context 'in an empty repository'

  let(:execution_context) { Git::ExecutionContext::Repository.from_base(repo) }
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
        repo.lib.checkout(sha)
      end

      it "returns 'HEAD'" do
        expect(described_instance.current_branch).to eq('HEAD')
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
        repo.add_remote('origin', bare_dir)
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
        repo.add_remote('origin', bare_dir)
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
        repo.add_remote('origin', bare_dir)
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
          .to raise_error(Git::Error)
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
end
