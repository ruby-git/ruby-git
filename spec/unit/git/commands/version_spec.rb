# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/version'

RSpec.describe Git::Commands::Version do
  # Duck-type collaborator: command specs depend on the #command_capturing
  # interface, not a single concrete ExecutionContext class.
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with no arguments' do
      it 'runs git version and returns the result' do
        expected_result = command_result('git version 2.42.0')
        expect_command_capturing('version').and_return(expected_result)

        result = command.call

        expect(result).to eq(expected_result)
      end
    end

    context 'with :build_options option' do
      it 'includes the --build-options flag' do
        expect_command_capturing('version', '--build-options').and_return(command_result)
        command.call(build_options: true)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError for unsupported options' do
        expect { command.call(unsupported: true) }
          .to raise_error(ArgumentError, /Unsupported options/)
      end
    end
  end
end
