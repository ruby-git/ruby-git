# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/stash/store'

RSpec.describe Git::Commands::Stash::Store do
  # Duck-type collaborator: command specs depend on the #command_capturing interface,
  # not a single concrete ExecutionContext class.
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with commit SHA only' do
      it 'calls git stash store with commit' do
        expected_result = command_result('')
        expect_command_capturing('stash', 'store', '--', 'abc123def456789')
          .and_return(expected_result)

        result = command.call('abc123def456789')

        expect(result).to eq(expected_result)
      end
    end

    context 'with :message option' do
      it 'adds --message flag with value' do
        expect_command_capturing('stash', 'store', '--message', 'WIP: my changes', '--', 'abc123')
          .and_return(command_result(''))

        command.call('abc123', message: 'WIP: my changes')
      end

      it 'accepts :m alias' do
        expect_command_capturing('stash', 'store', '--message', 'WIP', '--', 'abc123')
          .and_return(command_result(''))

        command.call('abc123', m: 'WIP')
      end

      it 'handles message with special characters' do
        expect_command_capturing('stash', 'store', '--message', 'Fix "bug" in code', '--', 'abc123')
          .and_return(command_result(''))

        command.call('abc123', message: 'Fix "bug" in code')
      end

      it 'handles message with spaces' do
        expect_command_capturing('stash', 'store', '--message', 'work in progress', '--', 'abc123')
          .and_return(command_result(''))

        command.call('abc123', message: 'work in progress')
      end
    end

    context 'with :quiet option' do
      it 'adds --quiet flag' do
        expect_command_capturing('stash', 'store', '--quiet', '--', 'abc123def456')
          .and_return(command_result(''))

        command.call('abc123def456', quiet: true)
      end

      it 'accepts :q alias' do
        expect_command_capturing('stash', 'store', '--quiet', '--', 'abc123def456')
          .and_return(command_result(''))

        command.call('abc123def456', q: true)
      end
    end

    context 'with full SHA' do
      it 'handles 40-character SHA' do
        sha = 'a' * 40
        expect_command_capturing('stash', 'store', '--', sha)
          .and_return(command_result(''))

        command.call(sha)
      end
    end
  end
end
