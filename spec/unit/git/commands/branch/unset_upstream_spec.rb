# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/branch/unset_upstream'

RSpec.describe Git::Commands::Branch::UnsetUpstream do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  # BranchInfo format output for mocking Branch::List (no upstream after unset)
  let(:branch_info_output) do
    'refs/heads/feature|abc123def456789012345678901234567890abcd||||'
  end

  # Helper to stub the branch list command that returns branch info
  def stub_list_command
    allow(execution_context).to receive(:command)
      .with('branch', '--list', any_args)
      .and_return(command_result(branch_info_output))
  end

  describe '#call' do
    context 'with no arguments (unset upstream for current branch)' do
      it 'calls git branch --unset-upstream' do
        expect(execution_context).to receive(:command).with('branch', '--unset-upstream').ordered
        stub_list_command
        command.call
      end
    end

    context 'with branch_name' do
      it 'calls git branch --unset-upstream <branch>' do
        expect(execution_context).to receive(:command)
          .with('branch', '--unset-upstream', 'feature').ordered
        stub_list_command
        command.call('feature')
      end
    end

    context 'with nil branch_name' do
      it 'calls git branch --unset-upstream (nil is treated as not provided)' do
        expect(execution_context).to receive(:command).with('branch', '--unset-upstream').ordered
        stub_list_command
        command.call(nil)
      end
    end

    context 'with unsupported options' do
      it 'raises ArgumentError for unknown options' do
        expect { command.call(unknown: true) }.to raise_error(ArgumentError, /unknown/)
      end
    end

    context 'return value' do
      it 'returns a BranchInfo with upstream nil' do
        allow(execution_context).to receive(:command).with('branch', '--unset-upstream', 'feature')
        stub_list_command
        result = command.call('feature')

        expect(result).to be_a(Git::BranchInfo)
        expect(result.refname).to eq('feature')
        expect(result.upstream).to be_nil
      end
    end
  end
end
