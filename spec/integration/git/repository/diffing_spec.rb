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

RSpec.describe Git::Repository::Diffing, :integration do
  include_context 'in an empty repository'

  let(:execution_context) { Git::ExecutionContext::Repository.from_base(repo) }
  let(:described_instance) { Git::Repository.new(execution_context: execution_context) }

  describe '#diff_full' do
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
end
