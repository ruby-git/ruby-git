# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/config_option_syntax/set'

RSpec.describe Git::Commands::ConfigOptionSyntax::Set do
  let(:execution_context) { execution_context_double }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with name and value arguments' do
      it 'runs git config with name and value' do
        expected_result = command_result
        expect_command_capturing('config', '--', 'user.name', 'Alice').and_return(expected_result)

        result = command.call('user.name', 'Alice')

        expect(result).to eq(expected_result)
      end
    end

    context 'with name, value, and value_regex' do
      it 'adds the value_regex after the value' do
        expect_command_capturing('config', '--', 'user.name', 'Alice', 'Bob').and_return(command_result)

        command.call('user.name', 'Alice', 'Bob')
      end
    end

    context 'with the :global option' do
      it 'adds --global to the command line' do
        expect_command_capturing('config', '--global', '--', 'user.name', 'Alice').and_return(command_result)

        command.call('user.name', 'Alice', global: true)
      end
    end

    context 'with the :system option' do
      it 'adds --system to the command line' do
        expect_command_capturing('config', '--system', '--', 'user.name', 'Alice').and_return(command_result)

        command.call('user.name', 'Alice', system: true)
      end
    end

    context 'with the :local option' do
      it 'adds --local to the command line' do
        expect_command_capturing('config', '--local', '--', 'user.name', 'Alice').and_return(command_result)

        command.call('user.name', 'Alice', local: true)
      end
    end

    context 'with the :worktree option' do
      it 'adds --worktree to the command line' do
        expect_command_capturing('config', '--worktree', '--', 'user.name', 'Alice').and_return(command_result)

        command.call('user.name', 'Alice', worktree: true)
      end
    end

    context 'with the :file option' do
      it 'adds --file with the path' do
        expect_command_capturing('config', '--file', '/path/to/config', '--', 'user.name',
                                 'Alice').and_return(command_result)

        command.call('user.name', 'Alice', file: '/path/to/config')
      end

      it 'supports the :f alias' do
        expect_command_capturing('config', '--file', '/path/to/config', '--', 'user.name',
                                 'Alice').and_return(command_result)

        command.call('user.name', 'Alice', f: '/path/to/config')
      end
    end

    context 'with the :blob option' do
      it 'adds --blob with the value' do
        expect_command_capturing('config', '--blob', 'HEAD:.gitmodules', '--', 'user.name',
                                 'Alice').and_return(command_result)

        command.call('user.name', 'Alice', blob: 'HEAD:.gitmodules')
      end
    end

    context 'with the :replace_all option' do
      it 'adds --replace-all to the command line' do
        expect_command_capturing('config', '--replace-all', '--', 'user.name', 'Alice').and_return(command_result)

        command.call('user.name', 'Alice', replace_all: true)
      end
    end

    context 'with the :append option' do
      it 'adds --append to the command line' do
        expect_command_capturing('config', '--append', '--', 'user.name', 'Alice').and_return(command_result)

        command.call('user.name', 'Alice', append: true)
      end
    end

    context 'with the :comment option' do
      it 'adds --comment with the message' do
        expect_command_capturing('config', '--comment', 'added by script', '--', 'user.name',
                                 'Alice').and_return(command_result)

        command.call('user.name', 'Alice', comment: 'added by script')
      end
    end

    context 'with the :type option' do
      it 'adds --type=<value> inline' do
        expect_command_capturing('config', '--type=bool', '--', 'core.bare', 'true').and_return(command_result)

        command.call('core.bare', 'true', type: 'bool')
      end
    end

    context 'with the :fixed_value option' do
      it 'adds --fixed-value to the command line' do
        expect_command_capturing('config', '--fixed-value', '--', 'core.gitproxy', 'ssh',
                                 'default-proxy').and_return(command_result)

        command.call('core.gitproxy', 'ssh', 'default-proxy', fixed_value: true)
      end
    end

    context 'with the :no_type option' do
      it 'adds --no-type to the command line' do
        expect_command_capturing('config', '--no-type', '--', 'core.bare', 'true').and_return(command_result)

        command.call('core.bare', 'true', no_type: true)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError when name is missing' do
        expect { command.call }.to raise_error(ArgumentError, /name/)
      end

      it 'raises ArgumentError when value is missing' do
        expect { command.call('user.name') }.to raise_error(ArgumentError, /value/)
      end

      it 'raises ArgumentError for unsupported options' do
        expect do
          command.call('user.name', 'Alice', unknown: true)
        end.to raise_error(ArgumentError, /Unsupported options/)
      end
    end
  end
end
