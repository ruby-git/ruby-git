# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/config_option_syntax/get_color_bool'

RSpec.describe Git::Commands::ConfigOptionSyntax::GetColorBool do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with a name argument' do
      it 'runs git config --get-colorbool with the name' do
        expected_result = command_result
        expect_command_capturing('config', '--get-colorbool', '--', 'color.diff').and_return(expected_result)

        result = command.call('color.diff')

        expect(result).to eq(expected_result)
      end
    end

    context 'with a name and stdout_is_tty' do
      it 'adds the stdout_is_tty after the name' do
        expect_command_capturing('config', '--get-colorbool', '--', 'color.diff', 'true').and_return(command_result)

        command.call('color.diff', 'true')
      end
    end

    context 'with the :global option' do
      it 'adds --global to the command line' do
        expect_command_capturing('config', '--get-colorbool', '--global', '--', 'color.diff').and_return(command_result)

        command.call('color.diff', global: true)
      end
    end

    context 'with the :system option' do
      it 'adds --system to the command line' do
        expect_command_capturing('config', '--get-colorbool', '--system', '--', 'color.diff').and_return(command_result)

        command.call('color.diff', system: true)
      end
    end

    context 'with the :local option' do
      it 'adds --local to the command line' do
        expect_command_capturing('config', '--get-colorbool', '--local', '--', 'color.diff').and_return(command_result)

        command.call('color.diff', local: true)
      end
    end

    context 'with the :worktree option' do
      it 'adds --worktree to the command line' do
        expect_command_capturing('config', '--get-colorbool', '--worktree', '--',
                                 'color.diff').and_return(command_result)

        command.call('color.diff', worktree: true)
      end
    end

    context 'with the :file option' do
      it 'adds --file with the path' do
        expect_command_capturing('config', '--get-colorbool', '--file', '/path/to/config', '--',
                                 'color.diff').and_return(command_result)

        command.call('color.diff', file: '/path/to/config')
      end

      it 'supports the :f alias' do
        expect_command_capturing('config', '--get-colorbool', '--file', '/path/to/config', '--',
                                 'color.diff').and_return(command_result)

        command.call('color.diff', f: '/path/to/config')
      end
    end

    context 'with the :blob option' do
      it 'adds --blob with the value' do
        expect_command_capturing('config', '--get-colorbool', '--blob', 'HEAD:.gitmodules', '--',
                                 'color.diff').and_return(command_result)

        command.call('color.diff', blob: 'HEAD:.gitmodules')
      end
    end

    context 'with the :includes option' do
      it 'adds --includes to the command line' do
        expect_command_capturing('config', '--get-colorbool', '--includes', '--',
                                 'color.diff').and_return(command_result)

        command.call('color.diff', includes: true)
      end

      it 'adds --no-includes to the command line' do
        expect_command_capturing('config', '--get-colorbool', '--no-includes', '--',
                                 'color.diff').and_return(command_result)

        command.call('color.diff', includes: false)
      end
    end

    context 'exit code handling' do
      it 'returns result for exit code 0' do
        result = command_result(exitstatus: 0)
        expect_command_capturing('config', '--get-colorbool', '--', 'color.diff').and_return(result)

        expect(command.call('color.diff')).to eq(result)
      end

      it 'returns result for exit code 1 (color=no)' do
        result = command_result(exitstatus: 1)
        expect_command_capturing('config', '--get-colorbool', '--', 'color.diff').and_return(result)

        expect(command.call('color.diff')).to eq(result)
      end

      it 'raises FailedError for exit code 2' do
        result = command_result(stderr: 'fatal: bad config', exitstatus: 2)
        expect_command_capturing('config', '--get-colorbool', '--', 'color.diff').and_return(result)

        expect { command.call('color.diff') }.to raise_error(Git::FailedError, /fatal: bad config/)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError when name is missing' do
        expect { command.call }.to raise_error(ArgumentError, /name/)
      end

      it 'raises ArgumentError for unsupported options' do
        expect { command.call('color.diff', unknown: true) }.to raise_error(ArgumentError, /Unsupported options/)
      end
    end
  end
end
