# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/branch/copy'

RSpec.describe Git::Commands::Branch::Copy do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with only new_branch (copy current branch)' do
      it 'runs branch --copy with only the new branch name' do
        expect(execution_context).to receive(:command)
          .with('branch', '--copy', 'new-name')
          .and_return(command_result(''))

        result = command.call('new-name')

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.stdout).to eq('')
      end
    end

    context 'with old_branch and new_branch' do
      it 'runs branch --copy with both branch names' do
        expect(execution_context).to receive(:command)
          .with('branch', '--copy', 'old-name', 'new-name')
          .and_return(command_result(''))

        result = command.call('old-name', 'new-name')

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'with :force option' do
      it 'adds --force flag when copying current branch' do
        expect(execution_context).to receive(:command)
          .with('branch', '--copy', '--force', 'new-name')
          .and_return(command_result(''))

        result = command.call('new-name', force: true)

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'adds --force flag when copying specific branch' do
        expect(execution_context).to receive(:command)
          .with('branch', '--copy', '--force', 'old-name', 'new-name')
          .and_return(command_result(''))

        result = command.call('old-name', 'new-name', force: true)

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'does not add flag when false' do
        expect(execution_context).to receive(:command)
          .with('branch', '--copy', 'new-name')
          .and_return(command_result(''))

        result = command.call('new-name', force: false)

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'with :f short option alias' do
      it 'adds --force flag when copying current branch' do
        expect(execution_context).to receive(:command)
          .with('branch', '--copy', '--force', 'new-name')
          .and_return(command_result(''))

        result = command.call('new-name', f: true)

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'adds --force flag when copying specific branch' do
        expect(execution_context).to receive(:command)
          .with('branch', '--copy', '--force', 'old-name', 'new-name')
          .and_return(command_result(''))

        result = command.call('old-name', 'new-name', f: true)

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError for unknown options' do
        expect { command.call('new-name', unknown: true) }.to raise_error(ArgumentError, /unknown/)
      end
    end
  end
end
