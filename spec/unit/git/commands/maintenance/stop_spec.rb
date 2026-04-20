# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/maintenance/stop'

RSpec.describe Git::Commands::Maintenance::Stop do
  let(:execution_context) { execution_context_double }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with no arguments' do
      it 'runs git maintenance stop' do
        expected_result = command_result('')
        expect_command_capturing('maintenance', 'stop').and_return(expected_result)

        result = command.call

        expect(result).to eq(expected_result)
      end
    end

    context 'with :env execution option' do
      it 'forwards env: to the execution context' do
        expect_command_capturing('maintenance', 'stop', env: { 'GIT_CONFIG_GLOBAL' => '/tmp/config' })
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
