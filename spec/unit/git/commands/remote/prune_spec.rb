# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/remote/prune'

RSpec.describe Git::Commands::Remote::Prune do
  # Duck-type collaborator: command specs depend on the #command_capturing interface,
  # not a single concrete ExecutionContext class.
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with one remote name' do
      it 'passes the remote name' do
        expected_result = command_result
        expect_command_capturing('remote', 'prune', '--', 'origin').and_return(expected_result)

        result = command.call('origin')

        expect(result).to eq(expected_result)
      end
    end

    context 'with multiple remote names' do
      it 'passes all remote operands' do
        expect_command_capturing('remote', 'prune', '--', 'origin', 'upstream').and_return(command_result)

        command.call('origin', 'upstream')
      end
    end

    context 'with :dry_run option' do
      it 'includes --dry-run' do
        expect_command_capturing('remote', 'prune', '--dry-run', '--', 'origin').and_return(command_result)

        command.call('origin', dry_run: true)
      end

      it 'accepts :n alias' do
        expect_command_capturing('remote', 'prune', '--dry-run', '--', 'origin').and_return(command_result)

        command.call('origin', n: true)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError when no names are provided' do
        expect { command.call }.to raise_error(ArgumentError, /at least one value is required for name/)
      end

      it 'raises ArgumentError for unsupported options' do
        expect { command.call('origin', push: true) }.to raise_error(ArgumentError, /unsupported/i)
      end
    end
  end
end
