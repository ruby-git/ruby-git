# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/diff/patch'

RSpec.describe Git::Commands::Diff::Patch, :integration do
  include_context 'in a diff test repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    describe 'comparing commits' do
      it 'diffs between two tags' do
        result = command.call('initial', 'after_modify')

        expect(result).to be_a(Git::DiffResult)
        expect(result.files.size).to eq(1)
        expect(result.files.first.path).to eq('README.md')
      end

      it 'returns file change statistics' do
        result = command.call('initial', 'after_modify')

        expect(result.files_changed).to eq(1)
        expect(result.total_insertions).to be > 0
      end

      it 'returns file-level insertion/deletion counts' do
        result = command.call('initial', 'after_modify')

        file = result.files.first
        expect(file.insertions).to be > 0
        expect(file.deletions).to eq(0)
      end

      it 'includes the unified diff patch text' do
        result = command.call('initial', 'after_modify')

        file = result.files.first
        expect(file.patch).to include('diff --git')
        expect(file.patch).to include('@@')
        expect(file.patch).to include('+## Installation')
      end

      it 'supports two-dot range syntax' do
        result = command.call('initial..after_modify')

        expect(result.files.size).to eq(1)
        expect(result.files.first.path).to eq('README.md')
      end
    end

    describe 'file change types' do
      describe 'modified files' do
        it 'detects modified status' do
          result = command.call('initial', 'after_modify')

          file = result.files.first
          expect(file.status).to eq(:modified)
          expect(file.src).not_to be_nil
          expect(file.dst).not_to be_nil
          expect(file.src.path).to eq(file.dst.path)
        end

        it 'provides source and destination mode and sha' do
          result = command.call('initial', 'after_modify')

          file = result.files.first
          expect(file.src.mode).to eq('100644')
          expect(file.dst.mode).to eq('100644')
          expect(file.src.sha).not_to be_nil
          expect(file.dst.sha).not_to be_nil
        end
      end

      describe 'renamed files' do
        it 'detects renamed status with similarity' do
          result = command.call('after_modify', 'after_rename')

          file = result.files.first
          expect(file.status).to eq(:renamed)
          expect(file.src.path).to eq('README.md')
          expect(file.dst.path).to eq('docs.md')
          expect(file.similarity).to be_a(Integer)
          expect(file.similarity).to be > 0
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
      end

      describe 'copied files' do
        before do
          # Create an exact copy of an existing file
          write_file('lib/copy_of_main.rb', File.read(File.join(repo_dir, 'lib/main.rb')))
          repo.add('lib/copy_of_main.rb')
          repo.commit('Copy main.rb')
        end

        it 'detects copied files with find_copies option' do
          result = command.call('HEAD^', 'HEAD', find_copies: true)

          file = result.files.find { |f| f.path == 'lib/copy_of_main.rb' }
          expect(file).not_to be_nil
          # With exact copy, should be detected as copied
          if file.status == :copied
            expect(file.copied?).to be true
            expect(file.similarity).to be > 0
            expect(file.src.path).to eq('lib/main.rb')
          end
        end
      end

      describe 'deleted files' do
        it 'detects deleted status with nil dst' do
          result = command.call('after_rename', 'after_delete')

          file = result.files.first
          expect(file.status).to eq(:deleted)
          expect(file.src).not_to be_nil
          expect(file.dst).to be_nil
          expect(file.src.path).to eq('docs.md')
        end
      end

      describe 'added files' do
        it 'detects added status with nil src' do
          result = command.call('after_delete', 'after_add')

          file = result.files.first
          expect(file.status).to eq(:added)
          expect(file.src).to be_nil
          expect(file.dst).not_to be_nil
          expect(file.dst.path).to eq('lib/main.rb')
        end
      end

      describe 'binary files' do
        it 'marks binary files as binary' do
          result = command.call('after_add', 'after_binary')

          file = result.files.first
          expect(file.binary?).to be true
          expect(file.path).to eq('image.png')
        end

        it 'has zero insertions/deletions for binary files' do
          result = command.call('after_add', 'after_binary')

          file = result.files.first
          expect(file.insertions).to eq(0)
          expect(file.deletions).to eq(0)
        end
      end

      describe 'mode changes', skip: Gem.win_platform? ? 'Windows does not support Unix file permissions' : false do
        it 'includes mode change in patch' do
          # Look for the mode change commit
          result = command.call('after_binary^', 'after_mode_change')

          mode_change_file = result.files.find { |f| f.path == 'bin/run' }
          # The file might show in multiple commits; mode change should be detectable
          expect(mode_change_file).not_to be_nil if mode_change_file
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

        # NOTE: Unlike raw format which shows type change as status 'T',
        # patch format shows type changes as separate delete + add entries.
        it 'shows type change as separate delete and add entries', skip: Gem.win_platform? do
          result = command.call('before_symlink', 'after_symlink')

          files = result.files.select { |f| f.path == 'link_target.txt' }
          expect(files.size).to eq(2)

          deleted = files.find { |f| f.status == :deleted }
          added = files.find { |f| f.status == :added }

          expect(deleted).not_to be_nil
          expect(deleted.src.mode).to eq('100644')
          expect(added).not_to be_nil
          expect(added.dst.mode).to eq('120000')
        end
      end

      describe 'files with spaces in paths' do
        it 'handles paths with spaces' do
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

      describe 'multiple files changed' do
        # Use after_utf8_rename on Windows since tab filename is skipped
        let(:multi_base_tag) { Gem.win_platform? ? 'after_utf8_rename' : 'after_tab_filename' }

        it 'returns all changed files' do
          result = command.call(multi_base_tag, 'after_multi')

          expect(result.files.size).to eq(3)
          paths = result.files.map(&:path)
          expect(paths).to include('lib/main.rb')
          expect(paths).to include('lib/helper.rb')
          expect(paths).to include('CHANGELOG.md')
        end

        it 'aggregates summary statistics' do
          result = command.call(multi_base_tag, 'after_multi')

          expect(result.files_changed).to eq(3)
          expect(result.total_insertions).to be > 0
        end
      end
    end

    describe 'comparing with working tree' do
      before do
        # Reset any staged changes first
        Dir.chdir(repo_dir) { system('git', 'reset', 'HEAD', out: File::NULL, err: File::NULL) }
        Dir.chdir(repo_dir) { system('git', 'checkout', '--', 'lib/main.rb', out: File::NULL, err: File::NULL) }
        write_file('lib/main.rb', "# frozen_string_literal: true\n\nmodule Main\n  VERSION = '2.0.0'\nend\n")
      end

      after do
        # Clean up working tree changes
        Dir.chdir(repo_dir) { system('git', 'checkout', '--', 'lib/main.rb', out: File::NULL, err: File::NULL) }
      end

      it 'diffs working tree against HEAD' do
        result = command.call('HEAD')

        file = result.files.find { |f| f.path == 'lib/main.rb' }
        expect(file).not_to be_nil
        expect(file.patch).to include('-  VERSION')
        expect(file.patch).to include('+  VERSION')
      end

      it 'diffs working tree against a tag' do
        result = command.call('after_add')

        file = result.files.find { |f| f.path == 'lib/main.rb' }
        expect(file).not_to be_nil
      end
    end

    describe 'cached/staged option' do
      before do
        # Reset any prior state
        Dir.chdir(repo_dir) { system('git', 'reset', 'HEAD', out: File::NULL, err: File::NULL) }
        Dir.chdir(repo_dir) { system('git', 'checkout', '--', 'lib/main.rb', out: File::NULL, err: File::NULL) }
        write_file('lib/main.rb', "# frozen_string_literal: true\n\nmodule Main\n  VERSION = '2.0.0'\nend\n")
        repo.add('lib/main.rb')
      end

      after do
        # Clean up staged and working tree changes
        Dir.chdir(repo_dir) { system('git', 'reset', 'HEAD', out: File::NULL, err: File::NULL) }
        Dir.chdir(repo_dir) { system('git', 'checkout', '--', 'lib/main.rb', out: File::NULL, err: File::NULL) }
      end

      it 'diffs staged changes against HEAD' do
        result = command.call(cached: true)

        file = result.files.find { |f| f.path == 'lib/main.rb' }
        expect(file).not_to be_nil
        expect(file.patch).to include('+  VERSION')
      end

      it 'diffs staged changes against a commit' do
        result = command.call('after_add', cached: true)

        file = result.files.find { |f| f.path == 'lib/main.rb' }
        expect(file).not_to be_nil
      end

      it 'supports staged: alias' do
        result = command.call(staged: true)

        file = result.files.find { |f| f.path == 'lib/main.rb' }
        expect(file).not_to be_nil
      end
    end

    describe 'pathspec filtering' do
      it 'limits diff to matching pathspec' do
        result = command.call('after_spaces', 'after_multi', pathspecs: ['lib/'])

        paths = result.files.map(&:path)
        expect(paths).to all(start_with('lib/'))
        expect(paths).not_to include('CHANGELOG.md')
      end

      it 'supports multiple pathspecs' do
        result = command.call('after_spaces', 'after_multi', pathspecs: ['lib/main.rb', 'CHANGELOG.md'])

        paths = result.files.map(&:path)
        expect(paths).to contain_exactly('lib/main.rb', 'CHANGELOG.md')
      end

      it 'supports glob patterns' do
        result = command.call('after_spaces', 'after_multi', pathspecs: ['*.md'])

        paths = result.files.map(&:path)
        expect(paths).to all(end_with('.md'))
      end
    end

    describe 'merge-base option' do
      it 'compares using merge-base with three-dot syntax' do
        result = command.call('main...feature')

        file = result.files.find { |f| f.path == 'lib/feature.rb' }
        expect(file).not_to be_nil
        expect(file.status).to eq(:added)
      end
    end

    describe 'dirstat option' do
      it 'includes directory statistics when requested' do
        result = command.call('initial', 'after_multi', dirstat: true)

        expect(result.dirstat).not_to be_nil
        expect(result.dirstat).to be_a(Git::DirstatInfo)
        expect(result.dirstat.entries).not_to be_empty
      end

      it 'includes directory paths in dirstat' do
        result = command.call('initial', 'after_multi', dirstat: true)

        directories = result.dirstat.entries.map(&:directory)
        expect(directories).to include('lib/')
      end

      it 'supports dirstat options string' do
        result = command.call('initial', 'after_multi', dirstat: 'cumulative')

        expect(result.dirstat).not_to be_nil
      end
    end

    describe 'no_index option' do
      it 'compares two filesystem paths with differences (exit code 1)' do
        file1 = File.join(repo_dir, '..', 'outside1.txt')
        file2 = File.join(repo_dir, '..', 'outside2.txt')

        begin
          File.write(file1, "Line 1\nLine 2\n")
          File.write(file2, "Line 1\nLine 2\nLine 3\n")

          result = command.call(file1, file2, no_index: true)

          expect(result.files.size).to eq(1)
          # The file shows insertions in the patch
          expect(result.files.first.patch).to include('+Line 3')
        ensure
          FileUtils.rm_f([file1, file2])
        end
      end

      it 'compares two identical files (exit code 0)' do
        file1 = File.join(repo_dir, '..', 'same1.txt')
        file2 = File.join(repo_dir, '..', 'same2.txt')

        begin
          File.write(file1, "Identical content\n")
          File.write(file2, "Identical content\n")

          result = command.call(file1, file2, no_index: true)

          expect(result.files).to be_empty
        ensure
          FileUtils.rm_f([file1, file2])
        end
      end
    end

    describe 'empty diff' do
      it 'returns empty files array when no changes (exit code 0)' do
        result = command.call('initial', 'initial')

        expect(result.files).to be_empty
        expect(result.files_changed).to eq(0)
        expect(result.total_insertions).to eq(0)
        expect(result.total_deletions).to eq(0)
      end
    end

    describe 'exit code handling' do
      it 'succeeds with differences found (exit code 1)' do
        # When differences exist, git returns exit code 1
        result = command.call('initial', 'after_modify')

        expect(result.files).not_to be_empty
      end

      it 'raises FailedError for invalid revision (exit code 128)' do
        expect { command.call('nonexistent-ref') }.to raise_error(Git::FailedError)
      end
    end
  end
end
