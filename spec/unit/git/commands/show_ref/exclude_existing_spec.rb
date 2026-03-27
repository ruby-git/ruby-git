# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/show_ref/exclude_existing'

RSpec.describe Git::Commands::ShowRef::ExcludeExisting do
  # Duck-type collaborator: command specs depend on the #command_capturing interface,
  # not a single concrete ExecutionContext class.
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  # Helper for asserting stdin-feeding filter commands.
  #
  # Intercepts `execution_context.command_capturing`, asserts the CLI args,
  # the standard execution options, and the exact bytes written to stdin.
  #
  # @param expected_cli_args [Array<String>] arguments expected after 'show-ref'
  # @param stdin_content [String] exact bytes that should be written to the pipe
  #
  def expect_filter_command(*expected_cli_args, stdin_content:, **extra_kwargs)
    expect(execution_context).to receive(:command_capturing) do |*args, **kwargs|
      expect(args).to eq(['show-ref', *expected_cli_args])
      expect(kwargs).to include(raise_on_failure: false, **extra_kwargs)
      expect(kwargs[:in].read).to eq(stdin_content)
      command_result
    end
  end

  describe '#call' do
    context 'with no refs' do
      it 'feeds empty stdin and passes --exclude-existing' do
        expected_result = command_result
        expect(execution_context).to receive(:command_capturing) do |*args, **kwargs|
          expect(args).to eq(['show-ref', '--exclude-existing'])
          expect(kwargs).to include(raise_on_failure: false)
          expect(kwargs[:in].read).to eq('')
          expected_result
        end

        result = command.call

        expect(result).to eq(expected_result)
      end
    end

    context 'with a single ref' do
      it 'writes the ref to stdin' do
        expect_filter_command('--exclude-existing', stdin_content: "refs/heads/main\n")

        command.call('refs/heads/main')
      end
    end

    context 'with multiple refs' do
      it 'writes each ref on its own line to stdin' do
        expect_filter_command(
          '--exclude-existing',
          stdin_content: "refs/heads/main\nrefs/tags/v1.0\n"
        )

        command.call('refs/heads/main', 'refs/tags/v1.0')
      end
    end

    context 'with exclude_existing set to a pattern string' do
      it 'adds --exclude-existing=<pattern> to argv' do
        expect_filter_command('--exclude-existing=refs/heads/', stdin_content: "refs/heads/main\n")

        command.call('refs/heads/main', exclude_existing: 'refs/heads/')
      end
    end

    context 'with the :timeout execution option' do
      it 'passes timeout to the execution context' do
        expect_filter_command('--exclude-existing', stdin_content: '', timeout: 5)

        command.call(timeout: 5)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError for unsupported options' do
        expect { command.call(bogus: true) }
          .to raise_error(ArgumentError, /Unsupported options/)
      end

      it 'raises ArgumentError when exclude_existing is false' do
        expect { command.call(exclude_existing: false) }
          .to raise_error(ArgumentError, /exclude_existing/)
      end

      it 'raises ArgumentError when exclude_existing is nil' do
        expect { command.call(exclude_existing: nil) }
          .to raise_error(ArgumentError, /exclude_existing/)
      end

      it 'raises ArgumentError when exclude_existing is an empty string' do
        expect { command.call(exclude_existing: '') }
          .to raise_error(ArgumentError, /exclude_existing/)
      end
    end
  end
end
