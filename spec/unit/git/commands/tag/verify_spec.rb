# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/tag/verify'

RSpec.describe Git::Commands::Tag::Verify do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with a single tag name' do
      it 'calls git tag --verify with the tag name' do
        expect(execution_context).to receive(:command).with('tag', '--verify', 'v1.0.0')
        command.call('v1.0.0')
      end
    end

    context 'with multiple tag names' do
      it 'passes all tag names to the command' do
        expect(execution_context).to receive(:command).with('tag', '--verify', 'v1.0.0', 'v2.0.0', 'v3.0.0')
        command.call('v1.0.0', 'v2.0.0', 'v3.0.0')
      end
    end

    context 'with :format option' do
      it 'adds --format flag with the specified format string' do
        expect(execution_context).to receive(:command).with(
          'tag', '--verify', '--format=%(refname:short)', 'v1.0.0'
        )
        command.call('v1.0.0', format: '%(refname:short)')
      end

      it 'works with multiple tags and format' do
        expect(execution_context).to receive(:command).with(
          'tag', '--verify', '--format=%(objectname)', 'v1.0.0', 'v2.0.0'
        )
        command.call('v1.0.0', 'v2.0.0', format: '%(objectname)')
      end
    end

    context 'return value' do
      let(:mock_result) { double('Result', stdout: "Good signature from \"Test User <test@example.com>\"\n") }

      it 'returns the command output' do
        allow(execution_context).to receive(:command).and_return(mock_result)
        result = command.call('v1.0.0')
        expect(result).to eq(mock_result)
      end
    end

    context 'error behavior' do
      # The command propagates Git::FailedError from execution_context.command
      # when tag doesn't exist or signature verification fails.
      # This is tested via integration tests, not unit tests.
      it 'propagates errors from execution context' do
        error = Git::FailedError.new(command_result('', stderr: 'error', exitstatus: 1))
        allow(execution_context).to receive(:command).and_raise(error)
        expect { command.call('unsigned-tag') }.to raise_error(Git::FailedError)
      end
    end

    context 'argument validation' do
      it 'raises ArgumentError when no tag names are provided' do
        expect { command.call }.to raise_error(ArgumentError, /at least one value is required for tag_names/i)
      end
    end
  end
end
