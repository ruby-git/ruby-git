# frozen_string_literal: true

require 'spec_helper'

# Integration tests confirming that Git::Base exposes the Git::Repository::Branching
# facade methods via one-line delegators.  Each example calls the method on `repo`
# (a Git::Base instance) and verifies it returns the expected type/value.

RSpec.describe Git::Base, :integration do
  include_context 'in an empty repository'

  before do
    write_file('README.md', "# Hello\n")
    repo.add('README.md')
    repo.commit('Initial commit')
  end

  describe '#branches_all' do
    it 'returns an array of branch info objects' do
      result = repo.branches_all
      expect(result).to be_an(Array)
      expect(result).not_to be_empty
    end
  end

  describe '#branch_contains' do
    it 'returns a String' do
      sha = repo.log(1).execute.first.sha
      result = repo.branch_contains(sha)
      expect(result).to be_a(String)
    end
  end

  describe '#branch_new' do
    it 'creates a new branch without raising' do
      expect { repo.branch_new('feature-x') }.not_to raise_error
    end

    it 'makes the branch visible in branches_all' do
      repo.branch_new('feature-y')
      names = repo.branches_all.map { |b| b.refname.gsub(%r{\Arefs/heads/}, '') }
      expect(names).to include('feature-y')
    end
  end

  describe '#branch_delete' do
    before { repo.branch_new('to-delete') }

    it 'deletes the branch without raising' do
      expect { repo.branch_delete('to-delete') }.not_to raise_error
    end

    it 'removes the branch from branches_all' do
      repo.branch_delete('to-delete')
      names = repo.branches_all.map { |b| b.refname.gsub(%r{\Arefs/heads/}, '') }
      expect(names).not_to include('to-delete')
    end
  end
end
