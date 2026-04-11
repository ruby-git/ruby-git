# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/branch/show_current'

RSpec.describe Git::Commands::Branch::ShowCurrent do
  # Duck-type collaborator: command specs depend on the #command_capturing interface,
  # not a single concrete ExecutionContext class.
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with no arguments' do
      it 'runs branch --show-current' do
        expected_result = command_result("main\n")
        expect_command_capturing('branch', '--show-current')
          .and_return(expected_result)

        result = command.call

        expect(result).to eq(expected_result)
      end
    end
  end
end
