# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/update_ref/batch'

RSpec.describe Git::Commands::UpdateRef::Batch do
  let(:execution_context) { execution_context_double }
  let(:command) { described_class.new(execution_context) }

  # Helper for asserting stdin-feeding batch commands (capturing path).
  #
  # Intercepts `execution_context.command_capturing`, asserts the CLI args and
  # the exact content written to stdin.
  #
  # @param expected_cli_args [Array<String>] arguments expected after 'update-ref'
  # @param stdin_content [String] exact bytes that should be written to the pipe
  #
  def expect_batch_command(*expected_cli_args, stdin_content:)
    expect(execution_context).to receive(:command_capturing) do |*args, **kwargs|
      expect(args).to eq(['update-ref', '--stdin', *expected_cli_args])
      expect(kwargs).to include(raise_on_failure: false)
      expect(kwargs[:in].read).to eq(stdin_content)
      command_result
    end
  end

  describe '#call' do
    context 'with a single instruction' do
      it 'writes the instruction to stdin with newline delimiter' do
        expected_result = command_result
        expect(execution_context).to receive(:command_capturing) do |*args, **kwargs|
          expect(args).to eq(['update-ref', '--stdin'])
          expect(kwargs).to include(raise_on_failure: false)
          expect(kwargs[:in].read).to eq("update refs/heads/main newsha oldsha\n")
          expected_result
        end

        result = command.call('update refs/heads/main newsha oldsha')

        expect(result).to eq(expected_result)
      end
    end

    context 'with multiple instructions' do
      it 'writes each instruction on its own line to stdin' do
        expect_batch_command(
          stdin_content: "update refs/heads/main newsha oldsha\ndelete refs/heads/old\n"
        )

        command.call(
          'update refs/heads/main newsha oldsha',
          'delete refs/heads/old'
        )
      end
    end

    context 'with the :z option' do
      it 'adds -z and uses NUL-delimited stdin' do
        expect(execution_context).to receive(:command_capturing) do |*args, **kwargs|
          expect(args).to eq(['update-ref', '--stdin', '-z'])
          expect(kwargs).to include(raise_on_failure: false)
          expect(kwargs[:in].read).to eq("update refs/heads/main\0newsha\0oldsha\0")
          command_result
        end

        command.call("update refs/heads/main\0newsha\0oldsha", z: true)
      end
    end

    context 'with the :no_deref option' do
      it 'adds --no-deref to the command line' do
        expect(execution_context).to receive(:command_capturing) do |*args, **kwargs|
          expect(args).to eq(['update-ref', '--no-deref', '--stdin'])
          expect(kwargs).to include(raise_on_failure: false)
          expect(kwargs[:in].read).to eq("update refs/heads/main newsha\n")
          command_result
        end

        command.call('update refs/heads/main newsha', no_deref: true)
      end
    end

    context 'with the :m option' do
      it 'adds -m <reason> to the command line' do
        expect(execution_context).to receive(:command_capturing) do |*args, **kwargs|
          expect(args).to eq(['update-ref', '-m', 'batch update', '--stdin'])
          expect(kwargs).to include(raise_on_failure: false)
          expect(kwargs[:in].read).to eq("update refs/heads/main newsha\n")
          command_result
        end

        command.call('update refs/heads/main newsha', m: 'batch update')
      end
    end

    context 'with multiple options combined' do
      it 'includes all options in definition order' do
        expect(execution_context).to receive(:command_capturing) do |*args, **kwargs|
          expect(args).to eq(['update-ref', '-m', 'reason', '--no-deref', '--stdin', '-z'])
          expect(kwargs).to include(raise_on_failure: false)
          expect(kwargs[:in].read).to eq("update refs/heads/main\0newsha\0")
          command_result
        end

        command.call("update refs/heads/main\0newsha", m: 'reason', no_deref: true, z: true)
      end
    end

    context 'with the :batch_updates option' do
      it 'adds --batch-updates after --stdin' do
        expect(execution_context).to receive(:command_capturing) do |*args, **kwargs|
          expect(args).to eq(['update-ref', '--stdin', '--batch-updates'])
          expect(kwargs).to include(raise_on_failure: false)
          expect(kwargs[:in].read).to eq("update refs/heads/main newsha\n")
          command_result
        end

        command.call('update refs/heads/main newsha', batch_updates: true)
      end
    end

    context 'with the :timeout execution option' do
      it 'passes timeout to the execution context' do
        expect(execution_context).to receive(:command_capturing) do |*args, **kwargs|
          expect(args).to eq(['update-ref', '--stdin'])
          expect(kwargs).to include(raise_on_failure: false, timeout: 5)
          expect(kwargs[:in].read).to eq("update refs/heads/main newsha\n")
          command_result
        end

        command.call('update refs/heads/main newsha', timeout: 5)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError for unsupported options' do
        expect { command.call('update refs/heads/main newsha', unknown: true) }
          .to raise_error(ArgumentError, /Unsupported options/)
      end

      it 'raises ArgumentError when no instructions are provided' do
        expect { command.call }
          .to raise_error(ArgumentError, /at least one value is required for instructions/)
      end
    end
  end
end
