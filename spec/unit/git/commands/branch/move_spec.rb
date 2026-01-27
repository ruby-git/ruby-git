# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/branch/move'

RSpec.describe Git::Commands::Branch::Move do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with only new_branch (rename current branch)' do
      it 'calls git branch --move with only the new branch name' do
        expect(execution_context).to receive(:command).with('branch', '--move', 'new-name')
        command.call('new-name')
      end
    end

    context 'with old_branch and new_branch' do
      it 'calls git branch --move with both branch names' do
        expect(execution_context).to receive(:command).with('branch', '--move', 'old-name', 'new-name')
        command.call('old-name', 'new-name')
      end
    end

    context 'with :force option' do
      it 'adds --force flag when renaming current branch' do
        expect(execution_context).to receive(:command).with('branch', '--move', '--force', 'new-name')
        command.call('new-name', force: true)
      end

      it 'adds --force flag when renaming specific branch' do
        expect(execution_context).to receive(:command).with('branch', '--move', '--force', 'old-name', 'new-name')
        command.call('old-name', 'new-name', force: true)
      end

      it 'does not add flag when false' do
        expect(execution_context).to receive(:command).with('branch', '--move', 'new-name')
        command.call('new-name', force: false)
      end
    end

    context 'with unsupported options' do
      it 'raises ArgumentError for unknown options' do
        expect { command.call('new-name', unknown: true) }.to raise_error(ArgumentError, /unknown/)
      end
    end
  end
end
