# frozen_string_literal: true

require 'spec_helper'
require 'git/repository'
require 'git/repository/status_operations'
require 'git/execution_context/repository'

# Integration tests for Git::Repository::StatusOperations#ls_files.
#
# ls_files performs facade-owned post-processing: it parses the raw stdout of
# `git ls-files --stage` into a structured Ruby hash. This integration test
# exercises that full parsing pipeline against a real git repository.

RSpec.describe Git::Repository::StatusOperations, :integration do
  include_context 'in an empty repository'

  let(:execution_context) { Git::ExecutionContext::Repository.from_base(repo) }
  let(:described_instance) { Git::Repository.new(execution_context: execution_context) }

  before do
    write_file('README.md', "# Hello World\n")
    write_file('lib/git.rb', "# frozen_string_literal: true\n")
    repo.add(all: true)
    repo.commit('Initial commit')
  end

  describe '#ls_files' do
    context 'with no location argument (defaults to all files)' do
      it 'returns a hash containing all tracked files' do
        result = described_instance.ls_files
        expect(result.keys).to contain_exactly('README.md', 'lib/git.rb')
      end

      it 'each entry has the required hash structure with the correct key types' do
        result = described_instance.ls_files
        entry = result['README.md']
        expect(entry.keys).to contain_exactly(:path, :mode_index, :sha_index, :stage)
      end

      it 'each entry has the correct :path value' do
        result = described_instance.ls_files
        expect(result['README.md'][:path]).to eq('README.md')
      end

      it 'each entry has a six-digit octal :mode_index' do
        result = described_instance.ls_files
        expect(result['README.md'][:mode_index]).to match(/\A\d{6}\z/)
      end

      it 'each entry has a 40-hex-character :sha_index' do
        result = described_instance.ls_files
        expect(result['README.md'][:sha_index]).to match(/\A[0-9a-f]{40}\z/)
      end

      it 'normal tracked files have :stage of "0"' do
        result = described_instance.ls_files
        expect(result['README.md'][:stage]).to eq('0')
      end
    end

    context 'with an explicit subdirectory location' do
      it 'returns only files under that subdirectory' do
        result = described_instance.ls_files('lib')
        expect(result.keys).to eq(['lib/git.rb'])
      end

      it 'uses the full repository-relative path as the hash key' do
        result = described_instance.ls_files('lib')
        expect(result.keys).to all(start_with('lib/'))
      end
    end

    context 'with a location that has no tracked files' do
      it 'returns an empty hash' do
        result = described_instance.ls_files('nonexistent/')
        expect(result).to eq({})
      end
    end
  end
end
