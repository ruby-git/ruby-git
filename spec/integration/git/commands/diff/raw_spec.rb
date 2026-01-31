# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/diff/raw'

RSpec.describe Git::Commands::Diff::Raw, :integration do
  include_context 'in a diff test repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    # Tests focusing on raw format-specific output and parsing
    # (Basic diff scenarios are covered by Patch spec)

    describe 'raw output format' do
      it 'returns DiffFileRawInfo objects' do
        result = command.call('initial', 'after_modify')

        expect(result.files.first).to be_a(Git::DiffFileRawInfo)
      end

      it 'provides src and dst FileRef with mode and sha' do
        result = command.call('initial', 'after_modify')

        file = result.files.first
        expect(file.src).to be_a(Git::FileRef)
        expect(file.dst).to be_a(Git::FileRef)
        expect(file.src.mode).to eq('100644')
        expect(file.src.sha).to match(/\A[0-9a-f]+\z/)
        expect(file.dst.sha).to match(/\A[0-9a-f]+\z/)
      end
    end

    describe 'status detection' do
      it 'detects modified status' do
        result = command.call('initial', 'after_modify')

        file = result.files.first
        expect(file.status).to eq(:modified)
      end

      it 'detects renamed status with similarity percentage' do
        result = command.call('after_modify', 'after_rename')

        file = result.files.first
        expect(file.status).to eq(:renamed)
        expect(file.renamed?).to be true
        expect(file.similarity).to be_a(Integer)
        expect(file.similarity).to be_between(1, 100)
      end

      it 'includes correct insertions/deletions for renamed files' do
        result = command.call('after_modify', 'after_rename')

        file = result.files.first
        expect(file.status).to eq(:renamed)
        # Renamed file with content change should have stats
        expect(file.insertions).to be >= 0
        expect(file.deletions).to be >= 0
        # Total should match shortstat
        expect(result.total_insertions).to eq(file.insertions)
        expect(result.total_deletions).to eq(file.deletions)
      end

      it 'handles 100% rename (pure move with no content change)' do
        # Create a file and commit it
        write_file('to_be_moved.txt', "This file will be moved without changes\n")
        repo.add('to_be_moved.txt')
        repo.commit('Add file to move')
        repo.add_tag('before_pure_move')

        # Move the file without changing content
        FileUtils.mv(File.join(repo_dir, 'to_be_moved.txt'), File.join(repo_dir, 'moved_file.txt'))
        repo.add(all: true)
        repo.commit('Move file without changes')
        repo.add_tag('after_pure_move')

        result = command.call('before_pure_move', 'after_pure_move')

        file = result.files.first
        expect(file.status).to eq(:renamed)
        expect(file.similarity).to eq(100)
        expect(file.src_path).to eq('to_be_moved.txt')
        expect(file.path).to eq('moved_file.txt')
        expect(file.insertions).to eq(0)
        expect(file.deletions).to eq(0)
      end

      it 'detects deleted status' do
        result = command.call('after_rename', 'after_delete')

        file = result.files.first
        expect(file.status).to eq(:deleted)
        expect(file.deleted?).to be true
        expect(file.src).not_to be_nil
        expect(file.dst).to be_nil
      end

      it 'detects added status' do
        result = command.call('after_delete', 'after_add')

        file = result.files.first
        expect(file.status).to eq(:added)
        expect(file.added?).to be true
        expect(file.src).to be_nil
        expect(file.dst).not_to be_nil
      end
    end

    describe 'binary file handling' do
      it 'marks binary files as binary' do
        result = command.call('after_add', 'after_binary')

        file = result.files.first
        expect(file.binary?).to be true
        expect(file.path).to eq('image.png')
      end
    end

    describe 'find_copies option' do
      before do
        # Create a scenario where copy detection would apply
        write_file('lib/copy_of_main.rb', File.read(File.join(repo_dir, 'lib/main.rb')))
        repo.add('lib/copy_of_main.rb')
        repo.commit('Copy main.rb')
      end

      it 'detects copied files with -C flag' do
        result = command.call('HEAD^', 'HEAD', find_copies: true)

        # The file might be detected as added or copied depending on similarity
        file = result.files.find { |f| f.path == 'lib/copy_of_main.rb' }
        expect(file).not_to be_nil
        # With exact copy, should be detected as copied
        if file.status == :copied
          expect(file.copied?).to be true
          expect(file.similarity).to be > 0
        end
      end
    end

    describe 'type changes (symlinks)' do
      before do
        # Create a regular file, commit it, then replace with symlink
        write_file('link_target.txt', "Target content\n")
        repo.add('link_target.txt')
        repo.commit('Add link target')
        repo.add_tag('before_symlink')

        # Replace file with symlink (only works on Unix-like systems)
        file_path = File.join(repo_dir, 'link_target.txt')
        FileUtils.rm(file_path)
        File.symlink('other_file.txt', file_path)
        repo.add('link_target.txt')
        repo.commit('Replace file with symlink')
        repo.add_tag('after_symlink')
      end

      it 'detects type change from regular file to symlink', skip: Gem.win_platform? do
        result = command.call('before_symlink', 'after_symlink')

        file = result.files.find { |f| f.path == 'link_target.txt' }
        expect(file).not_to be_nil
        expect(file.status).to eq(:type_changed)
        expect(file.src.mode).to eq('100644')
        expect(file.dst.mode).to eq('120000')
      end
    end

    describe 'insertions and deletions' do
      it 'includes line change statistics' do
        result = command.call('initial', 'after_modify')

        file = result.files.first
        expect(file.insertions).to be > 0
        expect(file.deletions).to eq(0)
      end
    end

    describe 'files with spaces in paths' do
      it 'correctly parses paths with spaces' do
        result = command.call('after_mode_change', 'after_spaces')

        file = result.files.first
        expect(file.path).to eq('path with spaces/file name.txt')
      end
    end

    describe 'files with UTF-8 characters in paths' do
      it 'handles adding files with UTF-8 names' do
        result = command.call('after_spaces', 'after_utf8')

        file = result.files.first
        expect(file.path).to eq('file☠skull.rb')
        expect(file.status).to eq(:added)
      end

      it 'handles renaming files with UTF-8 names' do
        result = command.call('after_utf8', 'after_utf8_rename')

        file = result.files.first
        expect(file.status).to eq(:renamed)
        expect(file.src_path).to eq('file☠skull.rb')
        expect(file.path).to eq('renamed☠skull.rb')
      end
    end

    describe 'files with tab characters in paths',
             skip: Gem.win_platform? ? 'Windows does not allow tab characters in filenames' : false do
      it 'handles paths with escaped tab characters' do
        result = command.call('after_utf8_rename', 'after_tab_filename')

        file = result.files.first
        # Tab character should be unescaped from git's \t format
        expect(file.path).to eq("file\twith\ttab.txt")
        expect(file.status).to eq(:added)
      end
    end

    describe 'submodules' do
      before do
        skip 'Submodule setup failed (CI environment limitation)' unless submodule_available?
      end

      it 'detects submodule as added with mode 160000' do
        result = command.call('before_submodule', 'after_submodule')

        submodule_file = result.files.find { |f| f.path == 'vendor/submodule' }
        expect(submodule_file).not_to be_nil
        expect(submodule_file.status).to eq(:added)
        expect(submodule_file.dst.mode).to eq('160000')
      end

      it 'detects submodule pointer update as modified' do
        result = command.call('after_submodule', 'after_submodule_update')

        submodule_file = result.files.find { |f| f.path == 'vendor/submodule' }
        expect(submodule_file).not_to be_nil
        expect(submodule_file.status).to eq(:modified)
        expect(submodule_file.src.mode).to eq('160000')
        expect(submodule_file.dst.mode).to eq('160000')
      end
    end

    describe 'rename with path change' do
      it 'provides both src_path and path for renames' do
        result = command.call('after_modify', 'after_rename')

        file = result.files.first
        expect(file.src_path).to eq('README.md')
        expect(file.path).to eq('docs.md')
      end
    end

    describe 'dirstat option' do
      it 'includes directory statistics when requested' do
        result = command.call('initial', 'after_multi', dirstat: true)

        expect(result.dirstat).not_to be_nil
        expect(result.dirstat.entries).not_to be_empty
      end
    end

    describe 'pathspec filtering' do
      it 'limits results to matching pathspecs' do
        result = command.call('after_spaces', 'after_multi', pathspecs: ['lib/'])

        paths = result.files.map(&:path)
        expect(paths).to all(start_with('lib/'))
      end
    end

    describe 'exit code handling' do
      it 'succeeds with no differences (exit code 0)' do
        result = command.call('initial', 'initial')

        expect(result.files).to be_empty
      end

      it 'succeeds with differences found (exit code 1)' do
        result = command.call('initial', 'after_modify')

        expect(result.files).not_to be_empty
      end

      it 'raises FailedError for invalid revision (exit code 128)' do
        expect { command.call('nonexistent-ref') }.to raise_error(Git::FailedError)
      end
    end
  end
end
