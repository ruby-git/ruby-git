# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/config_option_syntax/get_urlmatch'

RSpec.describe Git::Commands::ConfigOptionSyntax::GetUrlmatch do
  # Duck-type collaborator: command specs depend on the #command_capturing interface,
  # not a single concrete ExecutionContext class.
  let(:execution_context) { execution_context_double }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with name and url arguments' do
      it 'runs git config --get-urlmatch with name and url' do
        expected_result = command_result
        expect_command_capturing('config', '--get-urlmatch', '--', 'http', 'https://example.com').and_return(expected_result)

        result = command.call('http', 'https://example.com')

        expect(result).to eq(expected_result)
      end
    end

    context 'with the :global option' do
      it 'adds --global to the command line' do
        expect_command_capturing('config', '--get-urlmatch', '--global', '--', 'http', 'https://example.com').and_return(command_result)

        command.call('http', 'https://example.com', global: true)
      end
    end

    context 'with the :system option' do
      it 'adds --system to the command line' do
        expect_command_capturing('config', '--get-urlmatch', '--system', '--', 'http', 'https://example.com').and_return(command_result)

        command.call('http', 'https://example.com', system: true)
      end
    end

    context 'with the :local option' do
      it 'adds --local to the command line' do
        expect_command_capturing('config', '--get-urlmatch', '--local', '--', 'http', 'https://example.com').and_return(command_result)

        command.call('http', 'https://example.com', local: true)
      end
    end

    context 'with the :worktree option' do
      it 'adds --worktree to the command line' do
        expect_command_capturing('config', '--get-urlmatch', '--worktree', '--', 'http', 'https://example.com').and_return(command_result)

        command.call('http', 'https://example.com', worktree: true)
      end
    end

    context 'with the :file option' do
      it 'adds --file with the path' do
        expect_command_capturing('config', '--get-urlmatch', '--file', '/path/to/config', '--', 'http', 'https://example.com').and_return(command_result)

        command.call('http', 'https://example.com', file: '/path/to/config')
      end

      it 'emits --file when called with the :f alias' do
        expect_command_capturing('config', '--get-urlmatch', '--file', '/path/to/config', '--', 'http', 'https://example.com').and_return(command_result)

        command.call('http', 'https://example.com', f: '/path/to/config')
      end
    end

    context 'with the :blob option' do
      it 'adds --blob with the value' do
        expect_command_capturing('config', '--get-urlmatch', '--blob', 'HEAD:.gitmodules', '--', 'http', 'https://example.com').and_return(command_result)

        command.call('http', 'https://example.com', blob: 'HEAD:.gitmodules')
      end
    end

    context 'with the :includes option' do
      it 'adds --includes to the command line' do
        expect_command_capturing('config', '--get-urlmatch', '--includes', '--', 'http', 'https://example.com').and_return(command_result)

        command.call('http', 'https://example.com', includes: true)
      end

      context 'when :no_includes is true' do
        it 'adds --no-includes to the command line' do
          expect_command_capturing('config', '--get-urlmatch', '--no-includes', '--', 'http', 'https://example.com').and_return(command_result)

          command.call('http', 'https://example.com', no_includes: true)
        end
      end
    end

    context 'with the :type option' do
      it 'adds --type=<value> inline' do
        expect_command_capturing('config', '--get-urlmatch', '--type=bool', '--', 'http', 'https://example.com').and_return(command_result)

        command.call('http', 'https://example.com', type: 'bool')
      end
    end

    context 'with the :null option' do
      it 'adds --null to the command line' do
        expect_command_capturing('config', '--get-urlmatch', '--null', '--', 'http', 'https://example.com').and_return(command_result)

        command.call('http', 'https://example.com', null: true)
      end

      it 'emits --null when called with the :z alias' do
        expect_command_capturing('config', '--get-urlmatch', '--null', '--', 'http', 'https://example.com').and_return(command_result)

        command.call('http', 'https://example.com', z: true)
      end
    end

    context 'exit code handling' do
      it 'returns result for exit code 0 (match found)' do
        result = command_result(exitstatus: 0)
        expect_command_capturing('config', '--get-urlmatch', '--', 'http', 'https://example.com').and_return(result)

        expect(command.call('http', 'https://example.com')).to eq(result)
      end

      it 'returns result for exit code 1 (no match found)' do
        result = command_result(exitstatus: 1)
        expect_command_capturing('config', '--get-urlmatch', '--', 'http', 'https://example.com').and_return(result)

        expect(command.call('http', 'https://example.com')).to eq(result)
      end

      it 'raises FailedError for exit code 2' do
        result = command_result(exitstatus: 2)
        expect_command_capturing('config', '--get-urlmatch', '--', 'http', 'https://example.com').and_return(result)

        expect { command.call('http', 'https://example.com') }.to raise_error(Git::FailedError, /git/)
      end

      it 'raises FailedError for exit code 128' do
        result = command_result(exitstatus: 128)
        expect_command_capturing('config', '--get-urlmatch', '--', 'http', 'https://example.com').and_return(result)

        expect { command.call('http', 'https://example.com') }.to raise_error(Git::FailedError, /git/)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError for unsupported options' do
        expect do
          command.call('http', 'https://example.com', unknown: true)
        end.to raise_error(ArgumentError, /Unsupported options/)
      end
    end
  end
end
