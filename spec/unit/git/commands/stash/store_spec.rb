# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/stash/store'

RSpec.describe Git::Commands::Stash::Store do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with commit SHA only' do
      it 'calls git stash store with commit' do
        expect(execution_context).to receive(:command)
          .with('stash', 'store', 'abc123def456789')
          .and_return(command_result(''))

        command.call('abc123def456789')
      end

      it 'returns the command result' do
        result = command_result('')
        allow(execution_context).to receive(:command)
          .with('stash', 'store', 'abc123def456789')
          .and_return(result)

        expect(command.call('abc123def456789')).to eq(result)
      end
    end

    context 'with :message option' do
      it 'adds --message flag with value' do
        expect(execution_context).to receive(:command)
          .with('stash', 'store', '--message=WIP: my changes', 'abc123')
          .and_return(command_result(''))

        command.call('abc123', message: 'WIP: my changes')
      end

      it 'accepts :m alias' do
        expect(execution_context).to receive(:command)
          .with('stash', 'store', '--message=WIP', 'abc123')
          .and_return(command_result(''))

        command.call('abc123', m: 'WIP')
      end

      it 'handles message with special characters' do
        expect(execution_context).to receive(:command)
          .with('stash', 'store', '--message=Fix "bug" in code', 'abc123')
          .and_return(command_result(''))

        command.call('abc123', message: 'Fix "bug" in code')
      end

      it 'handles message with spaces' do
        expect(execution_context).to receive(:command)
          .with('stash', 'store', '--message=work in progress', 'abc123')
          .and_return(command_result(''))

        command.call('abc123', message: 'work in progress')
      end
    end

    context 'with full SHA' do
      it 'handles 40-character SHA' do
        sha = 'a' * 40
        expect(execution_context).to receive(:command)
          .with('stash', 'store', sha)
          .and_return(command_result(''))

        command.call(sha)
      end
    end
  end
end
