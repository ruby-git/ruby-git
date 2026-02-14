# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/tag/verify'

RSpec.describe Git::Commands::Tag::Verify do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with a single tag name' do
      it 'calls git tag --verify with the tag name' do
        expected_result = command_result
        expect(execution_context).to receive(:command).with('tag', '--verify', 'v1.0.0')
                                                      .and_return(expected_result)

        result = command.call('v1.0.0')

        expect(result).to eq(expected_result)
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

    context 'input validation' do
      it 'raises ArgumentError when no tag names are provided' do
        expect { command.call }.to raise_error(ArgumentError, /at least one value is required for tag_names/i)
      end
    end
  end
end
