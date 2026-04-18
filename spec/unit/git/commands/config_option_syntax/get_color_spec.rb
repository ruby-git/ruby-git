# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/config_option_syntax/get_color'

RSpec.describe Git::Commands::ConfigOptionSyntax::GetColor do
  let(:execution_context) { execution_context_double }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with a name argument' do
      it 'runs git config --get-color with the name' do
        expected_result = command_result
        expect_command_capturing('config', '--get-color', '--', 'color.diff.new').and_return(expected_result)

        result = command.call('color.diff.new')
        expect(result).to eq(expected_result)
      end
    end

    context 'with a name and default' do
      it 'adds the default after the name' do
        expect_command_capturing('config', '--get-color', '--', 'color.diff.new', 'green').and_return(command_result)

        command.call('color.diff.new', 'green')
      end
    end

    context 'with the :global option' do
      it 'adds --global to the command line' do
        expect_command_capturing('config', '--get-color', '--global', '--', 'color.diff.new').and_return(command_result)

        command.call('color.diff.new', global: true)
      end
    end

    context 'with the :system option' do
      it 'adds --system to the command line' do
        expect_command_capturing('config', '--get-color', '--system', '--', 'color.diff.new').and_return(command_result)

        command.call('color.diff.new', system: true)
      end
    end

    context 'with the :local option' do
      it 'adds --local to the command line' do
        expect_command_capturing('config', '--get-color', '--local', '--', 'color.diff.new').and_return(command_result)

        command.call('color.diff.new', local: true)
      end
    end

    context 'with the :worktree option' do
      it 'adds --worktree to the command line' do
        expect_command_capturing('config', '--get-color', '--worktree', '--',
                                 'color.diff.new').and_return(command_result)

        command.call('color.diff.new', worktree: true)
      end
    end

    context 'with the :file option' do
      it 'adds --file with the path' do
        expect_command_capturing('config', '--get-color', '--file', '/path/to/config', '--',
                                 'color.diff.new').and_return(command_result)

        command.call('color.diff.new', file: '/path/to/config')
      end

      it 'supports the :f alias' do
        expect_command_capturing('config', '--get-color', '--file', '/path/to/config', '--',
                                 'color.diff.new').and_return(command_result)

        command.call('color.diff.new', f: '/path/to/config')
      end
    end

    context 'with the :blob option' do
      it 'adds --blob with the value' do
        expect_command_capturing('config', '--get-color', '--blob', 'HEAD:.gitmodules', '--',
                                 'color.diff.new').and_return(command_result)

        command.call('color.diff.new', blob: 'HEAD:.gitmodules')
      end
    end

    context 'with the :includes option' do
      it 'adds --includes when true' do
        expect_command_capturing('config', '--get-color', '--includes', '--',
                                 'color.diff.new').and_return(command_result)

        command.call('color.diff.new', includes: true)
      end

      it 'adds --no-includes when false' do
        expect_command_capturing('config', '--get-color', '--no-includes', '--',
                                 'color.diff.new').and_return(command_result)

        command.call('color.diff.new', includes: false)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError when name is missing' do
        expect { command.call }.to raise_error(ArgumentError, /name/)
      end

      it 'raises ArgumentError for unsupported options' do
        expect { command.call('color.diff.new', unknown: true) }.to raise_error(ArgumentError, /Unsupported options/)
      end
    end
  end
end
