# frozen_string_literal: true

require 'spec_helper'

# Integration tests confirming that Git::Base exposes the remaining Bucket 6
# facade methods via one-line delegators:
#   - Git::Repository::RemoteOperations#config_remote
#   - Git::Repository::Diffing#diff_index
#   - Git::Repository::StatusOperations#untracked_files

RSpec.describe Git::Base, :integration do
  include_context 'in an empty repository'

  before do
    write_file('README.md', "# Hello\n")
    repo.add('README.md')
    repo.commit('Initial commit')
  end

  describe '#config_remote' do
    before do
      repo.remote_add('origin', 'https://github.com/example/repo.git')
    end

    it 'returns a Hash with remote configuration' do
      result = repo.config_remote('origin')
      expect(result).to be_a(Hash)
      expect(result['url']).to eq('https://github.com/example/repo.git')
    end
  end

  describe '#diff_index' do
    it 'returns a Hash' do
      result = repo.diff_index('HEAD')
      expect(result).to be_a(Hash)
    end

    context 'when a tracked file is modified' do
      before { write_file('README.md', "# Modified\n") }

      it 'includes an entry for the modified file' do
        expect(repo.diff_index('HEAD')).to have_key('README.md')
      end
    end
  end

  describe '#untracked_files' do
    it 'returns an Array' do
      expect(repo.untracked_files).to be_an(Array)
    end

    context 'when an untracked file exists' do
      before { write_file('untracked.txt', 'content') }

      it 'includes the untracked file' do
        expect(repo.untracked_files).to include('untracked.txt')
      end
    end
  end
end
