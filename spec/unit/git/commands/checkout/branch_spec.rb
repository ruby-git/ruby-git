# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/checkout/branch'

RSpec.describe Git::Commands::Checkout::Branch do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with no arguments' do
      it 'calls git checkout with no arguments' do
        expected_result = command_result
        expect_command('checkout').and_return(expected_result)

        result = command.call

        expect(result).to eq(expected_result)
      end
    end

    context 'with branch name only' do
      it 'calls git checkout with the branch name' do
        expect_command('checkout', 'main').and_return(command_result)
        command.call('main')
      end

      it 'accepts a commit SHA' do
        expect_command('checkout', 'abc123').and_return(command_result)
        command.call('abc123')
      end

      it 'accepts a remote branch' do
        expect_command('checkout', 'origin/main').and_return(command_result)
        command.call('origin/main')
      end
    end

    context 'with :force option' do
      it 'adds --force flag' do
        expect_command('checkout', '--force', 'main').and_return(command_result)
        command.call('main', force: true)
      end

      it 'does not add flag when false' do
        expect_command('checkout', 'main').and_return(command_result)
        command.call('main', force: false)
      end

      it 'works with :f alias' do
        expect_command('checkout', '--force', 'main').and_return(command_result)
        command.call('main', f: true)
      end
    end

    context 'with :merge option' do
      it 'adds --merge flag' do
        expect_command('checkout', '--merge', 'main').and_return(command_result)
        command.call('main', merge: true)
      end

      it 'does not add flag when false' do
        expect_command('checkout', 'main').and_return(command_result)
        command.call('main', merge: false)
      end

      it 'works with :m alias' do
        expect_command('checkout', '--merge', 'main').and_return(command_result)
        command.call('main', m: true)
      end
    end

    context 'with :detach option' do
      it 'adds --detach flag' do
        expect_command('checkout', '--detach', 'main').and_return(command_result)
        command.call('main', detach: true)
      end

      it 'does not add flag when false' do
        expect_command('checkout', 'main').and_return(command_result)
        command.call('main', detach: false)
      end

      it 'works with :d alias' do
        expect_command('checkout', '--detach', 'main').and_return(command_result)
        command.call('main', d: true)
      end
    end

    context 'with :new_branch option (creates and switches to new branch)' do
      it 'adds -b flag with branch name' do
        expect_command('checkout', '-b', 'feature-branch').and_return(command_result)
        command.call(new_branch: 'feature-branch')
      end

      it 'adds start_point after -b branch' do
        expect_command('checkout', '-b', 'feature-branch', 'main').and_return(command_result)
        command.call('main', new_branch: 'feature-branch')
      end

      it 'works with :b alias' do
        expect_command('checkout', '-b', 'feature-branch').and_return(command_result)
        command.call(b: 'feature-branch')
      end
    end

    context 'with :new_branch_force option (creates/resets and switches)' do
      it 'adds -B flag with branch name' do
        expect_command('checkout', '-B', 'feature-branch').and_return(command_result)
        command.call(new_branch_force: 'feature-branch')
      end

      it 'adds start_point after -B branch' do
        expect_command('checkout', '-B', 'feature-branch', 'main').and_return(command_result)
        command.call('main', new_branch_force: 'feature-branch')
      end

      it 'works with :B alias' do
        expect_command('checkout', '-B', 'feature-branch').and_return(command_result)
        command.call(B: 'feature-branch')
      end
    end

    context 'with :orphan option' do
      it 'adds --orphan flag with branch name' do
        expect_command('checkout', '--orphan', 'gh-pages').and_return(command_result)
        command.call(orphan: 'gh-pages')
      end

      it 'adds start_point after --orphan branch' do
        expect_command('checkout', '--orphan', 'gh-pages', 'main').and_return(command_result)
        command.call('main', orphan: 'gh-pages')
      end
    end

    context 'with :track option' do
      context 'when true' do
        it 'adds --track flag' do
          expect_command('checkout', '--track', 'origin/feature').and_return(command_result)
          command.call('origin/feature', track: true)
        end
      end

      context 'when false' do
        it 'adds --no-track flag' do
          expect_command('checkout', '--no-track', 'origin/feature').and_return(command_result)
          command.call('origin/feature', track: false)
        end
      end

      context 'when "direct"' do
        it 'adds --track=direct flag' do
          expect_command('checkout', '--track=direct', 'origin/feature').and_return(command_result)
          command.call('origin/feature', track: 'direct')
        end
      end

      context 'when "inherit"' do
        it 'adds --track=inherit flag' do
          expect_command('checkout', '--track=inherit', 'origin/feature').and_return(command_result)
          command.call('origin/feature', track: 'inherit')
        end
      end

      it 'works with -b to set upstream' do
        expect_command('checkout', '-b', 'feature', '--track', 'origin/feature').and_return(command_result)
        command.call('origin/feature', new_branch: 'feature', track: true)
      end
    end

    context 'with :guess option' do
      context 'when true' do
        it 'adds --guess flag' do
          expect_command('checkout', '--guess', 'feature').and_return(command_result)
          command.call('feature', guess: true)
        end
      end

      context 'when false' do
        it 'adds --no-guess flag' do
          expect_command('checkout', '--no-guess', 'feature').and_return(command_result)
          command.call('feature', guess: false)
        end
      end
    end

    context 'with :ignore_other_worktrees option' do
      it 'adds --ignore-other-worktrees flag' do
        expect_command('checkout', '--ignore-other-worktrees', 'main').and_return(command_result)
        command.call('main', ignore_other_worktrees: true)
      end

      it 'does not add flag when false' do
        expect_command('checkout', 'main').and_return(command_result)
        command.call('main', ignore_other_worktrees: false)
      end
    end

    context 'with :recurse_submodules option' do
      context 'when true' do
        it 'adds --recurse-submodules flag' do
          expect_command('checkout', '--recurse-submodules', 'main').and_return(command_result)
          command.call('main', recurse_submodules: true)
        end
      end

      context 'when false' do
        it 'adds --no-recurse-submodules flag' do
          expect_command('checkout', '--no-recurse-submodules', 'main').and_return(command_result)
          command.call('main', recurse_submodules: false)
        end
      end
    end

    context 'with multiple options combined' do
      it 'includes all specified flags in correct order' do
        expect_command('checkout',
                       '--force',
                       '-b', 'feature',
                       '--track',
                       'origin/main').and_return(command_result)
        command.call('origin/main', force: true, new_branch: 'feature', track: true)
      end

      it 'combines detach with force' do
        expect_command('checkout',
                       '--force',
                       '--detach',
                       'abc123').and_return(command_result)
        command.call('abc123', force: true, detach: true)
      end
    end

    context 'with nil branch' do
      it 'omits the branch from the command' do
        expect_command('checkout').and_return(command_result)
        command.call(nil)
      end

      it 'allows creating a branch with -b and no start point' do
        expect_command('checkout', '-b', 'new-feature').and_return(command_result)
        command.call(nil, new_branch: 'new-feature')
      end
    end
  end
end
