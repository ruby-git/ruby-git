# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/branch/delete'
require 'git/commands/branch/list'
require 'git/branch_delete_result'
require 'git/branch_delete_failure'

RSpec.describe Git::Commands::Branch::Delete do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  # Create a BranchInfo for testing
  def build_branch_info(branch_name)
    Git::BranchInfo.new(
      refname: branch_name,
      target_oid: 'abc1234',
      current: false,
      worktree: false,
      symref: nil,
      upstream: nil
    )
  end

  # Build a successful command result
  def build_result(stdout: '', stderr: '', exitstatus: 0)
    status = instance_double(Process::Status, exitstatus: exitstatus)
    instance_double(Git::CommandLineResult, stdout: stdout, stderr: stderr, status: status)
  end

  # Set up mock for Branch::List command for specified branches
  def stub_list_commands(existing_branches)
    list_command = instance_double(Git::Commands::Branch::List)
    allow(Git::Commands::Branch::List).to receive(:new).with(execution_context).and_return(list_command)
    allow(list_command).to receive(:call) do |name|
      existing_branches.key?(name) ? [existing_branches[name]].compact : []
    end
  end

  describe '#call' do
    context 'with single branch name (successful deletion)' do
      it 'returns BranchDeleteResult with deleted branch' do
        branch_info = build_branch_info('feature-branch')
        stub_list_commands('feature-branch' => branch_info)
        result = build_result(stdout: "Deleted branch feature-branch (was abc1234).\n", exitstatus: 0)
        expect(execution_context).to receive(:command)
          .with('branch', '--delete', 'feature-branch', raise_on_failure: false)
          .and_return(result)

        delete_result = command.call('feature-branch')

        expect(delete_result).to be_a(Git::BranchDeleteResult)
        expect(delete_result.success?).to be true
        expect(delete_result.deleted).to eq([branch_info])
        expect(delete_result.not_deleted).to be_empty
      end
    end

    context 'with multiple branch names (all successful)' do
      it 'returns all deleted branches' do
        branch1 = build_branch_info('branch1')
        branch2 = build_branch_info('branch2')
        branch3 = build_branch_info('branch3')
        stub_list_commands('branch1' => branch1, 'branch2' => branch2, 'branch3' => branch3)

        stdout = <<~OUTPUT
          Deleted branch branch1 (was abc1234).
          Deleted branch branch2 (was abc1234).
          Deleted branch branch3 (was abc1234).
        OUTPUT
        result = build_result(stdout: stdout, exitstatus: 0)
        expect(execution_context).to receive(:command)
          .with('branch', '--delete', 'branch1', 'branch2', 'branch3', raise_on_failure: false)
          .and_return(result)

        delete_result = command.call('branch1', 'branch2', 'branch3')

        expect(delete_result.success?).to be true
        expect(delete_result.deleted).to eq([branch1, branch2, branch3])
        expect(delete_result.not_deleted).to be_empty
      end
    end

    context 'with partial failure (some branches not found)' do
      it 'returns deleted branches and failures' do
        branch1 = build_branch_info('branch1')
        branch3 = build_branch_info('branch3')
        stub_list_commands('branch1' => branch1, 'nonexistent' => nil, 'branch3' => branch3)

        stdout = <<~OUTPUT
          Deleted branch branch1 (was abc1234).
          Deleted branch branch3 (was abc1234).
        OUTPUT
        stderr = "error: branch 'nonexistent' not found.\n"
        result = build_result(stdout: stdout, stderr: stderr, exitstatus: 1)
        expect(execution_context).to receive(:command)
          .with('branch', '--delete', 'branch1', 'nonexistent', 'branch3', raise_on_failure: false)
          .and_return(result)

        delete_result = command.call('branch1', 'nonexistent', 'branch3')

        expect(delete_result.success?).to be false
        expect(delete_result.deleted).to eq([branch1, branch3])
        expect(delete_result.not_deleted.size).to eq(1)
        expect(delete_result.not_deleted.first.name).to eq('nonexistent')
        expect(delete_result.not_deleted.first.error_message).to include('nonexistent')
      end
    end

    context 'with :force option' do
      it 'adds --force flag' do
        branch_info = build_branch_info('feature-branch')
        stub_list_commands('feature-branch' => branch_info)
        result = build_result(stdout: "Deleted branch feature-branch (was abc1234).\n", exitstatus: 0)
        expect(execution_context).to receive(:command)
          .with('branch', '--delete', '--force', 'feature-branch', raise_on_failure: false)
          .and_return(result)

        delete_result = command.call('feature-branch', force: true)
        expect(delete_result.success?).to be true
      end

      it 'accepts :f alias' do
        branch_info = build_branch_info('feature-branch')
        stub_list_commands('feature-branch' => branch_info)
        result = build_result(stdout: "Deleted branch feature-branch (was abc1234).\n", exitstatus: 0)
        expect(execution_context).to receive(:command)
          .with('branch', '--delete', '--force', 'feature-branch', raise_on_failure: false)
          .and_return(result)

        delete_result = command.call('feature-branch', f: true)
        expect(delete_result.success?).to be true
      end
    end

    context 'with :remotes option' do
      it 'adds --remotes flag for remote-tracking branches' do
        branch_info = build_branch_info('origin/feature')
        stub_list_commands('origin/feature' => branch_info)
        result = build_result(stdout: "Deleted branch origin/feature (was abc1234).\n", exitstatus: 0)
        expect(execution_context).to receive(:command)
          .with('branch', '--delete', '--remotes', 'origin/feature', raise_on_failure: false)
          .and_return(result)

        delete_result = command.call('origin/feature', remotes: true)
        expect(delete_result.success?).to be true
      end

      it 'accepts :r alias' do
        branch_info = build_branch_info('origin/feature')
        stub_list_commands('origin/feature' => branch_info)
        result = build_result(stdout: "Deleted branch origin/feature (was abc1234).\n", exitstatus: 0)
        expect(execution_context).to receive(:command)
          .with('branch', '--delete', '--remotes', 'origin/feature', raise_on_failure: false)
          .and_return(result)

        delete_result = command.call('origin/feature', r: true)
        expect(delete_result.success?).to be true
      end
    end

    context 'with multiple options combined' do
      it 'includes all specified flags in correct order' do
        branch_info = build_branch_info('origin/feature')
        stub_list_commands('origin/feature' => branch_info)
        result = build_result(stdout: "Deleted remote-tracking branch origin/feature (was abc1234).\n", exitstatus: 0)
        expect(execution_context).to receive(:command)
          .with('branch', '--delete', '--force', '--remotes', 'origin/feature', raise_on_failure: false)
          .and_return(result)

        delete_result = command.call('origin/feature', force: true, remotes: true)
        expect(delete_result.success?).to be true
      end
    end

    context 'when deleting remote-tracking branches' do
      it 'parses "Deleted remote-tracking branch" output correctly' do
        branch_info = build_branch_info('origin/feature')
        stub_list_commands('origin/feature' => branch_info)

        stdout = "Deleted remote-tracking branch origin/feature (was abc1234).\n"
        result = build_result(stdout: stdout, exitstatus: 0)
        expect(execution_context).to receive(:command)
          .with('branch', '--delete', '--remotes', 'origin/feature', raise_on_failure: false)
          .and_return(result)

        delete_result = command.call('origin/feature', remotes: true)

        expect(delete_result.success?).to be true
        expect(delete_result.deleted.size).to eq(1)
        expect(delete_result.deleted.first).to eq(branch_info)
      end

      it 'passes remotes option to lookup_existing_branches' do
        list_command = instance_double(Git::Commands::Branch::List)
        allow(Git::Commands::Branch::List).to receive(:new).with(execution_context).and_return(list_command)

        # Expect the call to include remotes: true
        expect(list_command).to receive(:call).with('origin/feature', remotes: true).and_return([])

        result = build_result(stdout: '', stderr: "error: branch 'origin/feature' not found.\n", exitstatus: 1)
        expect(execution_context).to receive(:command)
          .with('branch', '--delete', '--remotes', 'origin/feature', raise_on_failure: false)
          .and_return(result)

        command.call('origin/feature', remotes: true)
      end
    end
  end
end
