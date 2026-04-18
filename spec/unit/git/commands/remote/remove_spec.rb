# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/remote/remove'

RSpec.describe Git::Commands::Remote::Remove do
  # Duck-type collaborator: command specs depend on the #command_capturing interface,
  # not a single concrete ExecutionContext class.
  let(:execution_context) { execution_context_double }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with a remote name' do
      it 'passes the remote name' do
        expected_result = command_result
        expect_command_capturing('remote', 'remove', '--', 'origin').and_return(expected_result)

        result = command.call('origin')

        expect(result).to eq(expected_result)
      end
    end

    context 'with end-of-options separator' do
      it 'includes -- before the name operand' do
        expect_command_capturing('remote', 'remove', '--', '-weirdremote')
          .and_return(command_result)

        command.call('-weirdremote')
      end
    end

    context 'input validation' do
      it 'raises ArgumentError when name is missing' do
        expect { command.call }.to raise_error(ArgumentError, /name is required/)
      end

      it 'raises ArgumentError for unsupported options' do
        expect { command.call('origin', force: true) }.to raise_error(ArgumentError, /unsupported/i)
      end
    end
  end
end
