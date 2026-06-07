# frozen_string_literal: true

require 'spec_helper'
require 'securerandom'

# Integration tests confirming that Git::Base exposes the Git::Repository::WorktreeOperations
# facade methods via one-line delegators.

RSpec.describe Git::Base, :integration do
  include_context 'in an empty repository'

  before do
    write_file('README.md', "# Hello\n")
    repo.add('README.md')
    repo.commit('Initial commit')
  end

  describe '#worktrees_all' do
    it 'returns an array with at least the main worktree' do
      result = repo.worktrees_all
      expect(result).to be_an(Array)
      expect(result.length).to be >= 1
    end
  end

  describe '#worktree_add and #worktree_remove' do
    let(:worktree_path) { File.join(repo_dir, '..', "wt-#{SecureRandom.hex(4)}") }

    after do
      FileUtils.rm_rf(worktree_path)
      repo.worktree_prune
    end

    it '#worktree_add creates a linked worktree' do
      expect { repo.worktree_add(worktree_path) }.not_to raise_error
      expect(File.directory?(worktree_path)).to be true
    end

    it '#worktree_remove removes the linked worktree' do
      repo.worktree_add(worktree_path)
      expect { repo.worktree_remove(worktree_path) }.not_to raise_error
    end
  end

  describe '#worktree_prune' do
    it 'completes without raising' do
      expect { repo.worktree_prune }.not_to raise_error
    end
  end
end
