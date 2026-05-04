# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/maintenance/register'

RSpec.describe Git::Commands::Maintenance::Register do
  let(:execution_context) { execution_context_double }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with no arguments' do
      it 'runs git maintenance register' do
        expected_result = command_result('')
        expect_command_capturing('maintenance', 'register').and_return(expected_result)

        result = command.call

        expect(result).to eq(expected_result)
      end
    end

    context 'with :config_file option as a path' do
      it 'passes --config-file with the given path' do
        expect_command_capturing('maintenance', 'register', '--config-file', '/path/to/config')
          .and_return(command_result(''))

        command.call(config_file: '/path/to/config')
      end
    end

    context 'with :config_file option as true' do
      it 'includes the --config-file flag' do
        expect_command_capturing('maintenance', 'register', '--config-file')
          .and_return(command_result(''))

        command.call(config_file: true)
      end
    end

    context 'with :config_file option' do
      context 'when :no_config_file is true' do
        it 'includes the --no-config-file flag' do
          expect_command_capturing('maintenance', 'register', '--no-config-file')
            .and_return(command_result(''))

          command.call(no_config_file: true)
        end
      end
    end

    context 'with :env execution option' do
      it 'forwards env: to the execution context' do
        expect_command_capturing('maintenance', 'register', env: { 'GIT_CONFIG_GLOBAL' => '/tmp/config' })
          .and_return(command_result(''))

        command.call(env: { 'GIT_CONFIG_GLOBAL' => '/tmp/config' })
      end
    end

    context 'input validation' do
      it 'raises ArgumentError for unknown options' do
        expect { command.call(unknown: true) }.to raise_error(ArgumentError, /unknown/)
      end
    end
  end
end
