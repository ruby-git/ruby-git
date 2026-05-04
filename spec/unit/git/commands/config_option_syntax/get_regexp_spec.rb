# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/config_option_syntax/get_regexp'

RSpec.describe Git::Commands::ConfigOptionSyntax::GetRegexp do
  let(:execution_context) { execution_context_double }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with a name_regex argument' do
      it 'runs git config --get-regexp with the name regex' do
        expected_result = command_result
        expect_command_capturing('config', '--get-regexp', '--', 'remote\..*\.url').and_return(expected_result)

        result = command.call('remote\..*\.url')

        expect(result).to eq(expected_result)
      end
    end

    context 'with a name_regex and value_regex' do
      it 'adds the value_regex after the name regex' do
        expect_command_capturing('config', '--get-regexp', '--', 'remote\..*\.url', 'github').and_return(command_result)

        command.call('remote\..*\.url', 'github')
      end
    end

    context 'with the :global option' do
      it 'adds --global to the command line' do
        expect_command_capturing('config', '--get-regexp', '--global', '--', 'user\..*').and_return(command_result)

        command.call('user\..*', global: true)
      end
    end

    context 'with the :system option' do
      it 'adds --system to the command line' do
        expect_command_capturing('config', '--get-regexp', '--system', '--', 'user\..*').and_return(command_result)

        command.call('user\..*', system: true)
      end
    end

    context 'with the :local option' do
      it 'adds --local to the command line' do
        expect_command_capturing('config', '--get-regexp', '--local', '--', 'user\..*').and_return(command_result)

        command.call('user\..*', local: true)
      end
    end

    context 'with the :worktree option' do
      it 'adds --worktree to the command line' do
        expect_command_capturing('config', '--get-regexp', '--worktree', '--', 'user\..*').and_return(command_result)

        command.call('user\..*', worktree: true)
      end
    end

    context 'with the :file option' do
      it 'adds --file with the path' do
        expect_command_capturing('config', '--get-regexp', '--file', '/path/to/config', '--',
                                 'user\..*').and_return(command_result)

        command.call('user\..*', file: '/path/to/config')
      end

      it 'supports the :f alias' do
        expect_command_capturing('config', '--get-regexp', '--file', '/path/to/config', '--',
                                 'user\..*').and_return(command_result)

        command.call('user\..*', f: '/path/to/config')
      end
    end

    context 'with the :blob option' do
      it 'adds --blob with the value' do
        expect_command_capturing('config', '--get-regexp', '--blob', 'HEAD:.gitmodules', '--',
                                 'user\..*').and_return(command_result)

        command.call('user\..*', blob: 'HEAD:.gitmodules')
      end
    end

    context 'with the :includes option' do
      context 'when true' do
        it 'adds --includes flag' do
          expect_command_capturing('config', '--get-regexp', '--includes', '--', 'user\..*').and_return(command_result)

          command.call('user\..*', includes: true)
        end
      end

      context 'when :no_includes is true' do
        it 'adds --no-includes flag' do
          expect_command_capturing(
            'config', '--get-regexp', '--no-includes', '--', 'user\..*'
          ).and_return(command_result)

          command.call('user\..*', no_includes: true)
        end
      end
    end

    context 'with the :type option' do
      it 'adds --type=<value> inline' do
        expect_command_capturing('config', '--get-regexp', '--type=bool', '--', 'core\..*').and_return(command_result)

        command.call('core\..*', type: 'bool')
      end
    end

    context 'with the :show_origin option' do
      it 'adds --show-origin to the command line' do
        expect_command_capturing('config', '--get-regexp', '--show-origin', '--', 'user\..*').and_return(command_result)

        command.call('user\..*', show_origin: true)
      end
    end

    context 'with the :show_scope option' do
      it 'adds --show-scope to the command line' do
        expect_command_capturing('config', '--get-regexp', '--show-scope', '--', 'user\..*').and_return(command_result)

        command.call('user\..*', show_scope: true)
      end
    end

    context 'with the :null option' do
      it 'adds --null to the command line' do
        expect_command_capturing('config', '--get-regexp', '--null', '--', 'user\..*').and_return(command_result)

        command.call('user\..*', null: true)
      end

      it 'supports the :z alias' do
        expect_command_capturing('config', '--get-regexp', '--null', '--', 'user\..*').and_return(command_result)

        command.call('user\..*', z: true)
      end
    end

    context 'with the :name_only option' do
      it 'adds --name-only to the command line' do
        expect_command_capturing('config', '--get-regexp', '--name-only', '--', 'user\..*').and_return(command_result)

        command.call('user\..*', name_only: true)
      end
    end

    context 'exit code handling' do
      it 'returns the result for exit code 0' do
        result = command_result(exitstatus: 0)
        expect_command_capturing('config', '--get-regexp', '--', 'user\..*').and_return(result)

        expect { command.call('user\..*') }.not_to raise_error
      end

      it 'returns the result for exit code 1 (no match found)' do
        result = command_result(exitstatus: 1)
        expect_command_capturing('config', '--get-regexp', '--', 'nonexistent\..*').and_return(result)

        expect { command.call('nonexistent\..*') }.not_to raise_error
      end

      it 'raises FailedError for exit code 2 (error)' do
        result = command_result(stderr: 'fatal: bad config', exitstatus: 2)
        expect_command_capturing('config', '--get-regexp', '--', 'user\..*').and_return(result)

        expect { command.call('user\..*') }.to raise_error(Git::FailedError, /fatal: bad config/)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError when name_regex is missing' do
        expect { command.call }.to raise_error(ArgumentError, /name_regex/)
      end

      it 'raises ArgumentError for unsupported options' do
        expect { command.call('user\..*', unknown: true) }.to raise_error(ArgumentError, /Unsupported options/)
      end
    end
  end
end
