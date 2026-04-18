# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/config_option_syntax/add'

RSpec.describe Git::Commands::ConfigOptionSyntax::Add do
  # Duck-type collaborator: command specs depend on the #command_capturing interface,
  # not a single concrete ExecutionContext class.
  let(:execution_context) { execution_context_double }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with name and value arguments' do
      it 'runs git config --add with name and value' do
        expected_result = command_result
        expect_command_capturing('config', '--add', '--', 'remote.origin.fetch',
                                 '+refs/heads/*:refs/remotes/origin/*').and_return(expected_result)

        result = command.call('remote.origin.fetch', '+refs/heads/*:refs/remotes/origin/*')
        expect(result).to eq(expected_result)
      end
    end

    context 'with the :global option' do
      it 'adds --global to the command line' do
        expect_command_capturing('config', '--add', '--global', '--', 'user.name', 'Alice').and_return(command_result)

        command.call('user.name', 'Alice', global: true)
      end
    end

    context 'with the :system option' do
      it 'adds --system to the command line' do
        expect_command_capturing('config', '--add', '--system', '--', 'user.name', 'Alice').and_return(command_result)

        command.call('user.name', 'Alice', system: true)
      end
    end

    context 'with the :local option' do
      it 'adds --local to the command line' do
        expect_command_capturing('config', '--add', '--local', '--', 'user.name', 'Alice').and_return(command_result)

        command.call('user.name', 'Alice', local: true)
      end
    end

    context 'with the :worktree option' do
      it 'adds --worktree to the command line' do
        expect_command_capturing('config', '--add', '--worktree', '--', 'user.name', 'Alice').and_return(command_result)

        command.call('user.name', 'Alice', worktree: true)
      end
    end

    context 'with the :file option' do
      it 'adds --file with the path' do
        expect_command_capturing('config', '--add', '--file', '/path/to/config', '--', 'user.name',
                                 'Alice').and_return(command_result)

        command.call('user.name', 'Alice', file: '/path/to/config')
      end

      it 'supports the :f alias' do
        expect_command_capturing('config', '--add', '--file', '/path/to/config', '--', 'user.name',
                                 'Alice').and_return(command_result)

        command.call('user.name', 'Alice', f: '/path/to/config')
      end
    end

    context 'with the :blob option' do
      it 'adds --blob with the value' do
        expect_command_capturing('config', '--add', '--blob', 'HEAD:.gitmodules', '--', 'user.name',
                                 'Alice').and_return(command_result)

        command.call('user.name', 'Alice', blob: 'HEAD:.gitmodules')
      end
    end

    context 'with the :type option' do
      it 'adds --type=<value> inline' do
        expect_command_capturing('config', '--add', '--type=int', '--', 'core.bigFileThreshold',
                                 '512m').and_return(command_result)

        command.call('core.bigFileThreshold', '512m', type: 'int')
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
