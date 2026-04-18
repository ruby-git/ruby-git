# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/symbolic_ref/update'

RSpec.describe Git::Commands::SymbolicRef::Update do
  let(:execution_context) { execution_context_double }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with name and ref operands' do
      it 'runs git symbolic-ref with both positional arguments' do
        expected_result = command_result
        expect_command_capturing('symbolic-ref', '--', 'HEAD', 'refs/heads/main')
          .and_return(expected_result)

        result = command.call('HEAD', 'refs/heads/main')

        expect(result).to eq(expected_result)
      end
    end

    context 'with the :m option' do
      it 'adds -m <reason> to the command line' do
        expect_command_capturing('symbolic-ref', '-m', 'switching to main', '--', 'HEAD', 'refs/heads/main')
          .and_return(command_result)

        command.call('HEAD', 'refs/heads/main', m: 'switching to main')
      end
    end

    context 'input validation' do
      it 'raises ArgumentError for unsupported options' do
        expect { command.call('HEAD', 'refs/heads/main', unknown: true) }
          .to raise_error(ArgumentError, /Unsupported options/)
      end

      it 'raises ArgumentError when the name operand is missing' do
        expect { command.call }
          .to raise_error(ArgumentError, /name is required/)
      end

      it 'raises ArgumentError when the ref operand is missing' do
        expect { command.call('HEAD') }
          .to raise_error(ArgumentError, /ref is required/)
      end
    end
  end
end
