# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::Commands::Reset do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with no arguments' do
      it 'runs git reset without a commit' do
        expected_result = command_result
        expect(execution_context).to receive(:command).with('reset')
                                                      .and_return(expected_result)

        result = command.call

        expect(result).to eq(expected_result)
      end
    end

    context 'with a commit argument' do
      it 'resets to the specified commit' do
        expect(execution_context).to receive(:command).with('reset', 'HEAD~1')

        command.call('HEAD~1')
      end

      it 'resets to a SHA' do
        expect(execution_context).to receive(:command).with('reset', 'abc123')

        command.call('abc123')
      end

      it 'accepts nil as the commit' do
        expect(execution_context).to receive(:command).with('reset')

        command.call(nil)
      end
    end

    context 'with the :hard option' do
      it 'includes the --hard flag when true' do
        expect(execution_context).to receive(:command).with('reset', '--hard')

        command.call(hard: true)
      end

      it 'includes --hard with a commit' do
        expect(execution_context).to receive(:command).with('reset', '--hard', 'HEAD~1')

        command.call('HEAD~1', hard: true)
      end

      it 'does not include the flag when false' do
        expect(execution_context).to receive(:command).with('reset')

        command.call(hard: false)
      end
    end

    context 'with the :soft option' do
      it 'includes the --soft flag when true' do
        expect(execution_context).to receive(:command).with('reset', '--soft')

        command.call(soft: true)
      end

      it 'includes --soft with a commit' do
        expect(execution_context).to receive(:command).with('reset', '--soft', 'HEAD~1')

        command.call('HEAD~1', soft: true)
      end

      it 'does not include the flag when false' do
        expect(execution_context).to receive(:command).with('reset')

        command.call(soft: false)
      end
    end

    context 'with the :mixed option' do
      it 'includes the --mixed flag when true' do
        expect(execution_context).to receive(:command).with('reset', '--mixed')

        command.call(mixed: true)
      end

      it 'includes --mixed with a commit' do
        expect(execution_context).to receive(:command).with('reset', '--mixed', 'HEAD~1')

        command.call('HEAD~1', mixed: true)
      end

      it 'does not include the flag when false' do
        expect(execution_context).to receive(:command).with('reset')

        command.call(mixed: false)
      end
    end

    context 'input validation' do
      it 'raises an error when both hard and soft are true' do
        expect { command.call(hard: true, soft: true) }.to(
          raise_error(ArgumentError, /cannot specify :hard and :soft/)
        )
      end

      it 'raises an error when both hard and mixed are true' do
        expect { command.call(hard: true, mixed: true) }.to(
          raise_error(ArgumentError, /cannot specify :hard and :mixed/)
        )
      end

      it 'raises an error when both soft and mixed are true' do
        expect { command.call(soft: true, mixed: true) }.to(
          raise_error(ArgumentError, /cannot specify :soft and :mixed/)
        )
      end

      it 'raises an error when all three are true' do
        expect { command.call(hard: true, soft: true, mixed: true) }.to(
          raise_error(ArgumentError, /cannot specify/)
        )
      end

      it 'raises ArgumentError for unsupported options' do
        expect { command.call('HEAD', invalid_option: true) }.to(
          raise_error(ArgumentError, /Unsupported options: :invalid_option/)
        )
      end
    end
  end
end
