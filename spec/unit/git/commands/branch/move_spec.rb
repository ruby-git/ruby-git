# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/branch/move'
require 'git/commands/branch/list'

RSpec.describe Git::Commands::Branch::Move do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  # Create a BranchInfo for testing
  def build_branch_info(branch_name)
    Git::BranchInfo.new(
      refname: branch_name,
      target_oid: nil,
      current: false,
      worktree: false,
      symref: nil,
      upstream: nil
    )
  end

  # Set up mock for Branch::List command
  def stub_list_command(branch_name, expected_branch_info)
    list_command = instance_double(Git::Commands::Branch::List)
    allow(Git::Commands::Branch::List).to receive(:new).with(execution_context).and_return(list_command)
    allow(list_command).to receive(:call).with(branch_name).and_return([expected_branch_info])
  end

  # Helper to set up expectations for both the move command and the subsequent list lookup
  def expect_move_and_list(expected_args, branch_name:)
    expected_branch_info = build_branch_info(branch_name)
    stub_list_command(branch_name, expected_branch_info)
    expect(execution_context).to receive(:command).with(*expected_args)
    expected_branch_info
  end

  describe '#call' do
    context 'with only new_branch (rename current branch)' do
      it 'calls git branch --move with only the new branch name and returns BranchInfo' do
        expected_branch_info = expect_move_and_list(['branch', '--move', 'new-name'], branch_name: 'new-name')
        result = command.call('new-name')
        expect(result).to eq(expected_branch_info)
      end
    end

    context 'with old_branch and new_branch' do
      it 'calls git branch --move with both branch names and returns BranchInfo' do
        expected_branch_info = expect_move_and_list(
          ['branch', '--move', 'old-name', 'new-name'],
          branch_name: 'new-name'
        )
        result = command.call('old-name', 'new-name')
        expect(result).to eq(expected_branch_info)
      end
    end

    context 'with :force option' do
      it 'adds --force flag when renaming current branch' do
        expected_branch_info = expect_move_and_list(
          ['branch', '--move', '--force', 'new-name'],
          branch_name: 'new-name'
        )
        result = command.call('new-name', force: true)
        expect(result).to eq(expected_branch_info)
      end

      it 'adds --force flag when renaming specific branch' do
        expected_branch_info = expect_move_and_list(
          ['branch', '--move', '--force', 'old-name', 'new-name'],
          branch_name: 'new-name'
        )
        result = command.call('old-name', 'new-name', force: true)
        expect(result).to eq(expected_branch_info)
      end

      it 'does not add flag when false' do
        expected_branch_info = expect_move_and_list(['branch', '--move', 'new-name'], branch_name: 'new-name')
        result = command.call('new-name', force: false)
        expect(result).to eq(expected_branch_info)
      end
    end

    context 'with :f short option alias' do
      it 'adds --force flag when renaming current branch' do
        expected_branch_info = expect_move_and_list(
          ['branch', '--move', '--force', 'new-name'],
          branch_name: 'new-name'
        )
        result = command.call('new-name', f: true)
        expect(result).to eq(expected_branch_info)
      end

      it 'adds --force flag when renaming specific branch' do
        expected_branch_info = expect_move_and_list(
          ['branch', '--move', '--force', 'old-name', 'new-name'],
          branch_name: 'new-name'
        )
        result = command.call('old-name', 'new-name', f: true)
        expect(result).to eq(expected_branch_info)
      end
    end

    context 'with unsupported options' do
      it 'raises ArgumentError for unknown options' do
        expect { command.call('new-name', unknown: true) }.to raise_error(ArgumentError, /unknown/)
      end
    end
  end
end
