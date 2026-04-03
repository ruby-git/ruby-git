# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/config_option_syntax/get'

RSpec.describe Git::Commands::ConfigOptionSyntax::Get do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with a name argument' do
      it 'runs git config --get with the name' do
        expected_result = command_result
        expect_command_capturing('config', '--get', '--', 'user.name').and_return(expected_result)

        result = command.call('user.name')
        expect(result).to eq(expected_result)
      end
    end

    context 'with a name and value_regex' do
      it 'adds the value_regex after the name' do
        expect_command_capturing('config', '--get', '--', 'user.name', 'Alice').and_return(command_result)

        command.call('user.name', 'Alice')
      end
    end

    context 'with the :global option' do
      it 'adds --global to the command line' do
        expect_command_capturing('config', '--get', '--global', '--', 'user.name').and_return(command_result)

        command.call('user.name', global: true)
      end
    end

    context 'with the :system option' do
      it 'adds --system to the command line' do
        expect_command_capturing('config', '--get', '--system', '--', 'user.name').and_return(command_result)

        command.call('user.name', system: true)
      end
    end

    context 'with the :local option' do
      it 'adds --local to the command line' do
        expect_command_capturing('config', '--get', '--local', '--', 'user.name').and_return(command_result)

        command.call('user.name', local: true)
      end
    end

    context 'with the :worktree option' do
      it 'adds --worktree to the command line' do
        expect_command_capturing('config', '--get', '--worktree', '--', 'user.name').and_return(command_result)

        command.call('user.name', worktree: true)
      end
    end

    context 'with the :file option' do
      it 'adds --file with the path' do
        expect_command_capturing('config', '--get', '--file', '/path/to/config', '--',
                                 'user.name').and_return(command_result)

        command.call('user.name', file: '/path/to/config')
      end

      it 'supports the :f alias' do
        expect_command_capturing('config', '--get', '--file', '/path/to/config', '--',
                                 'user.name').and_return(command_result)

        command.call('user.name', f: '/path/to/config')
      end
    end

    context 'with the :blob option' do
      it 'adds --blob with the value' do
        expect_command_capturing('config', '--get', '--blob', 'HEAD:.gitmodules', '--',
                                 'user.name').and_return(command_result)

        command.call('user.name', blob: 'HEAD:.gitmodules')
      end
    end

    context 'with the :includes option' do
      it 'adds --includes when true' do
        expect_command_capturing('config', '--get', '--includes', '--', 'user.name').and_return(command_result)

        command.call('user.name', includes: true)
      end

      it 'adds --no-includes when false' do
        expect_command_capturing('config', '--get', '--no-includes', '--', 'user.name').and_return(command_result)

        command.call('user.name', includes: false)
      end
    end

    context 'with the :type option' do
      it 'adds --type=<value> inline' do
        expect_command_capturing('config', '--get', '--type=bool', '--', 'core.bare').and_return(command_result)

        command.call('core.bare', type: 'bool')
      end
    end

    context 'with the :show_origin option' do
      it 'adds --show-origin to the command line' do
        expect_command_capturing('config', '--get', '--show-origin', '--', 'user.name').and_return(command_result)

        command.call('user.name', show_origin: true)
      end
    end

    context 'with the :show_scope option' do
      it 'adds --show-scope to the command line' do
        expect_command_capturing('config', '--get', '--show-scope', '--', 'user.name').and_return(command_result)

        command.call('user.name', show_scope: true)
      end
    end

    context 'with the :null option' do
      it 'adds --null to the command line' do
        expect_command_capturing('config', '--get', '--null', '--', 'user.name').and_return(command_result)

        command.call('user.name', null: true)
      end

      it 'supports the :z alias' do
        expect_command_capturing('config', '--get', '--null', '--', 'user.name').and_return(command_result)

        command.call('user.name', z: true)
      end
    end

    context 'with the :default option' do
      it 'adds --default with the value' do
        expect_command_capturing('config', '--get', '--default', 'fallback', '--',
                                 'user.name').and_return(command_result)

        command.call('user.name', default: 'fallback')
      end
    end

    context 'exit code handling' do
      it 'returns result for exit code 0' do
        result = command_result(exitstatus: 0)
        expect_command_capturing('config', '--get', '--', 'user.name').and_return(result)

        expect(command.call('user.name')).to eq(result)
      end

      it 'returns result for exit code 1 (key not found)' do
        result = command_result(exitstatus: 1)
        expect_command_capturing('config', '--get', '--', 'nonexistent.key').and_return(result)

        expect(command.call('nonexistent.key')).to eq(result)
      end

      it 'raises FailedError for exit code 2' do
        result = command_result(exitstatus: 2)
        expect_command_capturing('config', '--get', '--', 'user.name').and_return(result)

        expect { command.call('user.name') }.to raise_error(Git::FailedError)
      end

      it 'raises FailedError for exit code 128' do
        result = command_result(exitstatus: 128)
        expect_command_capturing('config', '--get', '--', 'user.name').and_return(result)

        expect { command.call('user.name') }.to raise_error(Git::FailedError)
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
