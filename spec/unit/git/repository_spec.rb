# frozen_string_literal: true

require 'spec_helper'
require 'git/repository'

RSpec.describe Git::Repository do
  let(:execution_context) { instance_double(Git::ExecutionContext::Repository) }
  let(:described_instance) { described_class.new(execution_context: execution_context) }

  describe '#initialize' do
    subject(:instance) { described_instance }

    it 'stores the execution context' do
      expect(instance).to have_attributes(execution_context: execution_context)
    end

    it 'raises ArgumentError when execution_context: is missing' do
      expect { described_class.new }.to raise_error(ArgumentError, /execution_context/)
    end

    it 'raises ArgumentError when execution_context: is nil' do
      expect do
        described_class.new(execution_context: nil)
      end.to raise_error(ArgumentError, /execution_context must not be nil/)
    end
  end

  describe '.open' do
    subject(:repository) { described_class.open(working_dir, options) }

    let(:working_dir) { '/repo' }
    let(:options) { {} }
    let(:resolved_paths) do
      { working_directory: '/repo', repository: '/repo/.git', index: '/repo/.git/index' }
    end

    before do
      allow(Dir).to receive(:exist?).with(working_dir).and_return(true)
      allow(Git::Repository::PathResolver).to(
        receive(:root_of_worktree)
          .with(working_dir, binary_path: :use_global_config, git_ssh: :use_global_config)
          .and_return(working_dir)
      )
      allow(Git::Repository::PathResolver).to receive(:resolve_paths).and_return(resolved_paths)
      allow(Git::ExecutionContext::Repository).to receive(:from_hash).and_return(execution_context)
    end

    it 'returns a Git::Repository' do
      expect(repository).to be_a(described_class)
    end

    it 'detects the root of the worktree when no repository option is given' do
      expect(Git::Repository::PathResolver).to(
        receive(:root_of_worktree)
          .with(working_dir, binary_path: :use_global_config, git_ssh: :use_global_config)
      )
      repository
    end

    it 'resolves the paths from the detected working directory' do
      expect(Git::Repository::PathResolver).to(
        receive(:resolve_paths).with(working_directory: working_dir, repository: nil, index: nil)
      )
      repository
    end

    it 'builds the execution context from the merged options and resolved paths' do
      expect(Git::ExecutionContext::Repository).to(
        receive(:from_hash).with(options.merge(resolved_paths), logger: nil)
      )
      repository
    end

    context 'when binary_path is given' do
      let(:options) { { binary_path: '/custom/git' } }

      it 'forwards binary_path to root_of_worktree' do
        expect(Git::Repository::PathResolver).to(
          receive(:root_of_worktree)
            .with(working_dir, binary_path: '/custom/git', git_ssh: :use_global_config)
            .and_return(working_dir)
        )
        repository
      end
    end

    context 'when git_ssh is given' do
      let(:options) { { git_ssh: '/custom/ssh' } }

      it 'forwards git_ssh to root_of_worktree' do
        expect(Git::Repository::PathResolver).to(
          receive(:root_of_worktree)
            .with(working_dir, binary_path: :use_global_config, git_ssh: '/custom/ssh')
            .and_return(working_dir)
        )
        repository
      end
    end

    context 'when git_ssh is nil (explicitly unset)' do
      let(:options) { { git_ssh: nil } }

      before do
        allow(Git::Repository::PathResolver).to(
          receive(:root_of_worktree)
            .with(working_dir, binary_path: :use_global_config, git_ssh: nil)
            .and_return(working_dir)
        )
      end

      it 'forwards nil git_ssh to root_of_worktree' do
        expect(Git::Repository::PathResolver).to(
          receive(:root_of_worktree)
            .with(working_dir, binary_path: :use_global_config, git_ssh: nil)
        )
        repository
      end
    end

    context 'when an explicit repository option is given' do
      let(:options) { { repository: '/custom/.git' } }

      it 'does not auto-detect the root of the worktree' do
        expect(Git::Repository::PathResolver).not_to receive(:root_of_worktree)
        repository
      end

      it 'forwards the repository and index options to resolve_paths' do
        expect(Git::Repository::PathResolver).to(
          receive(:resolve_paths).with(working_directory: working_dir, repository: '/custom/.git', index: nil)
        )
        repository
      end
    end

    context 'when a logger is given' do
      let(:options) { { log: instance_double(Logger) } }

      it 'forwards the logger to the execution context' do
        expect(Git::ExecutionContext::Repository).to(
          receive(:from_hash).with(anything, logger: options[:log])
        )
        repository
      end
    end

    context 'when the working directory is not a directory' do
      before { allow(Dir).to receive(:exist?).with(working_dir).and_return(false) }

      it 'raises ArgumentError' do
        expect { repository }.to raise_error(ArgumentError, /is not a directory/)
      end
    end
  end

  describe '.bare' do
    subject(:repository) { described_class.bare(git_dir, options) }

    let(:git_dir) { '/repo.git' }
    let(:options) { {} }
    let(:resolved_paths) do
      { working_directory: nil, repository: '/repo.git', index: '/repo.git/index' }
    end

    before do
      allow(Git::Repository::PathResolver).to receive(:resolve_paths).and_return(resolved_paths)
      allow(Git::ExecutionContext::Repository).to receive(:from_hash).and_return(execution_context)
    end

    it 'returns a Git::Repository' do
      expect(repository).to be_a(described_class)
    end

    it 'resolves the paths as a bare repository' do
      expect(Git::Repository::PathResolver).to(
        receive(:resolve_paths).with(repository: git_dir, bare: true)
      )
      repository
    end

    it 'builds the execution context from the merged options and resolved paths' do
      expect(Git::ExecutionContext::Repository).to(
        receive(:from_hash).with(options.merge(resolved_paths), logger: nil)
      )
      repository
    end
  end

  describe '#dir' do
    subject(:dir) { described_instance.dir }

    context 'when the execution context has a working directory' do
      before { allow(execution_context).to receive(:git_work_dir).and_return('/repo') }

      it 'returns the working directory as a Pathname' do
        expect(dir).to eq(Pathname.new('/repo'))
      end
    end

    context 'when the execution context has no working directory (bare)' do
      before { allow(execution_context).to receive(:git_work_dir).and_return(nil) }

      it 'returns nil' do
        expect(dir).to be_nil
      end
    end
  end

  describe '#repo' do
    subject(:repo) { described_instance.repo }

    context 'when the execution context has a repository directory' do
      before { allow(execution_context).to receive(:git_dir).and_return('/repo/.git') }

      it 'returns the repository directory as a Pathname' do
        expect(repo).to eq(Pathname.new('/repo/.git'))
      end
    end

    context 'when the execution context has no repository directory' do
      before { allow(execution_context).to receive(:git_dir).and_return(nil) }

      it 'returns nil' do
        expect(repo).to be_nil
      end
    end
  end

  describe '#index' do
    subject(:index) { described_instance.index }

    context 'when the execution context has an index file' do
      before { allow(execution_context).to receive(:git_index_file).and_return('/repo/.git/index') }

      it 'returns the index file as a Pathname' do
        expect(index).to eq(Pathname.new('/repo/.git/index'))
      end
    end

    context 'when the execution context has no index file' do
      before { allow(execution_context).to receive(:git_index_file).and_return(nil) }

      it 'returns nil' do
        expect(index).to be_nil
      end
    end
  end

  describe '#repo_size' do
    subject(:repo_size) { described_instance.repo_size }

    let(:repo_dir) { Dir.mktmpdir }

    before do
      allow(execution_context).to receive(:git_dir).and_return(repo_dir)
      File.write(File.join(repo_dir, 'a.txt'), 'a' * 100)
      File.write(File.join(repo_dir, 'b.txt'), 'b' * 50)
    end

    after { FileUtils.rm_rf(repo_dir) }

    it 'returns the total size in bytes of the files under the repository' do
      expect(repo_size).to be_an(Integer)
      expect(repo_size).to be >= 150
    end

    context 'when the repository directory is nil' do
      before { allow(execution_context).to receive(:git_dir).and_return(nil) }

      it 'returns zero' do
        expect(repo_size).to eq(0)
      end
    end

    context 'when the repository contains directories' do
      let(:nested_dir) { File.join(repo_dir, 'nested') }
      let(:nested_file) { File.join(nested_dir, 'c.txt') }

      before do
        FileUtils.mkdir_p(nested_dir)
        File.write(nested_file, 'c' * 25)
      end

      it 'counts only file sizes' do
        expect(repo_size).to eq(175)
      end
    end

    context 'when a file name includes double dots' do
      let(:double_dot_file) { File.join(repo_dir, 'release..notes.txt') }

      before do
        File.write(double_dot_file, 'd' * 10)
      end

      it 'includes that file in the total size' do
        expect(repo_size).to eq(160)
      end
    end

    context 'when the repository contains a symlink pointing outside the repo' do
      let(:outside_dir) { Dir.mktmpdir }
      let(:outside_file) { File.join(outside_dir, 'large.txt') }
      let(:symlink) { File.join(repo_dir, 'link') }

      before do
        File.write(outside_file, 'y' * 9999)
        File.symlink(outside_file, symlink)
      end

      after { FileUtils.rm_rf(outside_dir) }

      it 'does not count the target file size through the symlink' do
        # Symlinks are not followed, so only the two real files are counted and
        # the 9999-byte target is excluded.
        expect(repo_size).to eq(150)
      end
    end

    context 'when the repository contains a symlinked directory pointing outside the repo' do
      let(:outside_dir) { Dir.mktmpdir }
      let(:outside_file) { File.join(outside_dir, 'large.txt') }
      let(:linked_dir) { File.join(repo_dir, 'linkdir') }

      before do
        File.write(outside_file, 'y' * 9999)
        File.symlink(outside_dir, linked_dir)
      end

      after { FileUtils.rm_rf(outside_dir) }

      it 'does not count files reached through the symlinked directory' do
        # The traversal must not descend into the symlinked directory, so the
        # 9999-byte file living outside the repository is excluded.
        expect(repo_size).to eq(150)
      end
    end

    context 'when a file disappears during traversal' do
      let(:vanishing_file) { File.join(repo_dir, 'vanishing.txt') }

      before do
        File.write(vanishing_file, 'z' * 500)
        allow(File).to receive(:lstat).and_wrap_original do |original, path|
          raise Errno::ENOENT, path if File.expand_path(path) == File.expand_path(vanishing_file)

          original.call(path)
        end
      end

      it 'skips the missing file and totals the remaining files' do
        expect(repo_size).to eq(150)
      end
    end
  end
end
