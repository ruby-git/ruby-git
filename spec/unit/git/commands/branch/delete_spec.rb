# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/branch/delete'

RSpec.describe Git::Commands::Branch::Delete do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with single branch name (basic deletion)' do
      it 'calls git branch --delete with the branch name' do
        expect(execution_context).to receive(:command).with('branch', '--delete', 'feature-branch')
        command.call('feature-branch')
      end
    end

    context 'with multiple branch names' do
      it 'deletes all specified branches in one command' do
        expect(execution_context).to receive(:command).with('branch', '--delete', 'branch1', 'branch2', 'branch3')
        command.call('branch1', 'branch2', 'branch3')
      end
    end

    context 'with :force option' do
      it 'adds --force flag' do
        expect(execution_context).to receive(:command).with('branch', '--delete', '--force', 'feature-branch')
        command.call('feature-branch', force: true)
      end

      it 'does not add flag when false' do
        expect(execution_context).to receive(:command).with('branch', '--delete', 'feature-branch')
        command.call('feature-branch', force: false)
      end

      it 'accepts :f alias' do
        expect(execution_context).to receive(:command).with('branch', '--delete', '--force', 'feature-branch')
        command.call('feature-branch', f: true)
      end
    end

    context 'with :remotes option' do
      it 'adds --remotes flag for remote-tracking branches' do
        expect(execution_context).to receive(:command).with('branch', '--delete', '--remotes', 'origin/feature')
        command.call('origin/feature', remotes: true)
      end

      it 'does not add flag when false' do
        expect(execution_context).to receive(:command).with('branch', '--delete', 'origin/feature')
        command.call('origin/feature', remotes: false)
      end

      it 'accepts :r alias' do
        expect(execution_context).to receive(:command).with('branch', '--delete', '--remotes', 'origin/feature')
        command.call('origin/feature', r: true)
      end
    end

    context 'with :quiet option' do
      it 'adds --quiet flag' do
        expect(execution_context).to receive(:command).with('branch', '--delete', '--quiet', 'feature-branch')
        command.call('feature-branch', quiet: true)
      end

      it 'does not add flag when false' do
        expect(execution_context).to receive(:command).with('branch', '--delete', 'feature-branch')
        command.call('feature-branch', quiet: false)
      end

      it 'accepts :q alias' do
        expect(execution_context).to receive(:command).with('branch', '--delete', '--quiet', 'feature-branch')
        command.call('feature-branch', q: true)
      end
    end

    context 'with multiple options combined' do
      it 'includes all specified flags in correct order' do
        expect(execution_context).to receive(:command).with(
          'branch',
          '--delete',
          '--force',
          '--remotes',
          '--quiet',
          'origin/feature'
        )
        command.call('origin/feature', force: true, remotes: true, quiet: true)
      end

      it 'combines force with multiple branches' do
        expect(execution_context).to receive(:command).with(
          'branch',
          '--delete',
          '--force',
          'branch1',
          'branch2'
        )
        command.call('branch1', 'branch2', force: true)
      end

      it 'combines remotes with multiple branches' do
        expect(execution_context).to receive(:command).with(
          'branch',
          '--delete',
          '--remotes',
          'origin/branch1',
          'origin/branch2'
        )
        command.call('origin/branch1', 'origin/branch2', remotes: true)
      end
    end
  end
end
