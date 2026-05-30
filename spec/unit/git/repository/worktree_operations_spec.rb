# frozen_string_literal: true

require 'spec_helper'
require 'git/repository'
require 'git/repository/worktree_operations'

# Integration-level coverage for facade methods in Git::Repository::WorktreeOperations:
#   worktree_add, worktree_remove, and worktree_prune are one-line delegators to
#   single Git::Commands::Worktree::* classes with no post-processing. Their
#   end-to-end coverage comes from the command integration tests:
#     spec/integration/git/commands/worktree/add_spec.rb    (worktree_add)
#     spec/integration/git/commands/worktree/remove_spec.rb (worktree_remove)
#     spec/integration/git/commands/worktree/prune_spec.rb  (worktree_prune)
#   worktree and worktrees are factory methods that construct domain objects
#   (Git::Worktree and Git::Worktrees) without running git commands directly;
#   their behavior is fully covered by the unit tests below.
#   worktrees_all does facade-owned inline parsing of porcelain output; its
#   integration test is in spec/integration/git/repository/worktree_operations_spec.rb.

RSpec.describe Git::Repository::WorktreeOperations do
  let(:execution_context) { instance_double(Git::ExecutionContext::Repository) }
  let(:described_instance) { Git::Repository.new(execution_context: execution_context) }

  describe '#worktrees_all' do
    subject(:result) { described_instance.worktrees_all }

    let(:list_command) { instance_double(Git::Commands::Worktree::List) }
    let(:list_result) { command_result('') }

    before do
      allow(Git::Commands::Worktree::List).to receive(:new).with(execution_context).and_return(list_command)
      allow(list_command).to receive(:call).with(porcelain: true).and_return(list_result)
    end

    it 'constructs Git::Commands::Worktree::List with the execution context' do
      expect(Git::Commands::Worktree::List).to receive(:new).with(execution_context).and_return(list_command)
      described_instance.worktrees_all
    end

    it 'calls #call with porcelain: true' do
      expect(list_command).to receive(:call).with(porcelain: true).and_return(list_result)
      described_instance.worktrees_all
    end

    context 'when the output is empty (no worktrees reported)' do
      it 'returns an empty array' do
        expect(result).to eq([])
      end
    end

    context 'when there is one worktree' do
      let(:list_result) do
        command_result(
          "worktree /path/to/main\n" \
          "HEAD 4bef5ab0c8e7c19c6be2c0f55ccd45eec1f3d32a\n" \
          "branch refs/heads/main\n"
        )
      end

      it 'returns a single [directory, sha] pair' do
        expect(result).to eq(
          [['/path/to/main', '4bef5ab0c8e7c19c6be2c0f55ccd45eec1f3d32a']]
        )
      end
    end

    context 'when there are multiple worktrees' do
      let(:list_result) do
        command_result(
          "worktree /path/to/main\n" \
          "HEAD 4bef5ab0c8e7c19c6be2c0f55ccd45eec1f3d32a\n" \
          "branch refs/heads/main\n" \
          "\n" \
          "worktree /tmp/worktree-1\n" \
          "HEAD b8c63202c3c0ebd37b7e45fd0c22e6c20d5bead1\n" \
          "detached\n"
        )
      end

      it 'returns a [directory, sha] pair for each worktree' do
        expect(result).to eq(
          [
            ['/path/to/main', '4bef5ab0c8e7c19c6be2c0f55ccd45eec1f3d32a'],
            ['/tmp/worktree-1', 'b8c63202c3c0ebd37b7e45fd0c22e6c20d5bead1']
          ]
        )
      end
    end

    context 'when a worktree path contains spaces' do
      let(:list_result) do
        command_result(
          "worktree /path/to/main\n" \
          "HEAD 4bef5ab0c8e7c19c6be2c0f55ccd45eec1f3d32a\n" \
          "branch refs/heads/main\n" \
          "\n" \
          "worktree /tmp/worktree with spaces\n" \
          "HEAD b8c63202c3c0ebd37b7e45fd0c22e6c20d5bead1\n" \
          "detached\n"
        )
      end

      it 'preserves the full directory path when parsing worktree entries' do
        expect(result).to eq(
          [
            ['/path/to/main', '4bef5ab0c8e7c19c6be2c0f55ccd45eec1f3d32a'],
            ['/tmp/worktree with spaces', 'b8c63202c3c0ebd37b7e45fd0c22e6c20d5bead1']
          ]
        )
      end
    end

    context 'when git output uses CRLF line endings' do
      let(:list_result) do
        command_result(
          "worktree /path/to/main\r\n" \
          "HEAD 4bef5ab0c8e7c19c6be2c0f55ccd45eec1f3d32a\r\n" \
          "branch refs/heads/main\r\n" \
          "\r\n" \
          "worktree /tmp/worktree with spaces\r\n" \
          "HEAD b8c63202c3c0ebd37b7e45fd0c22e6c20d5bead1\r\n" \
          "detached\r\n"
        )
      end

      it 'parses entries without carriage returns in directory or sha values' do
        expect(result).to eq(
          [
            ['/path/to/main', '4bef5ab0c8e7c19c6be2c0f55ccd45eec1f3d32a'],
            ['/tmp/worktree with spaces', 'b8c63202c3c0ebd37b7e45fd0c22e6c20d5bead1']
          ]
        )
      end
    end
  end

  describe '#worktree_add' do
    subject(:result) { described_instance.worktree_add(dir, commitish) }

    let(:dir) { '/tmp/feature' }
    let(:commitish) { nil }
    let(:add_command) { instance_double(Git::Commands::Worktree::Add) }
    let(:add_result) { command_result("Preparing worktree (new branch 'feature')\n") }

    before do
      allow(Git::Commands::Worktree::Add).to receive(:new).with(execution_context).and_return(add_command)
      allow(add_command).to receive(:call).and_return(add_result)
    end

    it 'constructs Git::Commands::Worktree::Add with the execution context' do
      expect(Git::Commands::Worktree::Add).to receive(:new).with(execution_context).and_return(add_command)
      described_instance.worktree_add(dir)
    end

    context 'when no commitish is given (nil)' do
      it 'calls #call with only the directory' do
        expect(add_command).to receive(:call).with(dir).and_return(add_result)
        described_instance.worktree_add(dir)
      end

      it 'returns the stdout string' do
        expect(result).to eq("Preparing worktree (new branch 'feature')\n")
      end
    end

    context 'when a commitish is given' do
      let(:commitish) { 'main' }

      it 'calls #call with the directory and the commitish' do
        expect(add_command).to receive(:call).with(dir, commitish).and_return(add_result)
        described_instance.worktree_add(dir, commitish)
      end

      it 'returns the stdout string' do
        expect(result).to eq("Preparing worktree (new branch 'feature')\n")
      end
    end
  end

  describe '#worktree_remove' do
    subject(:result) { described_instance.worktree_remove(dir) }

    let(:dir) { '/tmp/feature' }
    let(:remove_command) { instance_double(Git::Commands::Worktree::Remove) }
    let(:remove_result) { command_result('') }

    before do
      allow(Git::Commands::Worktree::Remove).to receive(:new).with(execution_context).and_return(remove_command)
      allow(remove_command).to receive(:call).with(dir).and_return(remove_result)
    end

    it 'constructs Git::Commands::Worktree::Remove with the execution context' do
      expect(Git::Commands::Worktree::Remove).to receive(:new).with(execution_context).and_return(remove_command)
      described_instance.worktree_remove(dir)
    end

    it 'calls #call with the directory' do
      expect(remove_command).to receive(:call).with(dir).and_return(remove_result)
      described_instance.worktree_remove(dir)
    end

    it 'returns the stdout string' do
      expect(result).to eq('')
    end
  end

  describe '#worktree_prune' do
    subject(:result) { described_instance.worktree_prune }

    let(:prune_command) { instance_double(Git::Commands::Worktree::Prune) }
    let(:prune_result) { command_result('') }

    before do
      allow(Git::Commands::Worktree::Prune).to receive(:new).with(execution_context).and_return(prune_command)
      allow(prune_command).to receive(:call).and_return(prune_result)
    end

    it 'constructs Git::Commands::Worktree::Prune with the execution context' do
      expect(Git::Commands::Worktree::Prune).to receive(:new).with(execution_context).and_return(prune_command)
      described_instance.worktree_prune
    end

    it 'calls #call with no arguments' do
      expect(prune_command).to receive(:call).with(no_args).and_return(prune_result)
      described_instance.worktree_prune
    end

    it 'returns the stdout string' do
      expect(result).to eq('')
    end
  end

  describe '#worktree' do
    subject(:result) { described_instance.worktree(dir, commitish) }

    let(:dir) { '/tmp/feature' }
    let(:commitish) { nil }
    let(:worktree_double) { instance_double(Git::Worktree) }

    context 'when called without a commitish' do
      it 'returns a Git::Worktree for the directory with no commitish' do
        expect(Git::Worktree).to receive(:new).with(described_instance, dir, nil).and_return(worktree_double)
        expect(result).to eq(worktree_double)
      end
    end

    context 'when called with a commitish' do
      let(:commitish) { 'main' }

      it 'returns a Git::Worktree for the directory and commitish' do
        expect(Git::Worktree).to receive(:new).with(described_instance, dir, commitish).and_return(worktree_double)
        expect(result).to eq(worktree_double)
      end
    end
  end

  describe '#worktrees' do
    subject(:result) { described_instance.worktrees }

    let(:worktrees_collection) { instance_double(Git::Worktrees) }

    it 'returns a Git::Worktrees collection for all worktrees' do
      expect(Git::Worktrees).to receive(:new).with(described_instance).and_return(worktrees_collection)
      expect(result).to eq(worktrees_collection)
    end
  end
end
