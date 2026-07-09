# frozen_string_literal: true

require 'spec_helper'

# Integration tests for the Git module factory entry points: Git.open, Git.bare,
# Git.init, and Git.clone.
#
# These exercise real path resolution against real repositories on disk and verify
# that each entry point returns a properly configured Git::Repository.

RSpec.describe Git, :integration do
  include Git::IntegrationTestHelpers

  describe '.open' do
    include_context 'in an empty repository'

    subject(:repository) { Git.open(repo_dir, options) }

    let(:options) { {} }

    it 'returns a Git::Repository' do
      expect(repository).to be_a(Git::Repository)
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

    context 'when opening a submodule checkout' do
      context 'with a submodule added at the repository root' do
        let(:submodule_parent_dir) { Dir.mktmpdir('submodule_parent') }
        let(:submodule_dir) { File.join(submodule_parent_dir, 'submodule') }
        let(:main_repo_dir) { File.join(submodule_parent_dir, 'repo') }

        let(:submodule_repo) do
          submodule = init_test_repo(submodule_dir)
          File.write(File.join(submodule_dir, 'README.md'), '# Submodule')
          submodule.add('README.md')
          submodule.commit('Add README.md')
          submodule
        end

        before do
          submodule_repo
          main = init_test_repo(main_repo_dir)
          File.write(File.join(main_repo_dir, 'README.md'), '# Main Repository')
          main.add('README.md')
          main.commit('Add README.md')

          Dir.chdir(main_repo_dir) do
            system('git', '-c', 'protocol.file.allow=always', 'submodule', 'add', '../submodule', 'submodule',
                   out: File::NULL, err: File::NULL, exception: true)
            system('git', 'commit', '-am', 'Add submodule', out: File::NULL, err: File::NULL, exception: true)
          end
        end

        after { FileUtils.rm_rf(submodule_parent_dir) }

        it "resolves the submodule checkout's HEAD to the submodule's own commit" do
          submodule_checkout = Git.open(File.join(main_repo_dir, 'submodule'))
          expect(submodule_checkout.object('HEAD').sha).to eq(submodule_repo.object('HEAD').sha)
        end
      end

      context 'with a submodule containing a nested subdirectory' do
        let(:submodule_parent_dir) { Dir.mktmpdir('submodule_parent') }
        let(:submodule_dir) { File.join(submodule_parent_dir, 'submodule') }
        let(:main_repo_dir) { File.join(submodule_parent_dir, 'repo') }

        before do
          submodule = init_test_repo(submodule_dir)
          FileUtils.mkdir_p(File.join(submodule_dir, 'subdir'))
          File.write(File.join(submodule_dir, 'subdir', 'README.md'), '# Submodule')
          submodule.add('subdir/README.md')
          submodule.commit('Add README.md')

          main = init_test_repo(main_repo_dir)
          File.write(File.join(main_repo_dir, 'README.md'), '# Main Repository')
          main.add('README.md')
          main.commit('Add README.md')

          Dir.chdir(main_repo_dir) do
            system('git', '-c', 'protocol.file.allow=always', 'submodule', 'add', '../submodule', 'submodule',
                   out: File::NULL, err: File::NULL, exception: true)
            system('git', 'commit', '-am', 'Add submodule', out: File::NULL, err: File::NULL, exception: true)
          end
        end

        after { FileUtils.rm_rf(submodule_parent_dir) }

        it 'resolves the repository root to the submodule when opened from its subdirectory' do
          submodule_subdir_checkout = Git.open(File.join(main_repo_dir, 'submodule', 'subdir'))
          expect(submodule_subdir_checkout.ls_files.keys).to include('subdir/README.md')
        end
      end
    end
  end

  describe '.bare' do
    subject(:repository) { Git.bare(bare_dir) }

    let(:bare_dir) { Dir.mktmpdir }

    before { Git.init(bare_dir, bare: true) }

    after { FileUtils.rm_rf(bare_dir) }

    it 'returns a Git::Repository' do
      expect(repository).to be_a(Git::Repository)
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
    subject(:repository) { Git.clone(source_dir, clone_dir) }

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
      expect(repository).to be_a(Git::Repository)
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

      subject(:repository) { Git.clone(source_dir, bare_clone_dir, bare: true) }

      it 'returns a Git::Repository' do
        expect(repository).to be_a(Git::Repository)
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

      subject(:repository) { Git.clone(source_dir, 'my-clone', chdir: chdir_dir) }

      it 'returns a Git::Repository' do
        expect(repository).to be_a(Git::Repository)
      end

      it 'sets #dir to the clone subdirectory within chdir' do
        expected_path = File.join(chdir_dir, 'my-clone')
        expect(repository.dir).to eq(Pathname.new(expected_path))
      end
    end

    context 'with :index option' do
      let(:custom_index) { File.join(parent_dir, 'custom.index') }

      subject(:repository) { Git.clone(source_dir, clone_dir, index: custom_index) }

      it 'returns a Git::Repository' do
        expect(repository).to be_a(Git::Repository)
      end

      it 'uses the given index path' do
        expect(repository.index).to eq(Pathname.new(custom_index))
      end
    end

    context 'with :repository option (separate git dir)' do
      let(:separate_git_dir) { File.join(Dir.mktmpdir, 'separate-git') }

      after { FileUtils.rm_rf(File.dirname(separate_git_dir)) }

      subject(:repository) { Git.clone(source_dir, clone_dir, repository: separate_git_dir) }

      it 'returns a Git::Repository' do
        expect(repository).to be_a(Git::Repository)
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
    subject(:repository) { Git.init(init_dir) }

    let(:init_dir) { Dir.mktmpdir }

    after { FileUtils.rm_rf(init_dir) }

    it 'returns a Git::Repository' do
      expect(repository).to be_a(Git::Repository)
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

      subject(:repository) { Git.init(bare_dir, bare: true) }

      it 'returns a Git::Repository' do
        expect(repository).to be_a(Git::Repository)
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

      subject(:repository) { Git.init(init_dir, separate_git_dir: separate_git_dir) }

      it 'returns a Git::Repository' do
        expect(repository).to be_a(Git::Repository)
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
      subject(:repository) { Git.init(init_dir, initial_branch: 'trunk') }

      it 'returns a Git::Repository' do
        expect(repository).to be_a(Git::Repository)
      end

      it 'initializes with the specified branch name' do
        head_content = File.read(File.join(repository.repo.to_s, 'HEAD'))
        expect(head_content).to include('trunk')
      end
    end
  end
end
