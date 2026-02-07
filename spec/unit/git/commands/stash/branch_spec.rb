# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/stash/branch'
require 'git/commands/branch/list'
require 'git/branch_info'

RSpec.describe Git::Commands::Stash::Branch do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }
  let(:list_output) { "refs/heads/my-feature|abc123def456789012345678901234567890abcd|*|||\n" }
  let(:list_result) { command_result(list_output) }
  let(:list_command) { instance_double(Git::Commands::Branch::List) }

  before do
    allow(Git::Commands::Branch::List).to receive(:new).with(execution_context).and_return(list_command)
    allow(list_command).to receive(:call).and_return(list_result)
  end

  describe '#call' do
    context 'with branch name only (latest stash)' do
      it 'calls git stash branch with branch name' do
        expect(execution_context).to receive(:command)
          .with('stash', 'branch', 'my-feature')
          .and_return(command_result(''))

        command.call('my-feature')
      end

      it 'returns BranchInfo for the created branch' do
        allow(execution_context).to receive(:command)
          .with('stash', 'branch', 'my-feature')
          .and_return(command_result("Switched to a new branch 'my-feature'\n"))

        result = command.call('my-feature')

        expect(result).to be_a(Git::BranchInfo)
        expect(result.refname).to eq('my-feature')
      end

      it 'queries Branch::List for the new branch info' do
        allow(execution_context).to receive(:command).and_return(command_result(''))

        expect(list_command).to receive(:call).with('my-feature').and_return(list_result)

        command.call('my-feature')
      end
    end

    context 'with branch name and stash reference' do
      it 'passes stash reference to command' do
        expect(execution_context).to receive(:command)
          .with('stash', 'branch', 'my-feature', 'stash@{2}')
          .and_return(command_result(''))

        command.call('my-feature', 'stash@{2}')
      end

      it 'accepts numeric stash reference' do
        expect(execution_context).to receive(:command)
          .with('stash', 'branch', 'bugfix', '1')
          .and_return(command_result(''))

        command.call('bugfix', '1')
      end
    end

    context 'with special branch names' do
      it 'handles branch names with slashes' do
        slashed_list_result = command_result(
          "refs/heads/feature/new-thing|abc123def456789012345678901234567890abcd|*|||\n"
        )
        allow(list_command).to receive(:call).with('feature/new-thing').and_return(slashed_list_result)

        expect(execution_context).to receive(:command)
          .with('stash', 'branch', 'feature/new-thing')
          .and_return(command_result(''))

        result = command.call('feature/new-thing')
        expect(result.refname).to eq('feature/new-thing')
      end

      it 'handles branch names with hyphens' do
        expect(execution_context).to receive(:command)
          .with('stash', 'branch', 'fix-bug-123')
          .and_return(command_result(''))

        command.call('fix-bug-123')
      end
    end

    context 'with nil stash reference' do
      it 'omits nil stash from arguments' do
        expect(execution_context).to receive(:command)
          .with('stash', 'branch', 'my-branch')
          .and_return(command_result(''))

        command.call('my-branch', nil)
      end
    end
  end
end
