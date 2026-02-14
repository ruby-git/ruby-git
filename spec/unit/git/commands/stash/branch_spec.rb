# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/stash/branch'

RSpec.describe Git::Commands::Stash::Branch do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with branch name only (latest stash)' do
      it 'runs stash branch with the given branch name' do
        expect(execution_context).to receive(:command)
          .with('stash', 'branch', 'my-feature')
          .and_return(command_result("Switched to a new branch 'my-feature'\n"))

        result = command.call('my-feature')

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.stdout).to eq("Switched to a new branch 'my-feature'\n")
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
        expect(execution_context).to receive(:command)
          .with('stash', 'branch', 'feature/new-thing')
          .and_return(command_result(''))

        command.call('feature/new-thing')
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
