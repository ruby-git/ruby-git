# frozen_string_literal: true

require 'spec_helper'
require 'git/repository'
require 'git/repository/status_operations'
require 'git/execution_context/repository'

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

  let(:execution_context) { Git::ExecutionContext::Repository.from_base(repo) }
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
end
