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
        sha = repo.log(1).first.sha
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
end
