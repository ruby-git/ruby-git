# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/config_option_syntax/list'

RSpec.describe Git::Commands::ConfigOptionSyntax::List do
  # Duck-type collaborator: command specs depend on the #command_capturing interface,
  # not a single concrete ExecutionContext class.
  let(:execution_context) { execution_context_double }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with no arguments' do
      it 'runs git config --list' do
        expected_result = command_result
        expect_command_capturing('config', '--list').and_return(expected_result)

        result = command.call

        expect(result).to eq(expected_result)
      end
    end

    context 'with the :global option' do
      it 'adds --global to the command line' do
        expect_command_capturing('config', '--list', '--global').and_return(command_result)

        command.call(global: true)
      end
    end

    context 'with the :system option' do
      it 'adds --system to the command line' do
        expect_command_capturing('config', '--list', '--system').and_return(command_result)

        command.call(system: true)
      end
    end

    context 'with the :local option' do
      it 'adds --local to the command line' do
        expect_command_capturing('config', '--list', '--local').and_return(command_result)

        command.call(local: true)
      end
    end

    context 'with the :worktree option' do
      it 'adds --worktree to the command line' do
        expect_command_capturing('config', '--list', '--worktree').and_return(command_result)

        command.call(worktree: true)
      end
    end

    context 'with the :file option' do
      it 'adds --file with the path' do
        expect_command_capturing('config', '--list', '--file', '/path/to/config').and_return(command_result)

        command.call(file: '/path/to/config')
      end

      it 'supports the :f alias' do
        expect_command_capturing('config', '--list', '--file', '/path/to/config').and_return(command_result)

        command.call(f: '/path/to/config')
      end
    end

    context 'with the :blob option' do
      it 'adds --blob with the value' do
        expect_command_capturing('config', '--list', '--blob', 'HEAD:.gitmodules').and_return(command_result)

        command.call(blob: 'HEAD:.gitmodules')
      end
    end

    context 'with the :type option' do
      it 'adds --type=<value> inline' do
        expect_command_capturing('config', '--list', '--type=bool').and_return(command_result)

        command.call(type: 'bool')
      end
    end

    context 'with the :includes option' do
      it 'adds --includes when true' do
        expect_command_capturing('config', '--list', '--includes').and_return(command_result)

        command.call(includes: true)
      end

      it 'adds --no-includes when false' do
        expect_command_capturing('config', '--list', '--no-includes').and_return(command_result)

        command.call(includes: false)
      end
    end

    context 'with the :show_origin option' do
      it 'adds --show-origin to the command line' do
        expect_command_capturing('config', '--list', '--show-origin').and_return(command_result)

        command.call(show_origin: true)
      end
    end

    context 'with the :show_scope option' do
      it 'adds --show-scope to the command line' do
        expect_command_capturing('config', '--list', '--show-scope').and_return(command_result)

        command.call(show_scope: true)
      end
    end

    context 'with the :null option' do
      it 'adds --null to the command line' do
        expect_command_capturing('config', '--list', '--null').and_return(command_result)

        command.call(null: true)
      end

      it 'supports the :z alias' do
        expect_command_capturing('config', '--list', '--null').and_return(command_result)

        command.call(z: true)
      end
    end

    context 'with the :name_only option' do
      it 'adds --name-only to the command line' do
        expect_command_capturing('config', '--list', '--name-only').and_return(command_result)

        command.call(name_only: true)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError for unsupported options' do
        expect { command.call(unknown: true) }.to raise_error(ArgumentError, /Unsupported options/)
      end
    end
  end
end
