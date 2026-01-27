# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/branch/create'

RSpec.describe Git::Commands::Branch::Create do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with branch name only (basic creation)' do
      it 'calls git branch with the branch name' do
        expect(execution_context).to receive(:command).with('branch', 'feature-branch')
        command.call('feature-branch')
      end
    end

    context 'with start_point' do
      it 'adds the start point after the branch name' do
        expect(execution_context).to receive(:command).with('branch', 'feature-branch', 'main')
        command.call('feature-branch', 'main')
      end

      it 'accepts a commit SHA as start point' do
        expect(execution_context).to receive(:command).with('branch', 'feature-branch', 'abc123')
        command.call('feature-branch', 'abc123')
      end

      it 'accepts a tag as start point' do
        expect(execution_context).to receive(:command).with('branch', 'feature-branch', 'v1.0.0')
        command.call('feature-branch', 'v1.0.0')
      end

      it 'accepts a remote branch as start point' do
        expect(execution_context).to receive(:command).with('branch', 'feature-branch', 'origin/main')
        command.call('feature-branch', 'origin/main')
      end
    end

    context 'with :force option' do
      it 'adds --force flag' do
        expect(execution_context).to receive(:command).with('branch', '--force', 'feature-branch')
        command.call('feature-branch', force: true)
      end

      it 'allows resetting an existing branch to a new start point' do
        expect(execution_context).to receive(:command).with('branch', '--force', 'feature-branch', 'main')
        command.call('feature-branch', 'main', force: true)
      end

      it 'does not add flag when false' do
        expect(execution_context).to receive(:command).with('branch', 'feature-branch')
        command.call('feature-branch', force: false)
      end
    end

    context 'with :create_reflog option' do
      it 'adds --create-reflog flag' do
        expect(execution_context).to receive(:command).with('branch', '--create-reflog', 'feature-branch')
        command.call('feature-branch', create_reflog: true)
      end

      it 'does not add flag when false' do
        expect(execution_context).to receive(:command).with('branch', 'feature-branch')
        command.call('feature-branch', create_reflog: false)
      end
    end

    context 'with :recurse_submodules option' do
      it 'adds --recurse-submodules flag' do
        expect(execution_context).to receive(:command).with('branch', '--recurse-submodules', 'feature-branch')
        command.call('feature-branch', recurse_submodules: true)
      end

      it 'does not add flag when false' do
        expect(execution_context).to receive(:command).with('branch', 'feature-branch')
        command.call('feature-branch', recurse_submodules: false)
      end
    end

    context 'with :track option' do
      context 'when true' do
        it 'adds --track flag' do
          expect(execution_context).to receive(:command).with('branch', '--track', 'feature-branch', 'origin/main')
          command.call('feature-branch', 'origin/main', track: true)
        end
      end

      context 'when false' do
        it 'adds --no-track flag' do
          expect(execution_context).to receive(:command).with('branch', '--no-track', 'feature-branch', 'origin/main')
          command.call('feature-branch', 'origin/main', track: false)
        end
      end

      context 'when "direct"' do
        it 'adds --track=direct flag' do
          expect(execution_context).to receive(:command).with(
            'branch', '--track=direct', 'feature-branch', 'origin/main'
          )
          command.call('feature-branch', 'origin/main', track: 'direct')
        end
      end

      context 'when "inherit"' do
        it 'adds --track=inherit flag' do
          expect(execution_context).to receive(:command).with(
            'branch', '--track=inherit', 'feature-branch', 'origin/main'
          )
          command.call('feature-branch', 'origin/main', track: 'inherit')
        end
      end
    end

    context 'with multiple options combined' do
      it 'includes all specified flags in correct order' do
        expect(execution_context).to receive(:command).with(
          'branch',
          '--force',
          '--create-reflog',
          '--track',
          'feature-branch',
          'origin/main'
        )
        command.call('feature-branch', 'origin/main', force: true, create_reflog: true, track: true)
      end

      it 'combines force with no-track' do
        expect(execution_context).to receive(:command).with(
          'branch',
          '--force',
          '--no-track',
          'feature-branch',
          'main'
        )
        command.call('feature-branch', 'main', force: true, track: false)
      end
    end

    context 'with nil start_point' do
      it 'omits the start point from the command' do
        expect(execution_context).to receive(:command).with('branch', 'feature-branch')
        command.call('feature-branch', nil)
      end

      it 'omits the start point when options are provided' do
        expect(execution_context).to receive(:command).with('branch', '--force', 'feature-branch')
        command.call('feature-branch', nil, force: true)
      end
    end
  end
end
