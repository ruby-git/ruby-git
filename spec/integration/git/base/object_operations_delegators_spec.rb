# frozen_string_literal: true

require 'spec_helper'

# Integration tests confirming that Git::Base exposes the Git::Repository::ObjectOperations
# facade methods via one-line delegators. Each example calls the method on `repo`
# (a Git::Base instance) and verifies the return type or expected value.

RSpec.describe Git::Base, :integration do
  include_context 'in an empty repository'

  before do
    write_file('README.md', "# Hello World\n")
    repo.add('README.md')
    repo.commit('Initial commit')
  end

  describe '#cat_file_contents' do
    it 'returns the blob content as a String' do
      result = repo.cat_file_contents('HEAD:README.md')
      expect(result).to be_a(String)
      expect(result).to include('# Hello World')
    end
  end

  describe '#cat_file (alias)' do
    it 'is an alias for cat_file_contents' do
      expect(repo.method(:cat_file)).to eq(repo.method(:cat_file_contents))
    end
  end

  describe '#cat_file_size' do
    it 'returns an Integer' do
      result = repo.cat_file_size('HEAD:README.md')
      expect(result).to be_an(Integer)
      expect(result).to be > 0
    end
  end

  describe '#cat_file_type' do
    it 'returns "blob" for a blob reference' do
      expect(repo.cat_file_type('HEAD:README.md')).to eq('blob')
    end

    it 'returns "commit" for a commit reference' do
      expect(repo.cat_file_type('HEAD')).to eq('commit')
    end
  end

  describe '#cat_file_commit' do
    it 'returns a hash with commit metadata' do
      result = repo.cat_file_commit('HEAD')
      expect(result).to be_a(Hash)
      expect(result).to have_key('message')
    end
  end

  describe '#cat_file_tag' do
    before { repo.add_tag('v1.0.0', annotate: true, message: 'release') }

    it 'returns a hash with tag metadata' do
      result = repo.cat_file_tag('v1.0.0')
      expect(result).to be_a(Hash)
      expect(result).to have_key('message')
    end
  end

  describe '#tag_sha' do
    before { repo.add_tag('v1.0.0') }

    it 'returns a non-empty SHA string' do
      expect(repo.tag_sha('v1.0.0').chomp).to match(/\A[0-9a-f]{40}\z/)
    end
  end

  describe '#full_tree' do
    it 'returns an array of file path strings' do
      result = repo.full_tree('HEAD')
      expect(result).to be_an(Array)
      expect(result.any? { |e| e.include?('README.md') }).to be true
    end
  end

  describe '#name_rev' do
    it 'returns a non-empty String' do
      sha = repo.rev_parse('HEAD')
      result = repo.name_rev(sha)
      expect(result).to be_a(String)
      expect(result).not_to be_empty
    end
  end
end
