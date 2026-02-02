# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/branch/set_upstream'

RSpec.describe Git::Commands::Branch::SetUpstream do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  # BranchInfo format output for mocking Branch::List
  let(:branch_info_output) do
    'refs/heads/feature|abc123def456789012345678901234567890abcd||||refs/remotes/origin/main'
  end

  # Helper to stub the branch list command that returns branch info
  def stub_list_command
    allow(execution_context).to receive(:command)
      .with('branch', '--list', any_args)
      .and_return(command_result(branch_info_output))
  end

  describe '#call' do
    context 'with only set_upstream_to (set upstream for current branch)' do
      it 'calls git branch --set-upstream-to=<upstream>' do
        expect(execution_context).to receive(:command)
          .with('branch', '--set-upstream-to=origin/main').ordered
        stub_list_command
        command.call(set_upstream_to: 'origin/main')
      end
    end

    context 'with -u short alias' do
      it 'calls git branch --set-upstream-to=<upstream>' do
        expect(execution_context).to receive(:command)
          .with('branch', '--set-upstream-to=origin/main').ordered
        stub_list_command
        command.call(u: 'origin/main')
      end
    end

    context 'with set_upstream_to and branch_name' do
      it 'calls git branch --set-upstream-to=<upstream> <branch>' do
        expect(execution_context).to receive(:command)
          .with('branch', '--set-upstream-to=origin/main', 'feature').ordered
        stub_list_command
        command.call('feature', set_upstream_to: 'origin/main')
      end
    end

    context 'with remote-tracking branch as upstream' do
      it 'accepts various remote-tracking branch formats' do
        expect(execution_context).to receive(:command)
          .with('branch', '--set-upstream-to=upstream/develop').ordered
        stub_list_command
        command.call(set_upstream_to: 'upstream/develop')
      end
    end

    context 'with missing set_upstream_to' do
      it 'raises ArgumentError' do
        expect { command.call }.to raise_error(ArgumentError)
      end

      it 'raises ArgumentError even when branch_name is provided' do
        expect { command.call('feature') }.to raise_error(ArgumentError)
      end
    end

    context 'with unsupported options' do
      it 'raises ArgumentError for unknown options' do
        expect do
          command.call(set_upstream_to: 'origin/main', unknown: true)
        end.to raise_error(ArgumentError, /unknown/)
      end
    end

    context 'return value' do
      it 'returns a BranchInfo with upstream set' do
        allow(execution_context).to receive(:command)
          .with('branch', '--set-upstream-to=origin/main', 'feature')
        stub_list_command
        result = command.call('feature', set_upstream_to: 'origin/main')

        expect(result).to be_a(Git::BranchInfo)
        expect(result.refname).to eq('feature')
        expect(result.upstream).to be_a(Git::BranchInfo)
        expect(result.upstream.refname).to eq('remotes/origin/main')
      end
    end
  end
end
