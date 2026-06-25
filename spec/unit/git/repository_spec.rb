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
      let(:vanishing_file) do
        File.join(repo_dir, 'vanishing.txt')
      end
      before do
        File.write(vanishing_file, 'z' * 500)
        allow(File).to receive(:lstat).and_wrap_original do |original, path|
          if File.expand_path(path) == File.expand_path(vanishing_file)
            raise Errno::ENOENT,
                  path
          end

          original.call(path)
        end
      end

      it 'skips the missing file and totals the remaining files' do
        expect(repo_size).to eq(150)
      end
    end
  end

  describe '#lib' do
    subject(:lib_result) { described_instance.lib }

    it 'returns self' do
      allow(Git::Deprecation).to receive(:warn)
      expect(lib_result).to be(described_instance)
    end

    it 'emits a deprecation warning' do
      allow(Git::Deprecation).to receive(:warn)
      described_instance.lib
      expect(Git::Deprecation).to have_received(:warn).with(
        a_string_including('Git::Repository#lib', 'deprecated', 'v6.0.0')
      )
    end
  end

  describe 'Git::Configuring mixin' do
    it 'is included in Git::Repository so that all config_* methods are available' do
      expect(described_class.ancestors).to include(Git::Configuring)
    end

    describe 'assert_valid_scope! allows all repository scopes' do
      let(:get_command) { instance_double(Git::Commands::ConfigOptionSyntax::Get) }

      before do
        allow(Git::Commands::ConfigOptionSyntax::Get)
          .to receive(:new).with(execution_context).and_return(get_command)
        allow(get_command).to receive(:call).and_return(command_result(''))
      end

      it 'allows local: scope' do
        expect { described_instance.config_get('user.name', local: true) }.not_to raise_error
      end

      it 'allows global: scope' do
        expect { described_instance.config_get('user.name', global: true) }.not_to raise_error
      end

      it 'allows system: scope' do
        expect { described_instance.config_get('user.name', system: true) }.not_to raise_error
      end

      it 'allows worktree: scope' do
        expect { described_instance.config_get('user.name', worktree: true) }.not_to raise_error
      end

      it 'allows file: scope' do
        expect { described_instance.config_get('user.name', file: '/tmp/config') }.not_to raise_error
      end

      it 'allows blob: scope' do
        expect { described_instance.config_get('user.name', blob: 'HEAD:.gitconfig') }.not_to raise_error
      end
    end
  end
end
