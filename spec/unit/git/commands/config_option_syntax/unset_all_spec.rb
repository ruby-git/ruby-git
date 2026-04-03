# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/config_option_syntax/unset_all'

RSpec.describe Git::Commands::ConfigOptionSyntax::UnsetAll do
  # Duck-type collaborator: command specs depend on the #command_capturing interface,
  # not a single concrete ExecutionContext class.
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with a name argument' do
      it 'runs git config --unset-all with the name' do
        expected_result = command_result
        expect_command_capturing('config', '--unset-all', '--', 'remote.origin.fetch').and_return(expected_result)

        result = command.call('remote.origin.fetch')

        expect(result).to eq(expected_result)
      end
    end

    context 'with a name and value_regex' do
      it 'adds the value_regex after the name' do
        expect_command_capturing('config', '--unset-all', '--', 'remote.origin.fetch',
                                 '\\+refs/heads/.*').and_return(command_result)

        command.call('remote.origin.fetch', '\\+refs/heads/.*')
      end
    end

    context 'with the :global option' do
      it 'adds --global to the command line' do
        expect_command_capturing('config', '--unset-all', '--global', '--', 'user.name').and_return(command_result)

        command.call('user.name', global: true)
      end
    end

    context 'with the :system option' do
      it 'adds --system to the command line' do
        expect_command_capturing('config', '--unset-all', '--system', '--', 'user.name').and_return(command_result)

        command.call('user.name', system: true)
      end
    end

    context 'with the :local option' do
      it 'adds --local to the command line' do
        expect_command_capturing('config', '--unset-all', '--local', '--', 'user.name').and_return(command_result)

        command.call('user.name', local: true)
      end
    end

    context 'with the :worktree option' do
      it 'adds --worktree to the command line' do
        expect_command_capturing('config', '--unset-all', '--worktree', '--', 'user.name').and_return(command_result)

        command.call('user.name', worktree: true)
      end
    end

    context 'with the :file option' do
      it 'adds --file with the path' do
        expect_command_capturing('config', '--unset-all', '--file', '/path/to/config', '--',
                                 'user.name').and_return(command_result)

        command.call('user.name', file: '/path/to/config')
      end

      it 'supports the :f alias' do
        expect_command_capturing('config', '--unset-all', '--file', '/path/to/config', '--',
                                 'user.name').and_return(command_result)

        command.call('user.name', f: '/path/to/config')
      end
    end

    context 'with the :blob option' do
      it 'adds --blob with the value' do
        expect_command_capturing('config', '--unset-all', '--blob', 'HEAD:.gitmodules', '--',
                                 'user.name').and_return(command_result)

        command.call('user.name', blob: 'HEAD:.gitmodules')
      end
    end

    context 'exit code handling' do
      it 'returns normally on exit status 5 (key not found)' do
        result = command_result(exitstatus: 5)
        expect_command_capturing('config', '--unset-all', '--', 'nonexistent.key').and_return(result)

        expect(command.call('nonexistent.key')).to eq(result)
      end

      it 'raises Git::FailedError on exit status 6' do
        result = command_result(exitstatus: 6)
        expect_command_capturing('config', '--unset-all', '--', 'user.name').and_return(result)

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
