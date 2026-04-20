# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/maintenance/run'

RSpec.describe Git::Commands::Maintenance::Run do
  let(:execution_context) { execution_context_double }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with no arguments' do
      it 'runs git maintenance run' do
        expected_result = command_result('')
        expect_command_capturing('maintenance', 'run').and_return(expected_result)

        result = command.call

        expect(result).to eq(expected_result)
      end
    end

    context 'with :auto option' do
      it 'includes the --auto flag' do
        expect_command_capturing('maintenance', 'run', '--auto').and_return(command_result(''))

        command.call(auto: true)
      end

      it 'includes the --no-auto flag' do
        expect_command_capturing('maintenance', 'run', '--no-auto').and_return(command_result(''))

        command.call(auto: false)
      end
    end

    context 'with :detach option' do
      it 'includes the --detach flag' do
        expect_command_capturing('maintenance', 'run', '--detach').and_return(command_result(''))

        command.call(detach: true)
      end

      it 'includes the --no-detach flag' do
        expect_command_capturing('maintenance', 'run', '--no-detach').and_return(command_result(''))

        command.call(detach: false)
      end
    end

    context 'with :scheduled option' do
      it 'includes the --scheduled flag' do
        expect_command_capturing('maintenance', 'run', '--scheduled').and_return(command_result(''))

        command.call(scheduled: true)
      end

      it 'includes the --no-scheduled flag' do
        expect_command_capturing('maintenance', 'run', '--no-scheduled').and_return(command_result(''))

        command.call(scheduled: false)
      end
    end

    context 'with :schedule option as a frequency string' do
      it 'passes --schedule=<frequency>' do
        expect_command_capturing('maintenance', 'run', '--schedule=hourly').and_return(command_result(''))

        command.call(schedule: 'hourly')
      end
    end

    context 'with :schedule option as true' do
      it 'passes --schedule' do
        expect_command_capturing('maintenance', 'run', '--schedule').and_return(command_result(''))

        command.call(schedule: true)
      end
    end

    context 'with :schedule option as false' do
      it 'passes --no-schedule' do
        expect_command_capturing('maintenance', 'run', '--no-schedule').and_return(command_result(''))

        command.call(schedule: false)
      end
    end

    context 'with :quiet option' do
      it 'includes the --quiet flag' do
        expect_command_capturing('maintenance', 'run', '--quiet').and_return(command_result(''))

        command.call(quiet: true)
      end

      it 'includes the --no-quiet flag' do
        expect_command_capturing('maintenance', 'run', '--no-quiet').and_return(command_result(''))

        command.call(quiet: false)
      end
    end

    context 'with :task option as a single value' do
      it 'passes --task=<task>' do
        expect_command_capturing('maintenance', 'run', '--task=gc').and_return(command_result(''))

        command.call(task: 'gc')
      end
    end

    context 'with :task option as multiple values' do
      it 'passes multiple --task flags' do
        expect_command_capturing('maintenance', 'run', '--task=gc', '--task=commit-graph')
          .and_return(command_result(''))

        command.call(task: %w[gc commit-graph])
      end
    end

    context 'with :env execution option' do
      it 'forwards env: to the execution context' do
        expect_command_capturing('maintenance', 'run', env: { 'GIT_CONFIG_GLOBAL' => '/tmp/config' })
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
