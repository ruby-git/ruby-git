# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/remote/list'

RSpec.describe Git::Commands::Remote::List do
  # Duck-type collaborator: command specs depend on the #command_capturing interface,
  # not a single concrete ExecutionContext class.
  let(:execution_context) { execution_context_double }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with no options' do
      it 'runs git remote' do
        expected_result = command_result("origin\n")
        expect_command_capturing('remote').and_return(expected_result)

        result = command.call

        expect(result).to eq(expected_result)
      end
    end

    context 'with :verbose option' do
      it 'includes the --verbose flag' do
        expect_command_capturing('remote', '--verbose').and_return(command_result)

        command.call(verbose: true)
      end

      it 'accepts :v alias' do
        expect_command_capturing('remote', '--verbose').and_return(command_result)

        command.call(v: true)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError for unsupported options' do
        expect { command.call(prune: true) }.to raise_error(ArgumentError, /unsupported/i)
      end
    end
  end
end
