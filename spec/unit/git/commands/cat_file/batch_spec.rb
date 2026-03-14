# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/cat_file/batch'

RSpec.describe Git::Commands::CatFile::Batch do
  # Duck-type collaborator: command specs depend on the #command_capturing interface,
  # not a single concrete ExecutionContext class.
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  # Helper for asserting stdin-feeding batch commands (capturing path).
  #
  # Intercepts `execution_context.command_capturing`, asserts the CLI args, the
  # standard batch execution options, and the exact content written to stdin.
  #
  # @param expected_cli_args [Array<String>] arguments expected after 'cat-file'
  # @param stdin_content [String] exact bytes that should be written to the pipe
  #
  def expect_batch_command(*expected_cli_args, stdin_content:)
    expect(execution_context).to receive(:command_capturing) do |*args, **kwargs|
      expect(args).to eq(['cat-file', *expected_cli_args])
      expect(kwargs).to include(raise_on_failure: false, normalize: false, chomp: false)
      expect(kwargs[:in].read).to eq(stdin_content)
      command_result
    end
  end

  # Helper for asserting stdin-feeding batch commands (streaming path).
  #
  # Intercepts `execution_context.command_streaming`, asserts the CLI args,
  # the out: option, and the exact content written to stdin.
  #
  # @param expected_cli_args [Array<String>] arguments expected after 'cat-file'
  # @param out [#write] expected IO destination
  # @param stdin_content [String] exact bytes that should be written to the pipe
  #
  def expect_batch_streaming_command(*expected_cli_args, out:, stdin_content:)
    expect(execution_context).to receive(:command_streaming) do |*args, **kwargs|
      expect(args).to eq(['cat-file', *expected_cli_args])
      expect(kwargs).to include(raise_on_failure: false, out: out)
      expect(kwargs[:in].read).to eq(stdin_content)
      command_result
    end
  end

  describe '#initialize' do
    it 'accepts an execution context' do
      expect { described_class.new(execution_context) }.not_to raise_error
    end
  end

  describe '#call' do
    context 'with --batch mode and a single object' do
      it 'passes --batch, writes the object to stdin, and returns the result' do
        expected_result = command_result("abc123 blob 6\nhello\n\n", exitstatus: 0)
        expect(execution_context).to receive(:command_capturing) do |*args, **kwargs|
          expect(args).to eq(['cat-file', '--batch'])
          expect(kwargs).to include(raise_on_failure: false, normalize: false, chomp: false)
          expect(kwargs[:in].read).to eq("HEAD\n")
          expected_result
        end

        result = command.call('HEAD', batch: true)

        expect(result).to eq(expected_result)
      end
    end

    context 'with --batch mode and multiple objects' do
      it 'writes each object on its own line to stdin' do
        expect_batch_command('--batch', stdin_content: "HEAD\nv1.0\nabc123\n")

        command.call('HEAD', 'v1.0', 'abc123', batch: true)
      end
    end

    context 'with --batch-check mode' do
      it 'passes --batch-check and writes the object to stdin' do
        expect_batch_command('--batch-check', stdin_content: "HEAD\n")

        command.call('HEAD', batch_check: true)
      end
    end

    context 'with --batch-command mode' do
      it 'passes --batch-command and writes pre-formatted command lines to stdin' do
        expect_batch_command('--batch-command', stdin_content: "contents HEAD\n")

        command.call('contents HEAD', batch_command: true)
      end
    end

    context 'with --batch-all-objects and --batch' do
      it 'passes --batch --batch-all-objects and writes nothing to stdin' do
        expect_batch_command('--batch', '--batch-all-objects', stdin_content: '')

        command.call(batch_all_objects: true, batch: true)
      end
    end

    context 'with --batch-all-objects and --batch-check' do
      it 'passes --batch-check --batch-all-objects and writes nothing to stdin' do
        expect_batch_command('--batch-check', '--batch-all-objects', stdin_content: '')

        command.call(batch_all_objects: true, batch_check: true)
      end
    end

    context 'with the :buffer option' do
      it 'passes --buffer alongside --batch-command' do
        expect_batch_command('--batch-command', '--buffer', stdin_content: "info HEAD\n")

        command.call('info HEAD', batch_command: true, buffer: true)
      end
    end

    context 'with the :filter option' do
      it 'passes --filter= inline' do
        expect_batch_command('--batch-check', '--filter=blob:none', stdin_content: "HEAD\n")

        command.call('HEAD', batch_check: true, filter: 'blob:none')
      end
    end

    context 'with the :Z option (NUL-delimited I/O)' do
      it 'writes NUL-terminated object names to stdin' do
        expect_batch_command('--batch', '-Z', stdin_content: "HEAD\0v1.0\0")

        command.call('HEAD', 'v1.0', batch: true, Z: true)
      end
    end

    context 'with out: execution option (streaming)' do
      let(:out_io) { instance_double(File) }

      it 'dispatches to command_streaming for --batch when out: is given' do
        expect_batch_streaming_command('--batch', out: out_io, stdin_content: "HEAD\n")

        command.call('HEAD', batch: true, out: out_io)
      end

      it 'dispatches to command_streaming for --batch-check when out: is given' do
        expect_batch_streaming_command('--batch-check', out: out_io, stdin_content: "HEAD\n")

        command.call('HEAD', batch_check: true, out: out_io)
      end

      it 'dispatches to command_streaming for --batch-all-objects when out: is given' do
        expect_batch_streaming_command('--batch-check', '--batch-all-objects', out: out_io, stdin_content: '')

        command.call(batch_all_objects: true, batch_check: true, out: out_io)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError when :object and :batch_all_objects are combined' do
        expect { command.call('HEAD', batch_all_objects: true, batch: true) }
          .to raise_error(ArgumentError, /cannot specify :object and :batch_all_objects/)
      end

      it 'raises ArgumentError when neither :object nor :batch_all_objects is provided' do
        expect { command.call(batch: true) }
          .to raise_error(ArgumentError, /at least one of :object, :batch_all_objects must be provided/)
      end

      it 'raises ArgumentError for an unsupported option' do
        expect { command.call('HEAD', batch: true, bogus: true) }
          .to raise_error(ArgumentError, /bogus|Unsupported options/)
      end
    end
  end
end
