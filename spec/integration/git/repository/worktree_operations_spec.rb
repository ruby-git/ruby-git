# frozen_string_literal: true

require 'spec_helper'
require 'securerandom'
require 'git/repository'
require 'git/repository/worktree_operations'

# worktree_add, worktree_remove, and worktree_prune are one-line delegators with no
# facade-owned post-processing. Baseline coverage for their happy paths comes from
# the command integration tests (spec/integration/git/commands/worktree/). The
# integration tests below are added only for real-git behaviors that need an
# unborn (no-commit) repository or multi-worktree state to reproduce: version-
# dependent unborn-repo behavior, the main-worktree removal failure mode, and
# prune's effect on a manually deleted linked worktree.
#
# worktree and worktrees are factory methods that construct domain objects
# (Git::Worktree and Git::Worktrees) without running git commands directly; they
# have no integration tests and are fully covered by the unit tests.
#
# worktrees_all parses porcelain output inline inside the facade. This integration
# test verifies that the parsing logic works correctly against actual git output.

RSpec.describe Git::Repository::WorktreeOperations, :integration do
  include_context 'in an empty repository'

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

    context 'when the repository has no commits' do
      let(:unborn_repo_dir) { Dir.mktmpdir('unborn_repo') }
      let(:unborn_repo) { init_test_repo(unborn_repo_dir) }
      let(:unborn_instance) { Git::Repository.new(execution_context: unborn_repo.execution_context) }

      after { FileUtils.rm_rf(unborn_repo_dir) }

      it 'lists only the main worktree' do
        result = unborn_instance.worktrees_all
        expect(result.length).to eq(1)
        expect(result.first.first).to eq(File.realpath(unborn_repo_dir))
      end
    end
  end

  describe '#worktree_add' do
    context 'when the repository has no commits' do
      let(:unborn_repo_dir) { Dir.mktmpdir('unborn_repo') }
      let(:unborn_repo) { init_test_repo(unborn_repo_dir) }
      let(:unborn_instance) { Git::Repository.new(execution_context: unborn_repo.execution_context) }
      let(:worktree_path) { File.join(unborn_repo_dir, '..', "worktree-#{SecureRandom.hex(4)}") }

      after do
        FileUtils.rm_rf(unborn_repo_dir)
        FileUtils.rm_rf(worktree_path)
      end

      context 'on git versions before 2.42.0', if: Git.git_version < Git::Version.new(2, 42, 0) do
        it 'raises Git::FailedError' do
          expect { unborn_instance.worktree_add(worktree_path) }.to raise_error(Git::FailedError, /worktree/)
        end
      end

      context 'on git versions 2.42.0 and later', if: Git.git_version >= Git::Version.new(2, 42, 0) do
        it 'succeeds and creates a second worktree entry' do
          unborn_instance.worktree_add(worktree_path)

          expect(unborn_instance.worktrees_all.length).to eq(2)
        end
      end
    end
  end

  describe '#worktree_remove' do
    context 'when removing the main worktree' do
      let(:linked_worktree_path) { File.join(repo_dir, '..', "worktree-#{SecureRandom.hex(4)}") }

      before do
        described_instance.worktree_add(linked_worktree_path)
      end

      after do
        Git::Commands::Worktree::Remove.new(execution_context).call(linked_worktree_path, force: true)
        Git::Commands::Worktree::Prune.new(execution_context).call
      end

      it 'raises Git::FailedError and leaves all worktrees intact' do
        expect { described_instance.worktree_remove(File.realpath(repo_dir)) }
          .to raise_error(Git::FailedError, /main working tree/)

        expect(described_instance.worktrees_all.length).to eq(2)
      end
    end
  end

  describe '#worktree_prune' do
    context 'when a linked worktree has been manually deleted' do
      let(:worktree_path) { File.join(repo_dir, '..', "worktree-#{SecureRandom.hex(4)}") }

      before do
        described_instance.worktree_add(worktree_path)
        FileUtils.rm_rf(worktree_path)
      end

      it 'removes the deleted worktree from the worktree list' do
        described_instance.worktree_prune

        expect(described_instance.worktrees_all.length).to eq(1)
      end
    end
  end
end
