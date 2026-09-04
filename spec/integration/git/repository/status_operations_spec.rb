# frozen_string_literal: true

require 'spec_helper'
require 'git/repository'
require 'git/repository/status_operations'

# Integration tests for Git::Repository::StatusOperations.
#
# #ls_files performs facade-owned post-processing: it parses the raw stdout of
# `git ls-files --stage` into a structured Ruby hash. This integration test
# exercises that full parsing pipeline against a real git repository.
#
# #no_commits? is a two-outcome facade method that runs real git rev-parse
# against the HEAD ref, so integration tests verify both outcomes.

RSpec.describe Git::Repository::StatusOperations, :integration do
  include_context 'in an empty repository'

  let(:described_instance) { Git::Repository.new(execution_context: execution_context) }

  describe '#ls_files' do
    before do
      write_file('README.md', "# Hello World\n")
      write_file('lib/git.rb', "# frozen_string_literal: true\n")
      repo.add(all: true)
      repo.commit('Initial commit')
    end

    context 'with no location argument (defaults to all files)' do
      it 'returns a hash of all tracked files with correct per-file metadata' do
        result = described_instance.ls_files
        expect(result.keys).to contain_exactly('README.md', 'lib/git.rb')
        entry = result['README.md']
        expect(entry[:path]).to eq('README.md')
        expect(entry[:mode_index]).to match(/\A\d{6}\z/)
        expect(entry[:sha_index]).to match(/\A[0-9a-f]{40}\z/)
        expect(entry[:stage]).to eq('0')
      end
    end

    context 'with an explicit subdirectory location' do
      it 'returns only files under that subdirectory, keyed by full repository-relative paths' do
        result = described_instance.ls_files('lib')
        expect(result.keys).to contain_exactly('lib/git.rb')
      end
    end

    context 'with a location that has no tracked files' do
      it 'returns an empty hash' do
        result = described_instance.ls_files('nonexistent/')
        expect(result).to eq({})
      end
    end
  end

  describe '#no_commits?' do
    context 'when the repository has no commits yet' do
      it 'returns true' do
        expect(described_instance.no_commits?).to be(true)
      end
    end

    context 'when the repository has at least one commit' do
      before do
        write_file('README.md', "# Hello\n")
        repo.add(all: true)
        repo.commit('Initial commit')
      end

      it 'returns false' do
        expect(described_instance.no_commits?).to be(false)
      end
    end
  end

  # #status_info runs git status --porcelain=v2 -z and reads core.ignoreCase,
  # then assembles a Git::StatusInfo. The integration test verifies the
  # end-to-end value object against a real git repository.
  describe '#status_info' do
    context 'when the repository has no commits yet' do
      before do
        write_file('staged.rb', 'staged')
        write_file('untracked.rb', 'untracked')
        repo.add('staged.rb')
      end

      it 'returns a Git::StatusInfo reporting the staged file as added and the other as untracked' do
        result = described_instance.status_info
        expect(result).to be_a(Git::StatusInfo)
        expect(result.files).to all(be_a(Git::StatusFileInfo))
        expect(result.added.keys).to eq(['staged.rb'])
        expect(result.untracked.keys).to eq(['untracked.rb'])
      end
    end

    context 'when the repository has at least one commit' do
      before do
        write_file('README.md', "# Hello\n")
        write_file('lib/keep.rb', "keep\n")
        repo.add(all: true)
        repo.commit('Initial commit')
      end

      context 'when the working tree is clean' do
        it 'returns a Git::StatusInfo with no files' do
          expect(described_instance.status_info.files).to eq([])
        end
      end

      context 'when an untracked file exists' do
        before { write_file('untracked.rb', 'content') }

        it 'reports the file as untracked with no index or HEAD metadata' do
          result = described_instance.status_info
          expect(result.untracked.keys).to eq(['untracked.rb'])
          expect(result.untracked?('untracked.rb')).to be(true)
          expect(result['untracked.rb']).to have_attributes(
            index_status: '?', worktree_status: '?', submodule: nil, sha_head: nil, sha_index: nil
          )
        end
      end

      context 'when a new file is staged' do
        before do
          write_file('new.rb', 'content')
          repo.add('new.rb')
        end

        it 'reports the file as added with its index SHA' do
          result = described_instance.status_info
          expect(result.added.keys).to eq(['new.rb'])
          expect(result.added?('new.rb')).to be(true)
          expect(result['new.rb']).to have_attributes(index_status: 'A', worktree_status: '.')
          expect(result['new.rb'].sha_index).to match(/\A[0-9a-f]{40}\z/)
        end
      end

      context 'when a tracked file is modified in the working tree but not staged' do
        before { write_file('README.md', "# Changed\n") }

        it 'reports the file as changed on the worktree side' do
          result = described_instance.status_info
          expect(result.changed.keys).to eq(['README.md'])
          expect(result.changed?('README.md')).to be(true)
          expect(result['README.md']).to have_attributes(index_status: '.', worktree_status: 'M')
        end
      end

      context 'when a tracked file is modified and staged' do
        before do
          write_file('README.md', "# Changed\n")
          repo.add('README.md')
        end

        it 'reports the file as changed on the index side' do
          result = described_instance.status_info
          expect(result.changed.keys).to eq(['README.md'])
          expect(result['README.md']).to have_attributes(index_status: 'M', worktree_status: '.')
        end
      end

      context 'when a tracked file is deleted from the working tree' do
        before { remove('README.md') }

        it 'reports the file as deleted on the worktree side' do
          result = described_instance.status_info
          expect(result.deleted.keys).to eq(['README.md'])
          expect(result.deleted?('README.md')).to be(true)
          expect(result['README.md']).to have_attributes(index_status: '.', worktree_status: 'D')
        end
      end

      context 'when a tracked file is removed from the index' do
        before { repo.rm('README.md') }

        it 'reports the file as deleted on the index side' do
          result = described_instance.status_info
          expect(result.deleted.keys).to eq(['README.md'])
          expect(result['README.md']).to have_attributes(index_status: 'D', worktree_status: '.')
        end
      end

      context 'when a tracked file is renamed in the index' do
        before do
          repo.mv('README.md', 'RENAMED.md')
        end

        it 'reports the file as renamed with its original path and score' do
          result = described_instance.status_info
          expect(result.files.map(&:path)).to eq(['RENAMED.md'])
          expect(result['RENAMED.md']).to have_attributes(
            index_status: 'R', worktree_status: '.', original_path: 'README.md', rename_score: 100
          )
          expect(result['RENAMED.md']).to be_renamed
        end
      end

      context 'when a path contains a space' do
        before do
          write_file('dir name/file with space.txt', 'content')
          write_file('README.md', "# Changed\n")
        end

        it 'keeps the whole path including its spaces' do
          result = described_instance.status_info
          expect(result.untracked.keys).to eq(['dir name/file with space.txt'])
          expect(result.changed.keys).to eq(['README.md'])
        end
      end

      context 'when opened from a subdirectory' do
        before { write_file('lib/untracked.rb', 'untracked') }

        it "returns paths relative to the repository's root" do
          subdir_repo = Git.open(File.join(repo_dir, 'lib'))
          expect(subdir_repo.status_info.untracked.keys).to eq(['lib/untracked.rb'])
        end
      end

      context 'when core.ignoreCase is true' do
        before do
          repo.config_set('core.ignoreCase', 'true')
          write_file('README.md', "# Changed\n")
        end

        it 'matches predicate paths case-insensitively' do
          result = described_instance.status_info
          expect(result.ignore_case).to be(true)
          expect(result.changed?('readme.md')).to be(true)
        end
      end

      context 'when core.ignoreCase is a non-canonical true spelling' do
        before do
          repo.config_set('core.ignoreCase', 'yes')
          write_file('README.md', "# Changed\n")
        end

        it 'reads the setting as a boolean and matches predicate paths case-insensitively' do
          result = described_instance.status_info
          expect(result.ignore_case).to be(true)
          expect(result.changed?('readme.md')).to be(true)
        end
      end

      context 'when core.ignoreCase is false' do
        before do
          repo.config_set('core.ignoreCase', 'false')
          write_file('README.md', "# Changed\n")
        end

        it 'matches predicate paths exactly' do
          result = described_instance.status_info
          expect(result.ignore_case).to be(false)
          expect(result.changed?('readme.md')).to be(false)
          expect(result.changed?('README.md')).to be(true)
        end
      end
    end
  end

  # #status performs multi-command orchestration: it runs git ls-files --stage,
  # git ls-files --others --exclude-standard, git diff-files, and (when commits
  # exist) git diff-index HEAD. The integration test verifies the end-to-end
  # return value against a real git repository.
  #
  # #status is deprecated in favor of #status_info; the warning is stubbed here
  # because the suite raises on deprecation warnings.
  describe '#status' do
    before { allow(Git::Deprecation).to receive(:warn) }

    it 'emits a deprecation warning naming Git::Repository#status_info as the replacement' do
      expect(Git::Deprecation).to receive(:warn).with(/status is deprecated.*Use Git::Repository#status_info/)
      described_instance.status
    end

    context 'when the repository has no commits yet' do
      it 'returns a Git::Status instance' do
        expect(described_instance.status).to be_a(Git::Status)
      end
    end

    context 'when the repository has at least one commit' do
      before do
        write_file('README.md', "# Hello\n")
        repo.add(all: true)
        repo.commit('Initial commit')
      end

      context 'when an untracked file exists' do
        before { write_file('untracked.rb', 'content') }

        it 'includes the untracked file in status.untracked' do
          expect(described_instance.status.untracked.keys).to include('untracked.rb')
        end
      end

      context 'when a tracked file is modified in the index' do
        before do
          write_file('README.md', "# Changed\n")
          repo.add('README.md')
        end

        it 'includes the file in status.changed' do
          expect(described_instance.status.changed.keys).to include('README.md')
        end
      end

      context 'when a tracked file is deleted and recreated with the same content' do
        before do
          content = read_file('README.md')
          remove('README.md')
          write_file('README.md', content)
        end

        it 'reports the file as unchanged via status.changed?' do
          expect(described_instance.status.changed?('README.md')).to be(false)
        end
      end

      context 'when opened from a subdirectory' do
        before do
          write_file('subdir/tracked.txt', 'tracked')
          write_file('subdir/untracked.txt', 'untracked')
          repo.add('subdir/tracked.txt')
          repo.commit('Add subdir file')
        end

        it "returns untracked file paths relative to the repository's root" do
          subdir_repo = Git.open(File.join(repo_dir, 'subdir'))
          expect(subdir_repo.status.untracked.keys).to include('subdir/untracked.txt')
        end
      end
    end
  end

  describe '#untracked_files' do
    context 'when there are no untracked files' do
      it 'returns an empty array' do
        expect(described_instance.untracked_files).to eq([])
      end
    end

    context 'when there is one untracked file' do
      before do
        write_file('new_feature.rb', 'content')
      end

      it 'returns an array containing that file' do
        expect(described_instance.untracked_files).to eq(['new_feature.rb'])
      end
    end

    context 'when there are multiple untracked files including in subdirectories' do
      before do
        write_file('a.rb', 'content')
        write_file('lib/b.rb', 'content')
      end

      it 'returns all untracked file paths relative to the repository root' do
        expect(described_instance.untracked_files).to contain_exactly('a.rb', 'lib/b.rb')
      end
    end
  end
end
