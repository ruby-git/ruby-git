# frozen_string_literal: true

require 'spec_helper'
require 'git/repository'

# Integration tests for Git::Repository factory class methods and the path
# accessors (#dir, #repo, #index, #repo_size) they configure.
#
# These exercise real path resolution against real repositories on disk. The
# top-level Git.open, Git.bare, Git.init, and Git.clone entry points all return
# Git::Repository as of Step C1d.

RSpec.describe Git::Repository, :integration do
  include Git::IntegrationTestHelpers

  describe '.open' do
    include_context 'in an empty repository'

    subject(:repository) { described_class.open(repo_dir, options) }

    let(:options) { {} }

    it 'returns a Git::Repository' do
      expect(repository).to be_a(described_class)
    end

    it 'exposes the working directory through #dir' do
      expect(repository.dir).to eq(Pathname.new(repo_dir).realpath)
    end

    it 'exposes the repository directory through #repo' do
      expect(repository.repo).to eq(Pathname.new(File.join(repo_dir, '.git')).realpath)
    end

    it 'exposes the index file through #index' do
      expect(repository.index).to eq(repository.repo.join('index'))
    end

    it 'reports a positive repository size through #repo_size' do
      expect(repository.repo_size).to be > 0
    end

    context 'when given an explicit repository path' do
      let(:options) { { repository: File.join(repo_dir, '.git') } }

      it 'uses the given repository directory' do
        expect(repository.repo).to eq(Pathname.new(File.join(repo_dir, '.git')))
      end
    end
  end

  describe '.bare' do
    subject(:repository) { described_class.bare(bare_dir) }

    let(:bare_dir) { Dir.mktmpdir }

    before { Git.init(bare_dir, bare: true) }

    after { FileUtils.rm_rf(bare_dir) }

    it 'returns a Git::Repository' do
      expect(repository).to be_a(described_class)
    end

    it 'has no working directory' do
      expect(repository.dir).to be_nil
    end

    it 'exposes the bare repository directory through #repo' do
      expect(repository.repo).to eq(Pathname.new(bare_dir))
    end

    it 'reports a positive repository size through #repo_size' do
      expect(repository.repo_size).to be > 0
    end
  end

  describe '.clone' do
    subject(:repository) { described_class.clone(source_dir, clone_dir) }

    let(:source_dir) { Dir.mktmpdir }
    let(:parent_dir) { Dir.mktmpdir }
    let(:clone_dir) { File.join(parent_dir, 'cloned') }

    before do
      source = init_test_repo(source_dir)
      File.write(File.join(source_dir, 'README.md'), '# Test')
      source.add('README.md')
      source.commit('Initial commit')
    end

    after do
      FileUtils.rm_rf(source_dir)
      FileUtils.rm_rf(parent_dir)
    end

    it 'returns a Git::Repository' do
      expect(repository).to be_a(described_class)
    end

    it 'sets #dir to the cloned working directory' do
      expect(repository.dir).to be_a(Pathname)
      expect(repository.dir.directory?).to be(true)
    end

    it 'sets #repo to the .git directory inside the clone' do
      expect(repository.repo).to be_a(Pathname)
      expect(repository.repo.directory?).to be(true)
    end

    it 'sets #index to the index file inside .git' do
      expect(repository.index).to eq(repository.repo.join('index'))
    end

    context 'when cloning as bare' do
      let(:bare_clone_dir) { File.join(parent_dir, 'cloned.git') }

      subject(:repository) { described_class.clone(source_dir, bare_clone_dir, bare: true) }

      it 'returns a Git::Repository' do
        expect(repository).to be_a(described_class)
      end

      it 'has no working directory' do
        expect(repository.dir).to be_nil
      end

      it 'sets #repo to the bare repository directory' do
        expect(repository.repo).to be_a(Pathname)
        expect(repository.repo.directory?).to be(true)
      end
    end

    context 'with :chdir option' do
      let(:chdir_dir) { Dir.mktmpdir }

      after { FileUtils.rm_rf(chdir_dir) }

      subject(:repository) { described_class.clone(source_dir, 'my-clone', chdir: chdir_dir) }

      it 'returns a Git::Repository' do
        expect(repository).to be_a(described_class)
      end

      it 'sets #dir to the clone subdirectory within chdir' do
        expected_path = File.join(chdir_dir, 'my-clone')
        expect(repository.dir).to eq(Pathname.new(expected_path))
      end
    end

    context 'with :index option' do
      let(:custom_index) { File.join(parent_dir, 'custom.index') }

      subject(:repository) { described_class.clone(source_dir, clone_dir, index: custom_index) }

      it 'returns a Git::Repository' do
        expect(repository).to be_a(described_class)
      end

      it 'uses the given index path' do
        expect(repository.index).to eq(Pathname.new(custom_index))
      end
    end

    context 'with :repository option (separate git dir)' do
      let(:separate_git_dir) { File.join(Dir.mktmpdir, 'separate-git') }

      after { FileUtils.rm_rf(File.dirname(separate_git_dir)) }

      subject(:repository) { described_class.clone(source_dir, clone_dir, repository: separate_git_dir) }

      it 'returns a Git::Repository' do
        expect(repository).to be_a(described_class)
      end

      it 'sets #repo to the separate git directory' do
        expect(repository.repo).to eq(Pathname.new(separate_git_dir).realpath)
      end

      it 'creates a .git gitfile in the worktree pointing at the separate git dir' do
        repository
        gitfile = File.join(File.realpath(clone_dir), '.git')
        expect(File).to be_file(gitfile)
        expect(File.read(gitfile)).to start_with('gitdir:')
      end
    end
  end

  describe '.init' do
    subject(:repository) { described_class.init(init_dir) }

    let(:init_dir) { Dir.mktmpdir }

    after { FileUtils.rm_rf(init_dir) }

    it 'returns a Git::Repository' do
      expect(repository).to be_a(described_class)
    end

    it 'sets #dir to the initialized working directory' do
      expect(repository.dir).to be_a(Pathname)
      expect(repository.dir.directory?).to be(true)
    end

    it 'sets #repo to the .git directory' do
      expect(repository.repo).to be_a(Pathname)
      expect(repository.repo.directory?).to be(true)
    end

    it 'sets #index to the index path inside .git' do
      expect(repository.index).to eq(repository.repo.join('index'))
    end

    context 'with :bare option' do
      let(:bare_dir) { Dir.mktmpdir }

      after { FileUtils.rm_rf(bare_dir) }

      subject(:repository) { described_class.init(bare_dir, bare: true) }

      it 'returns a Git::Repository' do
        expect(repository).to be_a(described_class)
      end

      it 'has no working directory' do
        expect(repository.dir).to be_nil
      end

      it 'sets #repo to the bare repository directory' do
        expect(repository.repo).to be_a(Pathname)
        expect(repository.repo.directory?).to be(true)
      end
    end

    context 'with :separate_git_dir option' do
      let(:separate_git_dir) { File.join(init_dir, 'git-objects') }

      subject(:repository) { described_class.init(init_dir, separate_git_dir: separate_git_dir) }

      it 'returns a Git::Repository' do
        expect(repository).to be_a(described_class)
      end

      it 'stores the .git data in the separate directory' do
        expect(repository.repo).to eq(Pathname.new(separate_git_dir))
      end

      it 'writes a gitfile pointer in the working directory' do
        repository
        gitfile = File.join(init_dir, '.git')
        expect(File.file?(gitfile)).to be(true)
        expect(File.read(gitfile)).to match(/\Agitdir:/)
      end
    end

    context 'with :initial_branch option' do
      subject(:repository) { described_class.init(init_dir, initial_branch: 'trunk') }

      it 'returns a Git::Repository' do
        expect(repository).to be_a(described_class)
      end

      it 'initializes with the specified branch name' do
        head_content = File.read(File.join(repository.repo.to_s, 'HEAD'))
        expect(head_content).to include('trunk')
      end
    end
  end

  describe 'top-level entry points return Git::Repository' do
    include_context 'in an empty repository'

    it 'Git.open returns a Git::Repository' do
      expect(Git.open(repo_dir)).to be_a(Git::Repository)
    end

    it 'Git.bare returns a Git::Repository' do
      bare_dir = Dir.mktmpdir
      Git.init(bare_dir, bare: true)
      expect(Git.bare(bare_dir)).to be_a(Git::Repository)
    ensure
      FileUtils.rm_rf(bare_dir)
    end

    it 'Git.init returns a Git::Repository' do
      init_dir = Dir.mktmpdir
      expect(Git.init(init_dir)).to be_a(Git::Repository)
    ensure
      FileUtils.rm_rf(init_dir)
    end

    it 'Git.clone returns a Git::Repository' do
      clone_dir = Dir.mktmpdir
      expect(Git.clone(repo_dir, 'clone', chdir: clone_dir)).to be_a(Git::Repository)
    ensure
      FileUtils.rm_rf(clone_dir)
    end
  end

  describe '#config_get' do
    include_context 'in an empty repository'

    let(:described_instance) { Git::Repository.new(execution_context: execution_context) }

    it 'returns a Git::ConfigEntryInfo for an existing key' do
      entry = described_instance.config_get('user.name')

      expect(entry).to be_a(Git::ConfigEntryInfo)
      expect(entry.value).to eq('Test User')
    end

    it 'returns nil when the key does not exist' do
      entry = described_instance.config_get('nonexistent.key', local: true)

      expect(entry).to be_nil
    end
  end

  describe '#config_list' do
    include_context 'in an empty repository'

    let(:described_instance) { Git::Repository.new(execution_context: execution_context) }

    it 'returns an Array of Git::ConfigEntryInfo objects' do
      entries = described_instance.config_list

      expect(entries).to be_an(Array)
      expect(entries).to all(be_a(Git::ConfigEntryInfo))
    end

    it 'includes an entry for user.name from local config' do
      entries = described_instance.config_list(local: true)

      user_name_entry = entries.find { |e| e.key == 'user.name' }
      expect(user_name_entry).not_to be_nil
      expect(user_name_entry.value).to eq('Test User')
    end
  end
end
