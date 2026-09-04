# frozen_string_literal: true

require 'spec_helper'

# Integration tests for Git::Parsers::Worktree
#
# These tests verify that the parser correctly handles real
# `git worktree list --porcelain` output.
#
RSpec.describe Git::Parsers::Worktree, :integration do
  include_context 'in an empty repository'

  # Run `git worktree list --porcelain` in the given repository and return raw output
  def git_worktree_output(repository = repo)
    repository.execution_context.command_capturing('worktree', 'list', '--porcelain').stdout
  end

  before do
    write_file('README.md', "# Hello\n")
    repo.add('README.md')
    repo.commit('Initial commit')
  end

  describe '.parse_list' do
    context 'with only the main worktree' do
      it 'returns one Git::WorktreeInfo for the main worktree on its branch' do
        result = described_class.parse_list(git_worktree_output)

        expect(result.size).to eq(1)
        expect(result.first).to have_attributes(
          path: File.realpath(repo_dir), branch: 'refs/heads/main', bare: false, detached: false,
          locked: false, lock_reason: nil, prunable: false, prune_reason: nil
        )
        expect(result.first.head).to match(/\A[0-9a-f]{40}\z/)
      end
    end

    context 'with linked worktrees in every reported state' do
      let(:worktrees_dir) { Dir.mktmpdir('worktrees') }
      let(:locked_path) { File.join(worktrees_dir, 'locked') }
      let(:locked_with_reason_path) { File.join(worktrees_dir, 'locked-with-reason') }
      let(:detached_path) { File.join(worktrees_dir, 'detached') }
      let(:prunable_path) { File.join(worktrees_dir, 'prunable') }

      before do
        add = Git::Commands::Worktree::Add.new(execution_context)
        lock = Git::Commands::Worktree::Lock.new(execution_context)

        add.call(locked_path)
        lock.call(locked_path)

        add.call(locked_with_reason_path)
        lock.call(locked_with_reason_path, reason: 'on purpose')

        add.call(detached_path, detach: true)

        add.call(prunable_path)
        FileUtils.rm_rf(prunable_path)
      end

      after { FileUtils.rm_rf(worktrees_dir) }

      # Find the parsed entry for a worktree path (git reports resolved absolute paths)
      def entry_for(result, path)
        result.find { |info| info.path == File.join(File.realpath(worktrees_dir), File.basename(path)) }
      end

      it 'lists the main worktree first' do
        result = described_class.parse_list(git_worktree_output)

        expect(result.first.path).to eq(File.realpath(repo_dir))
      end

      it 'returns one entry per worktree' do
        result = described_class.parse_list(git_worktree_output)

        expect(result.size).to eq(5)
      end

      it 'parses a worktree locked without a reason' do
        result = described_class.parse_list(git_worktree_output)

        expect(entry_for(result, locked_path)).to have_attributes(
          branch: 'refs/heads/locked', locked: true, lock_reason: nil, detached: false, prunable: false
        )
      end

      it 'parses a worktree locked with a reason' do
        result = described_class.parse_list(git_worktree_output)

        expect(entry_for(result, locked_with_reason_path)).to have_attributes(
          branch: 'refs/heads/locked-with-reason', locked: true, lock_reason: 'on purpose'
        )
      end

      it 'parses a detached worktree with a nil branch' do
        result = described_class.parse_list(git_worktree_output)

        entry = entry_for(result, detached_path)
        expect(entry).to have_attributes(branch: nil, detached: true, locked: false)
        expect(entry.head).to match(/\A[0-9a-f]{40}\z/)
      end

      it 'parses a prunable worktree with its prune reason' do
        result = described_class.parse_list(git_worktree_output)

        entry = entry_for(result, prunable_path)
        expect(entry).to have_attributes(prunable: true, locked: false)
        expect(entry.prune_reason).to be_a(String)
        expect(entry.prune_reason).not_to be_empty
      end
    end

    context 'with a bare repository' do
      let(:bare_dir) { Dir.mktmpdir('bare_repo') }
      let(:bare_repo) { Git.init(bare_dir, bare: true) }

      after { FileUtils.rm_rf(bare_dir) }

      it 'returns a bare entry with no head or branch' do
        result = described_class.parse_list(git_worktree_output(bare_repo))

        expect(result).to eq(
          [
            Git::WorktreeInfo.new(
              path: File.realpath(bare_dir), head: nil, branch: nil, bare: true, detached: false,
              locked: false, lock_reason: nil, prunable: false, prune_reason: nil
            )
          ]
        )
      end
    end
  end
end
