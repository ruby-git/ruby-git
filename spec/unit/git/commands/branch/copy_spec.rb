# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/branch/copy'

RSpec.describe Git::Commands::Branch::Copy do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with only new_branch (copy current branch)' do
      it 'calls git branch --copy with only the new branch name' do
        expect(execution_context).to receive(:command).with('branch', '--copy', 'new-name')
        command.call('new-name')
      end
    end

    context 'with old_branch and new_branch' do
      it 'calls git branch --copy with both branch names' do
        expect(execution_context).to receive(:command).with('branch', '--copy', 'old-name', 'new-name')
        command.call('old-name', 'new-name')
      end
    end

    context 'with :force option' do
      it 'adds --force flag when copying current branch' do
        expect(execution_context).to receive(:command).with('branch', '--copy', '--force', 'new-name')
        command.call('new-name', force: true)
      end

      it 'adds --force flag when copying specific branch' do
        expect(execution_context).to receive(:command).with('branch', '--copy', '--force', 'old-name', 'new-name')
        command.call('old-name', 'new-name', force: true)
      end

      it 'does not add flag when false' do
        expect(execution_context).to receive(:command).with('branch', '--copy', 'new-name')
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
