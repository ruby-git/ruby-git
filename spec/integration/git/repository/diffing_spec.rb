# frozen_string_literal: true

require 'spec_helper'
require 'git/repository'
require 'git/repository/diffing'

# Integration tests for Git::Repository::Diffing facade methods that perform
# facade-owned post-processing of real git output:
#   - #diff_full: extract_patch_text strips numstat/shortstat lines before
#     returning the patch text
#   - #diff_numstat: parse_numstat_output parses combined numstat/shortstat
#     output into a structured hash
#
# Methods with facade-owned parsing covered by the legacy test suite
# (Git::Base delegates to the facade, so coverage is end-to-end):
#   tests/units/test_diff_path_status.rb covers #diff_path_status /
#   #diff_name_status, which parse raw diff output via
#   Private.extract_name_status_from_raw.
#
# #diff_stats is a lazy factory delegator (no facade-owned post-processing)
# and is covered by:
#   tests/units/test_diff_stats.rb

RSpec.describe Git::Repository::Diffing, :integration do
  include_context 'in an empty repository'

  let(:described_instance) { Git::Repository.new(execution_context: execution_context) }

  before do
    write_file('README.md', "# Project\n\nInitial content.\n")
    repo.add('README.md')
    repo.commit('Initial commit')

    write_file('lib/main.rb', "# frozen_string_literal: true\n\nmodule Main\nend\n")
    repo.add('lib/main.rb')
    repo.commit('Add main library')

    write_file('README.md', "# Project\n\nUpdated content.\n")
    write_file('lib/main.rb', "# frozen_string_literal: true\n\nmodule Main\n  VERSION = '1.0.0'\nend\n")
    repo.add(all: true)
    repo.commit('Update readme and main')
  end

  describe '#diff_full' do
    context 'with explicit obj1 and obj2 that differ' do
      it 'returns the unified diff patch text for those commits' do
        result = described_instance.diff_full('HEAD~1', 'HEAD')
        expect(result).to start_with('diff --git ')
        expect(result).to include('+++ b/')
        expect(result).to include('--- a/')
      end
    end

    context 'with path_limiter pointing to a specific file' do
      it 'only includes hunks for that file' do
        result = described_instance.diff_full('HEAD~1', 'HEAD', path_limiter: 'README.md')
        expect(result).to include('README.md')
        expect(result).not_to include('lib/main.rb')
      end
    end

    context 'when there are no changes between the compared refs' do
      it 'returns an empty string' do
        result = described_instance.diff_full('HEAD', 'HEAD')
        expect(result).to eq('')
      end
    end
  end

  describe '#diff_numstat' do
    # HEAD~1 = "Add main library" (adds lib/main.rb)
    # HEAD   = "Update readme and main" (modifies both README.md and lib/main.rb)
    #
    # Expected diff HEAD~1..HEAD:
    #   README.md    : -"Initial content." +"Updated content." → 1 insertion, 1 deletion
    #   lib/main.rb  : +"  VERSION = '1.0.0'" → 1 insertion, 0 deletions
    #   total        : insertions=2, deletions=1, lines=3, files=2

    context 'when comparing two refs that differ' do
      it 'returns correct per-file stats and aggregated totals' do
        result = described_instance.diff_numstat('HEAD~1', 'HEAD')
        expect(result[:total]).to eq(insertions: 2, deletions: 1, lines: 3, files: 2)
        expect(result[:files]['README.md']).to eq(insertions: 1, deletions: 1)
        expect(result[:files]['lib/main.rb']).to eq(insertions: 1, deletions: 0)
      end
    end

    context 'when there are no changes between the compared refs' do
      it 'returns zero totals and an empty files hash' do
        result = described_instance.diff_numstat('HEAD', 'HEAD')
        expect(result).to eq(
          total: { insertions: 0, deletions: 0, lines: 0, files: 0 },
          files: {}
        )
      end
    end

    context 'when path_limiter filters to a specific file' do
      it 'returns stats only for that file' do
        result = described_instance.diff_numstat('HEAD~1', 'HEAD', path_limiter: 'README.md')
        expect(result[:total]).to eq(insertions: 1, deletions: 1, lines: 2, files: 1)
        expect(result[:files].keys).to eq(['README.md'])
      end
    end
  end

  describe '#diff_files' do
    context 'when there are no unstaged changes' do
      it 'returns an empty hash' do
        result = described_instance.diff_files
        expect(result).to eq({})
      end
    end

    context 'when a tracked file has been modified but not staged' do
      before do
        write_file('README.md', "# Project\n\nModified but not staged.\n")
      end

      it 'returns an entry for the modified file with correct path, type, modes, and SHA markers' do
        result = described_instance.diff_files
        expect(result).to have_key('README.md')
        entry = result['README.md']
        expect(entry).to include(
          path: 'README.md',
          type: 'M',
          mode_index: '100644',
          mode_repo: '100644'
        )
        expect(entry[:sha_repo]).to match(/\A[0-9a-f]+\z/)
        expect(entry[:sha_index]).to match(/\A0+\z/)
      end
    end

    context 'when a tracked file is renamed in the working tree (unstaged)' do
      # git diff-files only iterates over index entries — it has no visibility
      # into untracked files. A working-tree rename therefore cannot produce a
      # two-path "Rxx old_path\tnew_path" line; it shows the original path as
      # deleted (D) and ignores the new untracked file entirely.
      before do
        FileUtils.mv(File.join(repo_dir, 'README.md'), File.join(repo_dir, 'RENAMED.md'))
      end

      it 'reports the original path as deleted, not as a rename entry' do
        result = described_instance.diff_files
        expect(result).to have_key('README.md')
        expect(result['README.md']).to include(type: 'D')
      end

      it 'does not include the new path (it is untracked)' do
        result = described_instance.diff_files
        expect(result).not_to have_key('RENAMED.md')
      end

      it 'returns only one entry (no spurious two-path artefacts)' do
        result = described_instance.diff_files
        expect(result.size).to eq(1)
      end
    end
  end

  describe '#diff_index' do
    context 'when the index matches HEAD (nothing staged)' do
      it 'returns an empty hash' do
        result = described_instance.diff_index('HEAD')
        expect(result).to eq({})
      end
    end

    context 'when a tracked file has been modified and staged' do
      before do
        write_file('README.md', "# Project\n\nStaged change.\n")
        repo.add('README.md')
      end

      it 'returns an entry with all expected keys and correct values' do
        result = described_instance.diff_index('HEAD')
        entry = result['README.md']
        expect(entry).to include(
          path: 'README.md',
          type: 'M',
          mode_index: '100644',
          mode_repo: '100644'
        )
        expect(entry[:sha_repo]).to match(/\A[0-9a-f]+\z/)
        expect(entry[:sha_index]).to match(/\A[0-9a-f]+\z/)
      end
    end

    context 'when a tracked file has been modified but NOT staged' do
      before do
        write_file('README.md', "# Project\n\nUnstaged change.\n")
        # intentionally no repo.add — file is dirty but not staged
      end

      it 'still returns an entry for the modified file' do
        result = described_instance.diff_index('HEAD')
        expect(result).to have_key('README.md')
        expect(result['README.md']).to include(path: 'README.md', type: 'M')
      end
    end

    context 'when a file is staged then the working tree is reverted to match HEAD' do
      before do
        # Stage a change so the index differs from the tree
        write_file('README.md', "# Project\n\nStaged change.\n")
        repo.add('README.md')
        # Revert the working-tree file to the HEAD content without unstaging
        write_file('README.md', "# Project\n\nUpdated content.\n")
      end

      it 'still reports the file as changed because the index differs from the tree' do
        result = described_instance.diff_index('HEAD')
        expect(result).to have_key('README.md')
        expect(result['README.md']).to include(path: 'README.md', type: 'M')
      end
    end
  end
end
