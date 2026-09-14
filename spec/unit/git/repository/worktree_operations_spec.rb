# frozen_string_literal: true

require 'spec_helper'
require 'git/repository'
require 'git/repository/worktree_operations'

# Integration-level coverage for facade methods in Git::Repository::WorktreeOperations:
#   worktree_prune is a one-line delegator to Git::Commands::Worktree::Prune with
#   no post-processing. Its end-to-end coverage comes from the command integration
#   test spec/integration/git/commands/worktree/prune_spec.rb.
#   worktree_list (parser post-processing), worktree_add (looking the new entry
#   up by its resolved path), and worktree_remove, worktree_move, worktree_lock,
#   worktree_unlock, and worktree_repair (a Git::WorktreeInfo argument reaching
#   git) are covered in spec/integration/git/repository/worktree_operations_spec.rb.

RSpec.describe Git::Repository::WorktreeOperations do
  let(:execution_context) { instance_double(Git::ExecutionContext::Repository) }
  let(:described_instance) { Git::Repository.new(execution_context: execution_context) }

  # Build a real Git::WorktreeInfo (not an instance_double) so the examples that
  # pass one to a facade method exercise Git::WorktreeInfo#to_s
  def worktree_info(path:, head:, **overrides)
    Git::WorktreeInfo.new(
      path: path, head: head, branch: nil, bare: false, detached: false,
      locked: false, lock_reason: nil, prunable: false, prune_reason: nil, **overrides
    )
  end

  let(:main_info) do
    worktree_info(
      path: '/path/to/main', head: '4bef5ab0c8e7c19c6be2c0f55ccd45eec1f3d32a', branch: 'refs/heads/main'
    )
  end

  let(:linked_info) do
    worktree_info(
      path: '/tmp/feature', head: 'b8c63202c3c0ebd37b7e45fd0c22e6c20d5bead1', branch: 'refs/heads/feature'
    )
  end

  describe '#worktree_list' do
    subject(:result) { described_instance.worktree_list }

    let(:list_command) { instance_double(Git::Commands::Worktree::List) }
    let(:list_result) { command_result('porcelain output') }
    let(:parsed_worktrees) { [main_info, linked_info] }

    before do
      allow(Git::Commands::Worktree::List).to receive(:new).with(execution_context).and_return(list_command)
      allow(list_command).to receive(:call).with(porcelain: true).and_return(list_result)
      allow(Git::Parsers::Worktree).to receive(:parse_list).with('porcelain output').and_return(parsed_worktrees)
    end

    it 'constructs Git::Commands::Worktree::List with the execution context' do
      expect(Git::Commands::Worktree::List).to receive(:new).with(execution_context).and_return(list_command)
      result
    end

    it 'lists worktrees in porcelain format then parses the output' do
      expect(list_command).to receive(:call).with(porcelain: true).and_return(list_result).ordered
      expect(Git::Parsers::Worktree).to(
        receive(:parse_list).with('porcelain output').and_return(parsed_worktrees).ordered
      )

      expect(result).to eq(parsed_worktrees)
    end

    context 'when no worktrees are reported' do
      let(:parsed_worktrees) { [] }

      it 'returns an empty array' do
        expect(result).to eq([])
      end
    end
  end

  describe '#worktree_add' do
    subject(:result) { described_instance.worktree_add(dir, commitish) }

    let(:dir) { '/tmp/feature' }
    let(:commitish) { nil }
    let(:add_command) { instance_double(Git::Commands::Worktree::Add) }
    let(:add_result) { command_result("HEAD is now at b8c6320 Add feature\n") }

    # git records the resolved path, which differs from dir when dir goes
    # through a symlink (/tmp on macOS) or differs in case, so the lookup must
    # compare by File.identical? rather than by string
    let(:added_info) do
      worktree_info(
        path: '/private/tmp/feature', head: 'b8c63202c3c0ebd37b7e45fd0c22e6c20d5bead1', branch: 'refs/heads/feature'
      )
    end

    before do
      allow(Git::Commands::Worktree::Add).to receive(:new).with(execution_context).and_return(add_command)
      allow(add_command).to receive(:call).and_return(add_result)
      allow(File).to receive(:identical?).and_return(false)
      allow(File).to receive(:identical?).with('/private/tmp/feature', dir).and_return(true)
      allow(described_instance).to receive(:worktree_list).and_return([main_info, added_info])
    end

    it 'constructs Git::Commands::Worktree::Add with the execution context' do
      expect(Git::Commands::Worktree::Add).to receive(:new).with(execution_context).and_return(add_command)
      described_instance.worktree_add(dir)
    end

    it 'runs the add before listing the worktrees' do
      expect(add_command).to receive(:call).with(dir).and_return(add_result).ordered
      expect(described_instance).to receive(:worktree_list).and_return([main_info, added_info]).ordered

      described_instance.worktree_add(dir)
    end

    it 'returns the Git::WorktreeInfo whose path is the same directory' do
      expect(result).to eq(added_info)
    end

    context 'when no commitish is given (nil)' do
      it 'calls #call with only the directory' do
        expect(add_command).to receive(:call).with(dir).and_return(add_result)
        described_instance.worktree_add(dir)
      end
    end

    context 'when a commitish is given' do
      let(:commitish) { 'main' }

      it 'calls #call with the directory and the commitish' do
        expect(add_command).to receive(:call).with(dir, commitish).and_return(add_result)
        described_instance.worktree_add(dir, commitish)
      end
    end

    context 'when the listing has no entry for the directory' do
      before do
        allow(described_instance).to receive(:worktree_list).and_return([main_info])
      end

      it 'raises Git::UnexpectedResultError naming the directory' do
        expect { result }.to raise_error(Git::UnexpectedResultError, %r{/tmp/feature})
      end
    end

    context 'when the add fails' do
      let(:failed_result) { command_result('', stderr: "fatal: '/tmp/feature' already exists\n", exitstatus: 128) }

      before do
        allow(add_command).to receive(:call).and_raise(Git::FailedError.new(failed_result))
      end

      it 'raises Git::FailedError without listing the worktrees' do
        expect(described_instance).not_to receive(:worktree_list)
        expect { result }.to raise_error(Git::FailedError)
      end
    end
  end

  describe '#worktree_remove' do
    subject(:result) { described_instance.worktree_remove(worktree) }

    let(:worktree) { '/tmp/feature' }
    let(:remove_command) { instance_double(Git::Commands::Worktree::Remove) }
    let(:remove_result) { command_result('') }

    before do
      allow(Git::Commands::Worktree::Remove).to receive(:new).with(execution_context).and_return(remove_command)
      allow(remove_command).to receive(:call).with('/tmp/feature').and_return(remove_result)
    end

    it 'constructs Git::Commands::Worktree::Remove with the execution context' do
      expect(Git::Commands::Worktree::Remove).to receive(:new).with(execution_context).and_return(remove_command)
      result
    end

    context 'when given a String path' do
      it 'calls #call with the path' do
        expect(remove_command).to receive(:call).with('/tmp/feature').and_return(remove_result)
        result
      end

      it 'returns the stdout string' do
        expect(result).to eq('')
      end
    end

    context 'when given a Git::WorktreeInfo' do
      let(:worktree) { linked_info }

      it 'calls #call with the path of the worktree' do
        expect(remove_command).to receive(:call).with('/tmp/feature').and_return(remove_result)
        result
      end
    end
  end

  describe '#worktree_move' do
    subject(:result) { described_instance.worktree_move(worktree, new_path) }

    let(:worktree) { '/tmp/feature' }
    let(:new_path) { '/tmp/feature-moved' }
    let(:move_command) { instance_double(Git::Commands::Worktree::Move) }
    let(:move_result) { command_result('') }

    before do
      allow(Git::Commands::Worktree::Move).to receive(:new).with(execution_context).and_return(move_command)
      allow(move_command).to receive(:call).and_return(move_result)
    end

    it 'constructs Git::Commands::Worktree::Move with the execution context' do
      expect(Git::Commands::Worktree::Move).to receive(:new).with(execution_context).and_return(move_command)
      result
    end

    context 'when given a String path' do
      it 'calls #call with the path and the new path' do
        expect(move_command).to receive(:call).with('/tmp/feature', '/tmp/feature-moved').and_return(move_result)
        result
      end

      it 'returns the stdout string' do
        expect(result).to eq('')
      end
    end

    context 'when given a Git::WorktreeInfo' do
      let(:worktree) { linked_info }

      it 'calls #call with the path of the worktree and the new path' do
        expect(move_command).to receive(:call).with('/tmp/feature', '/tmp/feature-moved').and_return(move_result)
        result
      end
    end

    context 'with the force option' do
      it 'forwards force: to #call' do
        expect(move_command).to(
          receive(:call).with('/tmp/feature', '/tmp/feature-moved', force: true).and_return(move_result)
        )
        described_instance.worktree_move(worktree, new_path, force: true)
      end
    end

    context 'signature compatibility' do
      it 'accepts the options as a positional Hash' do
        expect(move_command).to(
          receive(:call).with('/tmp/feature', '/tmp/feature-moved', force: true).and_return(move_result)
        )
        described_instance.worktree_move(worktree, new_path, { force: true })
      end
    end
  end

  describe '#worktree_lock' do
    subject(:result) { described_instance.worktree_lock(worktree) }

    let(:worktree) { '/tmp/feature' }
    let(:lock_command) { instance_double(Git::Commands::Worktree::Lock) }
    let(:lock_result) { command_result('') }

    before do
      allow(Git::Commands::Worktree::Lock).to receive(:new).with(execution_context).and_return(lock_command)
      allow(lock_command).to receive(:call).and_return(lock_result)
    end

    it 'constructs Git::Commands::Worktree::Lock with the execution context' do
      expect(Git::Commands::Worktree::Lock).to receive(:new).with(execution_context).and_return(lock_command)
      result
    end

    context 'when given a String path' do
      it 'calls #call with the path' do
        expect(lock_command).to receive(:call).with('/tmp/feature').and_return(lock_result)
        result
      end

      it 'returns the stdout string' do
        expect(result).to eq('')
      end
    end

    context 'when given a Git::WorktreeInfo' do
      let(:worktree) { linked_info }

      it 'calls #call with the path of the worktree' do
        expect(lock_command).to receive(:call).with('/tmp/feature').and_return(lock_result)
        result
      end
    end

    context 'with the reason option' do
      it 'forwards reason: to #call' do
        expect(lock_command).to receive(:call).with('/tmp/feature', reason: 'on NFS share').and_return(lock_result)
        described_instance.worktree_lock(worktree, reason: 'on NFS share')
      end
    end

    context 'signature compatibility' do
      it 'accepts the options as a positional Hash' do
        expect(lock_command).to receive(:call).with('/tmp/feature', reason: 'on NFS share').and_return(lock_result)
        described_instance.worktree_lock(worktree, { reason: 'on NFS share' })
      end
    end
  end

  describe '#worktree_unlock' do
    subject(:result) { described_instance.worktree_unlock(worktree) }

    let(:worktree) { '/tmp/feature' }
    let(:unlock_command) { instance_double(Git::Commands::Worktree::Unlock) }
    let(:unlock_result) { command_result('') }

    before do
      allow(Git::Commands::Worktree::Unlock).to receive(:new).with(execution_context).and_return(unlock_command)
      allow(unlock_command).to receive(:call).with('/tmp/feature').and_return(unlock_result)
    end

    it 'constructs Git::Commands::Worktree::Unlock with the execution context' do
      expect(Git::Commands::Worktree::Unlock).to receive(:new).with(execution_context).and_return(unlock_command)
      result
    end

    context 'when given a String path' do
      it 'calls #call with the path' do
        expect(unlock_command).to receive(:call).with('/tmp/feature').and_return(unlock_result)
        result
      end

      it 'returns the stdout string' do
        expect(result).to eq('')
      end
    end

    context 'when given a Git::WorktreeInfo' do
      let(:worktree) { linked_info }

      it 'calls #call with the path of the worktree' do
        expect(unlock_command).to receive(:call).with('/tmp/feature').and_return(unlock_result)
        result
      end
    end
  end

  describe '#worktree_repair' do
    let(:repair_command) { instance_double(Git::Commands::Worktree::Repair) }
    let(:repair_result) { command_result('') }

    before do
      allow(Git::Commands::Worktree::Repair).to receive(:new).with(execution_context).and_return(repair_command)
      allow(repair_command).to receive(:call).and_return(repair_result)
    end

    it 'constructs Git::Commands::Worktree::Repair with the execution context' do
      expect(Git::Commands::Worktree::Repair).to receive(:new).with(execution_context).and_return(repair_command)
      described_instance.worktree_repair
    end

    context 'when no paths are given' do
      it 'calls #call with no arguments' do
        expect(repair_command).to receive(:call).with(no_args).and_return(repair_result)
        described_instance.worktree_repair
      end

      it 'returns the stdout string' do
        expect(described_instance.worktree_repair).to eq('')
      end
    end

    context 'when given a String path' do
      it 'calls #call with the path' do
        expect(repair_command).to receive(:call).with('/tmp/feature').and_return(repair_result)
        described_instance.worktree_repair('/tmp/feature')
      end
    end

    context 'when given several paths including a Git::WorktreeInfo' do
      it 'calls #call with the path of each worktree' do
        expect(repair_command).to receive(:call).with('/tmp/other', '/tmp/feature').and_return(repair_result)
        described_instance.worktree_repair('/tmp/other', linked_info)
      end
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
end
