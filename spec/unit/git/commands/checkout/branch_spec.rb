# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/checkout/branch'

RSpec.describe Git::Commands::Checkout::Branch do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with no arguments' do
      it 'calls git checkout with no arguments' do
        expect(execution_context).to receive(:command).with('checkout')
        command.call
      end
    end

    context 'with branch name only' do
      it 'calls git checkout with the branch name' do
        expect(execution_context).to receive(:command).with('checkout', 'main')
        command.call('main')
      end

      it 'accepts a commit SHA' do
        expect(execution_context).to receive(:command).with('checkout', 'abc123')
        command.call('abc123')
      end

      it 'accepts a remote branch' do
        expect(execution_context).to receive(:command).with('checkout', 'origin/main')
        command.call('origin/main')
      end
    end

    context 'with :force option' do
      it 'adds --force flag' do
        expect(execution_context).to receive(:command).with('checkout', '--force', 'main')
        command.call('main', force: true)
      end

      it 'does not add flag when false' do
        expect(execution_context).to receive(:command).with('checkout', 'main')
        command.call('main', force: false)
      end

      it 'works with :f alias' do
        expect(execution_context).to receive(:command).with('checkout', '--force', 'main')
        command.call('main', f: true)
      end
    end

    context 'with :merge option' do
      it 'adds --merge flag' do
        expect(execution_context).to receive(:command).with('checkout', '--merge', 'main')
        command.call('main', merge: true)
      end

      it 'does not add flag when false' do
        expect(execution_context).to receive(:command).with('checkout', 'main')
        command.call('main', merge: false)
      end

      it 'works with :m alias' do
        expect(execution_context).to receive(:command).with('checkout', '--merge', 'main')
        command.call('main', m: true)
      end
    end

    context 'with :detach option' do
      it 'adds --detach flag' do
        expect(execution_context).to receive(:command).with('checkout', '--detach', 'main')
        command.call('main', detach: true)
      end

      it 'does not add flag when false' do
        expect(execution_context).to receive(:command).with('checkout', 'main')
        command.call('main', detach: false)
      end

      it 'works with :d alias' do
        expect(execution_context).to receive(:command).with('checkout', '--detach', 'main')
        command.call('main', d: true)
      end
    end

    context 'with :new_branch option (creates and switches to new branch)' do
      it 'adds -b flag with branch name' do
        expect(execution_context).to receive(:command).with('checkout', '-b', 'feature-branch')
        command.call(new_branch: 'feature-branch')
      end

      it 'adds start_point after -b branch' do
        expect(execution_context).to receive(:command).with('checkout', '-b', 'feature-branch', 'main')
        command.call('main', new_branch: 'feature-branch')
      end

      it 'works with :b alias' do
        expect(execution_context).to receive(:command).with('checkout', '-b', 'feature-branch')
        command.call(b: 'feature-branch')
      end
    end

    context 'with :new_branch_force option (creates/resets and switches)' do
      it 'adds -B flag with branch name' do
        expect(execution_context).to receive(:command).with('checkout', '-B', 'feature-branch')
        command.call(new_branch_force: 'feature-branch')
      end

      it 'adds start_point after -B branch' do
        expect(execution_context).to receive(:command).with('checkout', '-B', 'feature-branch', 'main')
        command.call('main', new_branch_force: 'feature-branch')
      end

      it 'works with :B alias' do
        expect(execution_context).to receive(:command).with('checkout', '-B', 'feature-branch')
        command.call(B: 'feature-branch')
      end
    end

    context 'with :orphan option' do
      it 'adds --orphan flag with branch name' do
        expect(execution_context).to receive(:command).with('checkout', '--orphan', 'gh-pages')
        command.call(orphan: 'gh-pages')
      end

      it 'adds start_point after --orphan branch' do
        expect(execution_context).to receive(:command).with('checkout', '--orphan', 'gh-pages', 'main')
        command.call('main', orphan: 'gh-pages')
      end
    end

    context 'with :track option' do
      context 'when true' do
        it 'adds --track flag' do
          expect(execution_context).to receive(:command).with('checkout', '--track', 'origin/feature')
          command.call('origin/feature', track: true)
        end
      end

      context 'when false' do
        it 'adds --no-track flag' do
          expect(execution_context).to receive(:command).with('checkout', '--no-track', 'origin/feature')
          command.call('origin/feature', track: false)
        end
      end

      context 'when "direct"' do
        it 'adds --track=direct flag' do
          expect(execution_context).to receive(:command).with('checkout', '--track=direct', 'origin/feature')
          command.call('origin/feature', track: 'direct')
        end
      end

      context 'when "inherit"' do
        it 'adds --track=inherit flag' do
          expect(execution_context).to receive(:command).with('checkout', '--track=inherit', 'origin/feature')
          command.call('origin/feature', track: 'inherit')
        end
      end

      it 'works with -b to set upstream' do
        expect(execution_context).to receive(:command).with(
          'checkout', '-b', 'feature', '--track', 'origin/feature'
        )
        command.call('origin/feature', new_branch: 'feature', track: true)
      end
    end

    context 'with :guess option' do
      context 'when true' do
        it 'adds --guess flag' do
          expect(execution_context).to receive(:command).with('checkout', '--guess', 'feature')
          command.call('feature', guess: true)
        end
      end

      context 'when false' do
        it 'adds --no-guess flag' do
          expect(execution_context).to receive(:command).with('checkout', '--no-guess', 'feature')
          command.call('feature', guess: false)
        end
      end
    end

    context 'with :ignore_other_worktrees option' do
      it 'adds --ignore-other-worktrees flag' do
        expect(execution_context).to receive(:command).with('checkout', '--ignore-other-worktrees', 'main')
        command.call('main', ignore_other_worktrees: true)
      end

      it 'does not add flag when false' do
        expect(execution_context).to receive(:command).with('checkout', 'main')
        command.call('main', ignore_other_worktrees: false)
      end
    end

    context 'with :recurse_submodules option' do
      context 'when true' do
        it 'adds --recurse-submodules flag' do
          expect(execution_context).to receive(:command).with('checkout', '--recurse-submodules', 'main')
          command.call('main', recurse_submodules: true)
        end
      end

      context 'when false' do
        it 'adds --no-recurse-submodules flag' do
          expect(execution_context).to receive(:command).with('checkout', '--no-recurse-submodules', 'main')
          command.call('main', recurse_submodules: false)
        end
      end
    end

    context 'with multiple options combined' do
      it 'includes all specified flags in correct order' do
        expect(execution_context).to receive(:command).with(
          'checkout',
          '--force',
          '-b', 'feature',
          '--track',
          'origin/main'
        )
        command.call('origin/main', force: true, new_branch: 'feature', track: true)
      end

      it 'combines detach with force' do
        expect(execution_context).to receive(:command).with(
          'checkout',
          '--force',
          '--detach',
          'abc123'
        )
        command.call('abc123', force: true, detach: true)
      end
    end

    context 'with nil branch' do
      it 'omits the branch from the command' do
        expect(execution_context).to receive(:command).with('checkout')
        command.call(nil)
      end

      it 'allows creating a branch with -b and no start point' do
        expect(execution_context).to receive(:command).with('checkout', '-b', 'new-feature')
        command.call(nil, new_branch: 'new-feature')
      end
    end
  end
end
