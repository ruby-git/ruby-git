# frozen_string_literal: true

require 'securerandom'
require 'spec_helper'
require 'git/repository'
require 'git/repository/worktree_operations'
require 'git/execution_context/repository'

# worktree_add, worktree_remove, and worktree_prune are one-line delegators with no
# facade-owned post-processing. Their end-to-end coverage comes from the command
# integration tests (spec/integration/git/commands/worktree/).
#
# worktrees_all parses porcelain output inline inside the facade. This integration
# test verifies that the parsing logic works correctly against actual git output.

RSpec.describe Git::Repository::WorktreeOperations, :integration do
  include_context 'in an empty repository'

  let(:execution_context) { Git::ExecutionContext::Repository.from_base(repo) }
  let(:described_instance) { Git::Repository.new(execution_context: execution_context) }

  before do
    write_file('README.md', "# Hello\n")
    repo.add('README.md')
    repo.commit('Initial commit')
  end

  describe '#worktrees_all' do
    context 'when only the main worktree exists' do
      it 'returns one entry for the main worktree' do
        result = described_instance.worktrees_all
        expect(result.length).to eq(1)
      end

      it 'returns the main worktree directory as the first element' do
        result = described_instance.worktrees_all
        expect(result.first.first).to eq(File.realpath(repo_dir))
      end

      it 'returns a full 40-character SHA as the second element' do
        result = described_instance.worktrees_all
        expect(result.first.last).to match(/\A[0-9a-f]{40}\z/)
      end
    end

    context 'when a linked worktree has been added' do
      let(:worktree_path) { File.join(repo_dir, '..', "worktree-#{SecureRandom.hex(4)}") }

      before do
        Git::Commands::Worktree::Add.new(execution_context).call(worktree_path)
      end

      after do
        Git::Commands::Worktree::Remove.new(execution_context).call(worktree_path, force: true)
        Git::Commands::Worktree::Prune.new(execution_context).call
      end

      it 'returns two entries' do
        result = described_instance.worktrees_all
        expect(result.length).to eq(2)
      end

      it 'includes the main worktree directory' do
        result = described_instance.worktrees_all
        directories = result.map(&:first)
        expect(directories).to include(File.realpath(repo_dir))
      end

      it 'includes the linked worktree directory' do
        result = described_instance.worktrees_all
        directories = result.map(&:first)
        expect(directories).to include(File.realpath(worktree_path))
      end

      it 'returns a valid 40-character SHA for each entry' do
        shas = described_instance.worktrees_all.map(&:last)
        expect(shas).to all(match(/\A[0-9a-f]{40}\z/))
      end
    end
  end
end
