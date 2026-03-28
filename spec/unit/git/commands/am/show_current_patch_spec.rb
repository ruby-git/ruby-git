# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/am/show_current_patch'

RSpec.describe Git::Commands::Am::ShowCurrentPatch do
  # Duck-type collaborator: command specs depend on the #command_capturing interface,
  # not a single concrete ExecutionContext class.
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with no format argument' do
      it 'includes the --show-current-patch flag' do
        expected_result = command_result
        expect_command_capturing('am', '--show-current-patch').and_return(expected_result)

        result = command.call

        expect(result).to eq(expected_result)
      end
    end

    context 'with a format string' do
      it 'includes --show-current-patch=diff' do
        expect_command_capturing('am', '--show-current-patch=diff').and_return(command_result)

        command.call('diff')
      end
    end

    context 'input validation' do
      it 'raises ArgumentError for an unsupported option' do
        expect { command.call(unknown: true) }
          .to raise_error(ArgumentError, /Unsupported options: :unknown/)
      end
    end
  end
end
