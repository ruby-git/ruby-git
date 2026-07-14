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

  # #status performs multi-command orchestration: it runs git ls-files --stage,
  # git ls-files --others --exclude-standard, git diff-files, and (when commits
  # exist) git diff-index HEAD. The integration test verifies the end-to-end
  # return value against a real git repository.
  describe '#status' do
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

    context 'when a file matches a .gitignore pattern' do
      before do
        write_file('ignored.log', 'log content')
        write_file('.gitignore', "ignored.log\n")
      end
    end
  end
end
