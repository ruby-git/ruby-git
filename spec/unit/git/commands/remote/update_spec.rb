# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/remote/update'

RSpec.describe Git::Commands::Remote::Update do
  # Duck-type collaborator: command specs depend on the #command_capturing interface,
  # not a single concrete ExecutionContext class.
  let(:execution_context) { execution_context_double }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with no operands' do
      it 'runs git remote update' do
        expected_result = command_result
        expect_command_capturing('remote', 'update').and_return(expected_result)

        result = command.call

        expect(result).to eq(expected_result)
      end
    end

    context 'with a single operand' do
      it 'passes the operand after the subcommand' do
        expect_command_capturing('remote', 'update', '--', 'origin').and_return(command_result)

        command.call('origin')
      end
    end

    context 'with multiple operands' do
      it 'passes each operand after the subcommand' do
        expect_command_capturing('remote', 'update', '--', 'origin', 'staging').and_return(command_result)

        command.call('origin', 'staging')
      end
    end

    context 'with :verbose option' do
      it 'includes --verbose before the update subcommand' do
        expect_command_capturing('remote', '--verbose', 'update').and_return(command_result)

        command.call(verbose: true)
      end

      it 'accepts :v alias' do
        expect_command_capturing('remote', '--verbose', 'update').and_return(command_result)

        command.call(v: true)
      end
    end

    context 'with :prune option' do
      it 'includes --prune after the update subcommand' do
        expect_command_capturing('remote', 'update', '--prune').and_return(command_result)

        command.call(prune: true)
      end

      it 'accepts :p alias' do
        expect_command_capturing('remote', 'update', '--prune').and_return(command_result)

        command.call(p: true)
      end

      it 'passes operands after end-of-options when combined' do
        expect_command_capturing('remote', 'update', '--prune', '--', 'origin').and_return(command_result)

        command.call('origin', prune: true)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError for unsupported options' do
        expect { command.call(no_query: true) }.to raise_error(ArgumentError, /unsupported/i)
      end
    end
  end
end
