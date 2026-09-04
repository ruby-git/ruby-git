# frozen_string_literal: true

require 'spec_helper'
require 'git/repository'
require 'git/repository/worktree_operations'

# Integration-level coverage for facade methods in Git::Repository::WorktreeOperations:
#   worktree_add and worktree_prune are one-line delegators to single
#   Git::Commands::Worktree::* classes with no post-processing. Their end-to-end
#   coverage comes from the command integration tests:
#     spec/integration/git/commands/worktree/add_spec.rb   (worktree_add)
#     spec/integration/git/commands/worktree/prune_spec.rb (worktree_prune)
#   worktree_list and worktrees_all (parser post-processing) and worktree_remove,
#   worktree_move, worktree_lock, worktree_unlock, and worktree_repair (a
#   Git::WorktreeInfo argument reaching git) are covered in
#   spec/integration/git/repository/worktree_operations_spec.rb.
#   worktree and worktrees are deprecated factory methods that construct domain
#   objects (Git::Worktree and Git::Worktrees) without running git commands
#   directly; their behavior is fully covered by the unit tests below.

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

  let(:bare_info) { worktree_info(path: '/path/to/repo.git', head: nil, bare: true) }

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

  describe '#worktrees_all' do
    subject(:result) { described_instance.worktrees_all }

    let(:list_command) { instance_double(Git::Commands::Worktree::List) }
    let(:list_result) { command_result('porcelain output') }
    let(:parsed_worktrees) { [main_info, linked_info] }

    before do
      allow(Git::Deprecation).to receive(:warn)
      allow(Git::Commands::Worktree::List).to receive(:new).with(execution_context).and_return(list_command)
      allow(list_command).to receive(:call).with(porcelain: true).and_return(list_result)
      allow(Git::Parsers::Worktree).to receive(:parse_list).with('porcelain output').and_return(parsed_worktrees)
    end

    it 'emits a deprecation warning via Git::Deprecation.warn' do
      expect(Git::Deprecation).to receive(:warn).with(
        'Git::Repository#worktrees_all is deprecated and will be removed in v6.0.0. ' \
        'Use Git::Repository#worktree_list instead.'
      )
      result
    end

    it 'lists worktrees in porcelain format then parses the output' do
      expect(list_command).to receive(:call).with(porcelain: true).and_return(list_result).ordered
      expect(Git::Parsers::Worktree).to(
        receive(:parse_list).with('porcelain output').and_return(parsed_worktrees).ordered
      )

      result
    end

    it 'returns a [directory, sha] pair for each worktree' do
      expect(result).to eq(
        [
          ['/path/to/main', '4bef5ab0c8e7c19c6be2c0f55ccd45eec1f3d32a'],
          ['/tmp/feature', 'b8c63202c3c0ebd37b7e45fd0c22e6c20d5bead1']
        ]
      )
    end

    context 'when no worktrees are reported' do
      let(:parsed_worktrees) { [] }

      it 'returns an empty array' do
        expect(result).to eq([])
      end
    end

    context 'when the listing includes a bare main worktree' do
      let(:parsed_worktrees) { [bare_info, linked_info] }

      it 'omits the bare worktree, which has no HEAD' do
        expect(result).to eq([['/tmp/feature', 'b8c63202c3c0ebd37b7e45fd0c22e6c20d5bead1']])
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

  describe '#worktree' do
    subject(:result) { described_instance.worktree(dir, commitish) }

    let(:dir) { '/tmp/feature' }
    let(:commitish) { nil }
    let(:worktree_double) { instance_double(Git::Worktree) }

    before do
      allow(Git::Deprecation).to receive(:warn)
      allow(Git::Worktree).to receive(:new).and_return(worktree_double)
    end

    it 'emits a deprecation warning via Git::Deprecation.warn' do
      expect(Git::Deprecation).to receive(:warn).with(
        'Git::Repository#worktree is deprecated and will be removed in v6.0.0. ' \
        'Use Git::Repository#worktree_add and Git::Repository#worktree_remove instead.'
      )
      result
    end

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

    before do
      allow(Git::Deprecation).to receive(:warn)
      allow(Git::Worktrees).to receive(:new).with(described_instance).and_return(worktrees_collection)
    end

    it 'emits a deprecation warning via Git::Deprecation.warn' do
      expect(Git::Deprecation).to receive(:warn).with(
        'Git::Repository#worktrees is deprecated and will be removed in v6.0.0. ' \
        'Use Git::Repository#worktree_list instead.'
      )
      result
    end

    it 'returns a Git::Worktrees collection for all worktrees' do
      expect(Git::Worktrees).to receive(:new).with(described_instance).and_return(worktrees_collection)
      expect(result).to eq(worktrees_collection)
    end
  end
end
