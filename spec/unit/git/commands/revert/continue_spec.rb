# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/revert/continue'

RSpec.describe Git::Commands::Revert::Continue do
  # Duck-type collaborator: command specs depend on the #command_capturing interface,
  # not a single concrete ExecutionContext class.
  let(:execution_context) { execution_context_double }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    it 'calls git revert --continue' do
      expected_result = command_result('')
      expect_command_capturing('revert', '--continue').and_return(expected_result)

      result = command.call

      expect(result).to eq(expected_result)
    end

    context 'with edit: true' do
      it 'includes --edit' do
        expect_command_capturing('revert', '--continue', '--edit').and_return(command_result(''))
        command.call(edit: true)
      end
    end

    context 'when :no_edit is true' do
      it 'includes --no-edit' do
        expect_command_capturing('revert', '--continue', '--no-edit').and_return(command_result(''))
        command.call(no_edit: true)
      end
    end

    context 'with e: true (alias for :edit)' do
      it 'includes --edit' do
        expect_command_capturing('revert', '--continue', '--edit').and_return(command_result(''))
        command.call(e: true)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError for unsupported options' do
        expect { command.call(invalid: true) }
          .to raise_error(ArgumentError, /Unsupported options/)
      end
    end
  end
end
