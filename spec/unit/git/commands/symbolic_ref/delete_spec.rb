# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/symbolic_ref/delete'

RSpec.describe Git::Commands::SymbolicRef::Delete do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with a name operand' do
      it 'runs git symbolic-ref --delete with the name' do
        expected_result = command_result
        expect_command_capturing('symbolic-ref', '--delete', '--', 'HEAD')
          .and_return(expected_result)

        result = command.call('HEAD')

        expect(result).to eq(expected_result)
      end
    end

    context 'with the :quiet option' do
      it 'adds --quiet to the command line' do
        expect_command_capturing('symbolic-ref', '--delete', '--quiet', '--', 'HEAD')
          .and_return(command_result)

        command.call('HEAD', quiet: true)
      end
    end

    context 'with the :q alias' do
      it 'adds --quiet to the command line' do
        expect_command_capturing('symbolic-ref', '--delete', '--quiet', '--', 'HEAD')
          .and_return(command_result)

        command.call('HEAD', q: true)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError for unsupported options' do
        expect { command.call('HEAD', unknown: true) }
          .to raise_error(ArgumentError, /Unsupported options/)
      end

      it 'raises ArgumentError when the name operand is missing' do
        expect { command.call }
          .to raise_error(ArgumentError, /name is required/)
      end
    end
  end
end
