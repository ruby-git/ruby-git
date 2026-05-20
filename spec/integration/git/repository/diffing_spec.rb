# frozen_string_literal: true

require 'spec_helper'
require 'git/repository'
require 'git/repository/diffing'
require 'git/execution_context/repository'

# Integration tests for Git::Repository::Diffing facade methods that perform
# facade-owned post-processing of real git output (extract_patch_text strips
# numstat/shortstat lines before returning the patch text). Methods that are
# pure single-command delegators without post-processing (diff_path_status /
# diff_name_status) are covered by the command's own integration tests:
#   tests/units/test_diff_path_status.rb
#
# #diff_stats is a lazy factory delegator (no facade-owned post-processing)
# and is covered by:
#   tests/units/test_diff_stats.rb

RSpec.describe Git::Repository::Diffing, :integration do
  include_context 'in an empty repository'

  let(:execution_context) { Git::ExecutionContext::Repository.from_base(repo) }
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
end
