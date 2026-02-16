# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::Commands::Base do
  let(:execution_context) { double('ExecutionContext') }

  describe '.arguments' do
    it 'stores a frozen args definition' do
      command_class = Class.new(described_class) do
        arguments do
          literal 'status'
        end
      end

      expect(command_class.args_definition).to be_a(Git::Commands::Arguments)
      expect(command_class.args_definition).to be_frozen
    end

    it 'raises ArgumentError when called twice on the same class' do
      command_class = Class.new(described_class) do
        arguments do
          literal 'status'
        end
      end

      expect do
        command_class.arguments do
          literal 'add'
        end
      end.to raise_error(ArgumentError, /arguments already defined/)
    end
  end

  describe '.allow_exit_status' do
    let(:command_class) do
      Class.new(described_class) do
        arguments do
          literal 'status'
        end
      end
    end

    it 'raises ArgumentError for non-Range values' do
      expect { command_class.allow_exit_status(1) }
        .to raise_error(ArgumentError, /expects a Range/)
    end

    it 'raises ArgumentError when bounds are not Integers' do
      expect { command_class.allow_exit_status('0'..'1') }
        .to raise_error(ArgumentError, /bounds must be Integers/)
    end

    it 'raises ArgumentError for inverted ranges' do
      expect { command_class.allow_exit_status(2..1) }
        .to raise_error(ArgumentError, /range must not be empty/)
    end
  end

  describe '#call' do
    let(:command_class) do
      Class.new(described_class) do
        arguments do
          literal 'status'
          execution_option :timeout
        end
      end
    end
    let(:command) { command_class.new(execution_context) }

    it 'raises on non-zero exit status by default' do
      allow(execution_context).to receive(:command)
        .with('status', raise_on_failure: false)
        .and_return(command_result('', exitstatus: 1))

      expect { command.call }
        .to raise_error(Git::FailedError)
    end

    it 'accepts status 1 when allow_exit_status 0..1 is configured' do
      command_class.allow_exit_status(0..1)
      allow(execution_context).to receive(:command)
        .with('status', raise_on_failure: false)
        .and_return(command_result('', exitstatus: 1))

      result = command.call

      expect(result.status.exitstatus).to eq(1)
    end

    it 'accepts exit status values 1 through 7 when allow_exit_status 0..7 is configured' do
      command_class.allow_exit_status(0..7)

      (1..7).each do |exitstatus|
        allow(execution_context).to receive(:command)
          .with('status', raise_on_failure: false)
          .and_return(command_result('', exitstatus: exitstatus))

        result = command.call
        expect(result.status.exitstatus).to eq(exitstatus)
      end
    end

    it 'accepts exit status only when included in declared range' do
      command_class.allow_exit_status(0..1)
      allow(execution_context).to receive(:command)
        .with('status', raise_on_failure: false)
        .and_return(command_result('', exitstatus: 2))

      expect { command.call }
        .to raise_error(Git::FailedError)
    end

    it 'raises ArgumentError when arguments are not defined on the command class' do
      stub_const('Git::Commands::BaseSpecMissingArgsCommand', Class.new(described_class))
      no_args_command = Git::Commands::BaseSpecMissingArgsCommand.new(execution_context)

      expect { no_args_command.call }
        .to raise_error(ArgumentError, /arguments not defined/)
    end

    it 'propagates timeout errors from execution context' do
      timeout_error = Git::TimeoutError.new(command_result('', stderr: 'timed out'), 1)
      allow(execution_context).to receive(:command)
        .with('status', raise_on_failure: false)
        .and_raise(timeout_error)

      expect { command.call }
        .to raise_error(Git::TimeoutError)
    end

    it 'propagates signal errors from execution context' do
      signaled_error = Git::SignaledError.new(command_result('', stderr: 'killed'))
      allow(execution_context).to receive(:command)
        .with('status', raise_on_failure: false)
        .and_raise(signaled_error)

      expect { command.call }
        .to raise_error(Git::SignaledError)
    end

    it 'forwards execution options extracted from bound arguments' do
      allow(execution_context).to receive(:command)
        .with('status', timeout: 30, raise_on_failure: false)
        .and_return(command_result)

      command.call(timeout: 30)
    end

    it 'does not forward execution option keywords when none are provided' do
      allow(execution_context).to receive(:command)
        .with('status', raise_on_failure: false)
        .and_return(command_result)

      command.call
    end

    it 'does not forward extra keywords for commands without execution options' do
      no_exec_opts_class = Class.new(described_class) do
        arguments do
          literal 'status'
        end
      end
      no_exec_opts_command = no_exec_opts_class.new(execution_context)

      allow(execution_context).to receive(:command)
        .with('status', raise_on_failure: false)
        .and_return(command_result)

      no_exec_opts_command.call
    end
  end
end
