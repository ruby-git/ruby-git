# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/config_option_syntax/unset'

RSpec.describe Git::Commands::ConfigOptionSyntax::Unset do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with a name argument' do
      it 'runs git config --unset with the name' do
        expected_result = command_result
        expect_command_capturing('config', '--unset', '--', 'user.name').and_return(expected_result)

        result = command.call('user.name')
        expect(result).to eq(expected_result)
      end
    end

    context 'with a name and value_regex' do
      it 'adds the value_regex after the name' do
        expect_command_capturing('config', '--unset', '--', 'user.name', 'Alice').and_return(command_result)

        command.call('user.name', 'Alice')
      end
    end

    context 'with the :global option' do
      it 'adds --global to the command line' do
        expect_command_capturing('config', '--unset', '--global', '--', 'user.name').and_return(command_result)

        command.call('user.name', global: true)
      end
    end

    context 'with the :system option' do
      it 'adds --system to the command line' do
        expect_command_capturing('config', '--unset', '--system', '--', 'user.name').and_return(command_result)

        command.call('user.name', system: true)
      end
    end

    context 'with the :local option' do
      it 'adds --local to the command line' do
        expect_command_capturing('config', '--unset', '--local', '--', 'user.name').and_return(command_result)

        command.call('user.name', local: true)
      end
    end

    context 'with the :worktree option' do
      it 'adds --worktree to the command line' do
        expect_command_capturing('config', '--unset', '--worktree', '--', 'user.name').and_return(command_result)

        command.call('user.name', worktree: true)
      end
    end

    context 'with the :file option' do
      it 'adds --file with the path' do
        expect_command_capturing('config', '--unset', '--file', '/path/to/config', '--',
                                 'user.name').and_return(command_result)

        command.call('user.name', file: '/path/to/config')
      end

      it 'supports the :f alias' do
        expect_command_capturing('config', '--unset', '--file', '/path/to/config', '--',
                                 'user.name').and_return(command_result)

        command.call('user.name', f: '/path/to/config')
      end
    end

    context 'with the :blob option' do
      it 'adds --blob with the value' do
        expect_command_capturing('config', '--unset', '--blob', 'HEAD:.gitmodules', '--',
                                 'user.name').and_return(command_result)

        command.call('user.name', blob: 'HEAD:.gitmodules')
      end
    end

    context 'exit code handling' do
      it 'returns result for exit code 5 (non-existent key)' do
        result = command_result(exitstatus: 5)
        expect_command_capturing('config', '--unset', '--', 'nonexistent.key').and_return(result)

        expect(command.call('nonexistent.key')).to eq(result)
      end

      it 'raises FailedError for exit code 6 (outside allowed range)' do
        result = command_result(exitstatus: 6)
        expect_command_capturing('config', '--unset', '--', 'user.name').and_return(result)

        expect { command.call('user.name') }.to raise_error(Git::FailedError, /git/)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError when name is missing' do
        expect { command.call }.to raise_error(ArgumentError, /name/)
      end

      it 'raises ArgumentError for unsupported options' do
        expect { command.call('user.name', unknown: true) }.to raise_error(ArgumentError, /Unsupported options/)
      end
    end
  end
end
