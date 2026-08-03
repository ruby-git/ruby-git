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
        expect_command_capturing('remote', 'remove', 'origin').and_return(expected_result)

        result = command.call('origin')

        expect(result).to eq(expected_result)
      end
    end

    context 'with a name that looks like a flag' do
      it 'raises ArgumentError instead of sending it to git' do
        expect { command.call('-weirdremote') }
          .to raise_error(ArgumentError, /looks like a command-line option/)
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
