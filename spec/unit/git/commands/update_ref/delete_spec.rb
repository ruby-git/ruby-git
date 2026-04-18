# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/update_ref/delete'

RSpec.describe Git::Commands::UpdateRef::Delete do
  let(:execution_context) { execution_context_double }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with only the ref operand' do
      it 'runs git update-ref -d with the ref' do
        expected_result = command_result
        expect_command_capturing('update-ref', '-d', '--', 'refs/heads/old-branch')
          .and_return(expected_result)

        result = command.call('refs/heads/old-branch')

        expect(result).to eq(expected_result)
      end
    end

    context 'with ref and oldvalue' do
      it 'includes both positional arguments' do
        expect_command_capturing('update-ref', '-d', '--', 'refs/heads/old-branch', 'oldsha')
          .and_return(command_result)

        command.call('refs/heads/old-branch', 'oldsha')
      end
    end

    context 'with the :m option' do
      it 'adds -m <reason> to the command line' do
        expect_command_capturing('update-ref', '-m', 'cleanup', '-d', '--', 'refs/heads/old-branch')
          .and_return(command_result)

        command.call('refs/heads/old-branch', m: 'cleanup')
      end
    end

    context 'with the :no_deref option' do
      it 'adds --no-deref to the command line' do
        expect_command_capturing('update-ref', '--no-deref', '-d', '--', 'refs/heads/old-branch')
          .and_return(command_result)

        command.call('refs/heads/old-branch', no_deref: true)
      end
    end

    context 'with multiple options combined' do
      it 'includes all specified options in definition order' do
        expect_command_capturing(
          'update-ref',
          '-m', 'force cleanup',
          '--no-deref',
          '-d',
          '--', 'refs/heads/old-branch', 'oldsha'
        ).and_return(command_result)

        command.call('refs/heads/old-branch', 'oldsha', m: 'force cleanup', no_deref: true)
      end
    end

    context 'with the :timeout execution option' do
      it 'passes timeout to the execution context' do
        expect_command_capturing('update-ref', '-d', '--', 'refs/heads/old-branch', timeout: 5)
          .and_return(command_result)

        command.call('refs/heads/old-branch', timeout: 5)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError for unsupported options' do
        expect { command.call('refs/heads/old-branch', unknown: true) }
          .to raise_error(ArgumentError, /Unsupported options/)
      end

      it 'raises ArgumentError when ref operand is missing' do
        expect { command.call }
          .to raise_error(ArgumentError, /ref is required/)
      end
    end
  end
end
