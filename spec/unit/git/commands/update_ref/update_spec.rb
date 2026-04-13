# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/update_ref/update'

RSpec.describe Git::Commands::UpdateRef::Update do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with ref and newvalue' do
      it 'runs git update-ref with the ref and newvalue as positional arguments' do
        expected_result = command_result
        expect_command_capturing('update-ref', '--', 'refs/heads/main', 'abc1234')
          .and_return(expected_result)

        result = command.call('refs/heads/main', 'abc1234')

        expect(result).to eq(expected_result)
      end
    end

    context 'with ref, newvalue, and oldvalue' do
      it 'includes all three positional arguments' do
        expect_command_capturing('update-ref', '--', 'refs/heads/main', 'newsha', 'oldsha')
          .and_return(command_result)

        command.call('refs/heads/main', 'newsha', 'oldsha')
      end
    end

    context 'with the :m option' do
      it 'adds -m <reason> to the command line' do
        expect_command_capturing('update-ref', '-m', 'reset to upstream', '--', 'refs/heads/main', 'abc1234')
          .and_return(command_result)

        command.call('refs/heads/main', 'abc1234', m: 'reset to upstream')
      end
    end

    context 'with the :no_deref option' do
      it 'adds --no-deref to the command line' do
        expect_command_capturing('update-ref', '--no-deref', '--', 'refs/heads/main', 'abc1234')
          .and_return(command_result)

        command.call('refs/heads/main', 'abc1234', no_deref: true)
      end
    end

    context 'with the :create_reflog option' do
      it 'adds --create-reflog to the command line' do
        expect_command_capturing('update-ref', '--create-reflog', '--', 'refs/heads/main', 'abc1234')
          .and_return(command_result)

        command.call('refs/heads/main', 'abc1234', create_reflog: true)
      end
    end

    context 'with the :timeout execution option' do
      it 'passes timeout to the execution context' do
        expect_command_capturing('update-ref', '--', 'refs/heads/main', 'abc1234', timeout: 5)
          .and_return(command_result)

        command.call('refs/heads/main', 'abc1234', timeout: 5)
      end
    end

    context 'with multiple options combined' do
      it 'includes all specified options in definition order' do
        expect_command_capturing(
          'update-ref',
          '-m', 'migration',
          '--no-deref',
          '--create-reflog',
          '--', 'refs/heads/main', 'newsha', 'oldsha'
        ).and_return(command_result)

        command.call('refs/heads/main', 'newsha', 'oldsha', m: 'migration', no_deref: true, create_reflog: true)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError for unsupported options' do
        expect { command.call('refs/heads/main', 'abc1234', unknown: true) }
          .to raise_error(ArgumentError, /Unsupported options/)
      end

      it 'raises ArgumentError when ref operand is missing' do
        expect { command.call }
          .to raise_error(ArgumentError, /ref is required/)
      end

      it 'raises ArgumentError when newvalue operand is missing' do
        expect { command.call('refs/heads/main') }
          .to raise_error(ArgumentError, /newvalue is required/)
      end
    end
  end
end
