# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/cat_file/object_content'

RSpec.describe Git::Commands::CatFile::ObjectContent do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  # Static args that ObjectContent always includes
  let(:static_args) { ['cat-file', '--batch'] }

  # Helper that stubs execution_context.command, captures the :in IO, and verifies
  # the stdin content matches expected_stdin. Returns the given result.
  def expect_batch_command(*extra_args, stdin_content: nil, **extra_opts) # rubocop:disable Metrics/AbcSize
    expect(execution_context).to receive(:command) do |*args, **kwargs|
      expect(args).to eq([*static_args, *extra_args])
      expect(kwargs).to include(raise_on_failure: false)
      if stdin_content
        expect(kwargs[:in]).to be_a(IO)
        expect(kwargs[:in].read).to eq(stdin_content)
      end
      extra_opts[:returns] || command_result
    end
  end

  describe '#call' do
    context 'with one object' do
      it 'passes the object via stdin and runs --batch' do
        expect_batch_command(stdin_content: "HEAD\n")
        command.call('HEAD')
      end
    end

    context 'with multiple objects' do
      it 'writes each object on its own line to stdin' do
        expect_batch_command(stdin_content: "HEAD\nv1.0\nabc1234\n")
        command.call('HEAD', 'v1.0', 'abc1234')
      end
    end

    context 'with no objects and no options' do
      it 'raises ArgumentError' do
        expect { command.call }.to raise_error(
          ArgumentError, 'at least one object is required unless batch_all_objects: true'
        )
      end
    end

    context 'with objects and batch_all_objects: true' do
      it 'raises ArgumentError' do
        expect { command.call('HEAD', batch_all_objects: true) }.to raise_error(
          ArgumentError, 'objects cannot be passed with batch_all_objects: true'
        )
      end
    end

    context 'with batch_all_objects: true' do
      it 'includes --batch-all-objects and writes nothing to stdin' do
        expect_batch_command('--batch-all-objects', stdin_content: '')
        command.call(batch_all_objects: true)
      end
    end

    context 'with unordered: true' do
      it 'includes --unordered' do
        expect_batch_command('--unordered', stdin_content: "HEAD\n")
        command.call('HEAD', unordered: true)
      end
    end

    context 'with follow_symlinks: true' do
      it 'includes --follow-symlinks' do
        expect_batch_command('--follow-symlinks', stdin_content: "HEAD\n")
        command.call('HEAD', follow_symlinks: true)
      end
    end

    context 'with allow_unknown_type: true' do
      it 'includes --allow-unknown-type' do
        expect_batch_command('--allow-unknown-type', stdin_content: "HEAD\n")
        command.call('HEAD', allow_unknown_type: true)
      end
    end

    context 'with multiple flags combined' do
      it 'includes all flags in definition order' do
        expect_batch_command('--batch-all-objects', '--unordered', stdin_content: '')
        command.call(batch_all_objects: true, unordered: true)
      end
    end

    context 'with an unsupported option' do
      it 'raises ArgumentError' do
        expect { command.call('HEAD', bogus: true) }.to raise_error(
          ArgumentError, /Unsupported options: :bogus/
        )
      end
    end

    context 'return value' do
      it 'returns the CommandLineResult from the execution context' do
        blob_output = "abc1234 blob 13\nHello, world!\n\n"
        expected = command_result(blob_output)
        allow(execution_context).to receive(:command).and_return(expected)

        result = command.call('HEAD:README.md')
        expect(result).to eq(expected)
      end
    end

    context 'error handling' do
      it 'raises Git::FailedError when git exits with unexpected status 128' do
        allow(execution_context).to receive(:command).and_return(
          command_result('', exitstatus: 128)
        )
        expect { command.call('HEAD') }.to raise_error(Git::FailedError)
      end

      it 'returns the result when a missing object exits 0 (missing line in output)' do
        expected = command_result("deadbeef missing\n")
        allow(execution_context).to receive(:command).and_return(expected)

        result = command.call('deadbeef')
        expect(result.stdout).to eq("deadbeef missing\n")
      end
    end
  end
end
