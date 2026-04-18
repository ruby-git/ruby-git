# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/write_tree'

RSpec.describe Git::Commands::WriteTree do
  # Duck-type collaborator: command specs depend on the #command_capturing
  # interface, not a single concrete ExecutionContext class.
  let(:execution_context) { execution_context_double }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with no options' do
      it 'runs git write-tree with no extra arguments' do
        expected_result = command_result
        expect_command_capturing('write-tree').and_return(expected_result)

        result = command.call

        expect(result).to eq(expected_result)
      end
    end

    context 'with the :missing_ok option' do
      it 'adds --missing-ok when true' do
        expect_command_capturing('write-tree', '--missing-ok').and_return(command_result)

        command.call(missing_ok: true)
      end
    end

    context 'with the :prefix option' do
      it 'adds --prefix=<value> inline' do
        expect_command_capturing('write-tree', '--prefix=lib/').and_return(command_result)

        command.call(prefix: 'lib/')
      end
    end

    context 'with multiple options combined' do
      it 'combines --missing-ok and --prefix options' do
        expect_command_capturing('write-tree', '--missing-ok', '--prefix=sub/').and_return(command_result)

        command.call(missing_ok: true, prefix: 'sub/')
      end
    end

    context 'input validation' do
      it 'raises ArgumentError for unsupported options' do
        expect { command.call(unknown: true) }
          .to raise_error(ArgumentError, /Unsupported options/)
      end
    end
  end
end
