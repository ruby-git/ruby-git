# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/config_option_syntax/get_all'

RSpec.describe Git::Commands::ConfigOptionSyntax::GetAll do
  let(:execution_context) { execution_context_double }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with a name argument' do
      it 'runs git config --get-all with the name' do
        expected_result = command_result
        expect_command_capturing('config', '--get-all', '--', 'remote.origin.fetch').and_return(expected_result)

        result = command.call('remote.origin.fetch')
        expect(result).to eq(expected_result)
      end
    end

    context 'with a name and value_regex' do
      it 'adds the value_regex after the name' do
        expect_command_capturing('config', '--get-all', '--', 'remote.origin.fetch',
                                 '\\+refs/heads/.*').and_return(command_result)

        command.call('remote.origin.fetch', '\\+refs/heads/.*')
      end
    end

    context 'with the :global option' do
      it 'adds --global to the command line' do
        expect_command_capturing('config', '--get-all', '--global', '--', 'user.name').and_return(command_result)

        command.call('user.name', global: true)
      end
    end

    context 'with the :system option' do
      it 'adds --system to the command line' do
        expect_command_capturing('config', '--get-all', '--system', '--', 'user.name').and_return(command_result)

        command.call('user.name', system: true)
      end
    end

    context 'with the :local option' do
      it 'adds --local to the command line' do
        expect_command_capturing('config', '--get-all', '--local', '--', 'user.name').and_return(command_result)

        command.call('user.name', local: true)
      end
    end

    context 'with the :worktree option' do
      it 'adds --worktree to the command line' do
        expect_command_capturing('config', '--get-all', '--worktree', '--', 'user.name').and_return(command_result)

        command.call('user.name', worktree: true)
      end
    end

    context 'with the :file option' do
      it 'adds --file with the path' do
        expect_command_capturing('config', '--get-all', '--file', '/path/to/config', '--',
                                 'user.name').and_return(command_result)

        command.call('user.name', file: '/path/to/config')
      end

      it 'supports the :f alias' do
        expect_command_capturing('config', '--get-all', '--file', '/path/to/config', '--',
                                 'user.name').and_return(command_result)

        command.call('user.name', f: '/path/to/config')
      end
    end

    context 'with the :blob option' do
      it 'adds --blob with the value' do
        expect_command_capturing('config', '--get-all', '--blob', 'HEAD:.gitmodules', '--',
                                 'user.name').and_return(command_result)

        command.call('user.name', blob: 'HEAD:.gitmodules')
      end
    end

    context 'with the :includes option' do
      context 'when true' do
        it 'adds --includes to the command line' do
          expect_command_capturing('config', '--get-all', '--includes', '--', 'user.name').and_return(command_result)

          command.call('user.name', includes: true)
        end
      end

      context 'when :no_includes is true' do
        it 'adds --no-includes to the command line' do
          expect_command_capturing('config', '--get-all', '--no-includes', '--', 'user.name').and_return(command_result)

          command.call('user.name', no_includes: true)
        end
      end
    end

    context 'with the :type option' do
      it 'adds --type=<value> inline' do
        expect_command_capturing('config', '--get-all', '--type=bool', '--', 'core.bare').and_return(command_result)

        command.call('core.bare', type: 'bool')
      end
    end

    context 'with the :no_type option' do
      it 'adds --no-type to the command line' do
        expect_command_capturing('config', '--get-all', '--no-type', '--', 'core.bare').and_return(command_result)

        command.call('core.bare', no_type: true)
      end
    end

    context 'with the :show_origin option' do
      it 'adds --show-origin to the command line' do
        expect_command_capturing('config', '--get-all', '--show-origin', '--', 'user.name').and_return(command_result)

        command.call('user.name', show_origin: true)
      end
    end

    context 'with the :show_scope option' do
      it 'adds --show-scope to the command line' do
        expect_command_capturing('config', '--get-all', '--show-scope', '--', 'user.name').and_return(command_result)

        command.call('user.name', show_scope: true)
      end
    end

    context 'with the :null option' do
      it 'adds --null to the command line' do
        expect_command_capturing('config', '--get-all', '--null', '--', 'user.name').and_return(command_result)

        command.call('user.name', null: true)
      end

      it 'supports the :z alias' do
        expect_command_capturing('config', '--get-all', '--null', '--', 'user.name').and_return(command_result)

        command.call('user.name', z: true)
      end
    end

    context 'exit code handling' do
      it 'returns result for exit code 0 (key found)' do
        expect_command_capturing('config', '--get-all', '--', 'user.name')
          .and_return(command_result('Alice', exitstatus: 0))

        result = command.call('user.name')
        expect(result.status.exitstatus).to eq(0)
      end

      it 'returns result for exit code 1 (key not found)' do
        expect_command_capturing('config', '--get-all', '--', 'nonexistent.key')
          .and_return(command_result('', exitstatus: 1))

        result = command.call('nonexistent.key')
        expect(result.status.exitstatus).to eq(1)
      end

      it 'raises FailedError when git exits with code 2' do
        expect_command_capturing('config', '--get-all', '--', 'user.name')
          .and_return(command_result('', stderr: 'error: bad config', exitstatus: 2))

        expect { command.call('user.name') }.to raise_error(Git::FailedError, /bad config/)
      end

      it 'raises FailedError when git exits with code 128' do
        expect_command_capturing('config', '--get-all', '--', 'user.name')
          .and_return(command_result('', stderr: 'fatal: not a git repository', exitstatus: 128))

        expect { command.call('user.name') }.to raise_error(Git::FailedError, /not a git repository/)
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
