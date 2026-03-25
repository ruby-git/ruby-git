# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/remote/show'

RSpec.describe Git::Commands::Remote::Show do
  # Duck-type collaborator: command specs depend on the #command_capturing interface,
  # not a single concrete ExecutionContext class.
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with one remote name' do
      it 'passes the remote name after show' do
        expected_result = command_result("* remote origin\n")
        expect_command_capturing('remote', 'show', '--', 'origin').and_return(expected_result)

        result = command.call('origin')

        expect(result).to eq(expected_result)
      end
    end

    context 'with multiple remote names' do
      it 'passes all remote operands' do
        expect_command_capturing('remote', 'show', '--', 'origin', 'upstream').and_return(command_result)

        command.call('origin', 'upstream')
      end
    end

    context 'with :verbose option' do
      it 'includes --verbose before the show subcommand' do
        expect_command_capturing('remote', '--verbose', 'show', '--', 'origin').and_return(command_result)

        command.call('origin', verbose: true)
      end

      it 'accepts :v alias' do
        expect_command_capturing('remote', '--verbose', 'show', '--', 'origin').and_return(command_result)

        command.call('origin', v: true)
      end
    end

    context 'with :n option' do
      it 'includes -n after the show subcommand' do
        expect_command_capturing('remote', 'show', '-n', '--', 'origin').and_return(command_result)

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
