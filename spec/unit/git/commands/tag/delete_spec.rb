# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/tag/delete'

RSpec.describe Git::Commands::Tag::Delete do
  let(:execution_context) { execution_context_double }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with a single tag name' do
      it 'calls git tag --delete with the tag name' do
        expected_result = command_result
        expect_command_capturing('tag', '--delete', 'v1.0.0').and_return(expected_result)

        result = command.call('v1.0.0')

        expect(result).to eq(expected_result)
      end
    end

    context 'with multiple tag names' do
      it 'passes all tag names as operands' do
        expect_command_capturing('tag', '--delete', 'v1.0.0', 'v2.0.0', 'v3.0.0').and_return(command_result)
        command.call('v1.0.0', 'v2.0.0', 'v3.0.0')
      end
    end

    context 'exit status' do
      it 'returns result for exit code 1 (partial failure)' do
        expect_command_capturing('tag', '--delete', 'v1.0.0', 'nonexistent')
          .and_return(command_result('', exitstatus: 1))

        result = command.call('v1.0.0', 'nonexistent')

        expect(result.status.exitstatus).to eq(1)
      end

      it 'raises FailedError for exit code > 1' do
        expect_command_capturing('tag', '--delete', 'v1.0.0')
          .and_return(command_result('', exitstatus: 128))

        expect { command.call('v1.0.0') }.to raise_error(Git::FailedError)
      end
    end
  end
end
