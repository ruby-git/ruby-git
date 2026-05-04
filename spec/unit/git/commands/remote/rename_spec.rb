# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/remote/rename'

RSpec.describe Git::Commands::Remote::Rename do
  # Duck-type collaborator: command specs depend on the #command_capturing interface,
  # not a single concrete ExecutionContext class.
  let(:execution_context) { execution_context_double }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with old and new names' do
      it 'passes both names' do
        expected_result = command_result
        expect_command_capturing('remote', 'rename', '--', 'origin', 'upstream').and_return(expected_result)

        result = command.call('origin', 'upstream')

        expect(result).to eq(expected_result)
      end
    end

    context 'with :progress option' do
      context 'when true' do
        it 'includes --progress flag' do
          expect_command_capturing('remote', 'rename', '--progress', '--', 'origin',
                                   'upstream').and_return(command_result)

          command.call('origin', 'upstream', progress: true)
        end
      end

      context 'when :no_progress is true' do
        it 'includes --no-progress flag' do
          expect_command_capturing('remote', 'rename', '--no-progress', '--', 'origin',
                                   'upstream').and_return(command_result)

          command.call('origin', 'upstream', no_progress: true)
        end
      end
    end

    context 'input validation' do
      it 'raises ArgumentError for unsupported options' do
        expect { command.call('origin', 'upstream', verbose: true) }.to raise_error(ArgumentError, /unsupported/i)
      end
    end
  end
end
