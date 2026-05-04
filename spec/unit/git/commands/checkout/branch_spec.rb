# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/checkout/branch'

RSpec.describe Git::Commands::Checkout::Branch do
  let(:execution_context) { execution_context_double }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with no arguments' do
      it 'calls git checkout with no arguments' do
        expected_result = command_result
        expect_command_capturing('checkout').and_return(expected_result)

        result = command.call

        expect(result).to eq(expected_result)
      end
    end

    context 'with branch name only' do
      it 'calls git checkout with the branch name' do
        expect_command_capturing('checkout', 'main').and_return(command_result)
        command.call('main')
      end

      it 'accepts a commit SHA' do
        expect_command_capturing('checkout', 'abc123').and_return(command_result)
        command.call('abc123')
      end

      it 'accepts a remote branch' do
        expect_command_capturing('checkout', 'origin/main').and_return(command_result)
        command.call('origin/main')
      end
    end

    context 'with :quiet option' do
      it 'adds --quiet flag' do
        expect_command_capturing('checkout', '--quiet', 'main').and_return(command_result)
        command.call('main', quiet: true)
      end

      it 'does not add flag when false' do
        expect_command_capturing('checkout', 'main').and_return(command_result)
        command.call('main', quiet: false)
      end

      it 'works with :q alias' do
        expect_command_capturing('checkout', '--quiet', 'main').and_return(command_result)
        command.call('main', q: true)
      end
    end

    context 'with :progress option' do
      it 'adds --progress flag' do
        expect_command_capturing('checkout', '--progress', 'main').and_return(command_result)
        command.call('main', progress: true)
      end

      context 'when :no_progress is true' do
        it 'adds --no-progress flag' do
          expect_command_capturing('checkout', '--no-progress', 'main').and_return(command_result)
          command.call('main', no_progress: true)
        end
      end
    end

    context 'with :force option' do
      it 'adds --force flag' do
        expect_command_capturing('checkout', '--force', 'main').and_return(command_result)
        command.call('main', force: true)
      end

      it 'does not add flag when false' do
        expect_command_capturing('checkout', 'main').and_return(command_result)
        command.call('main', force: false)
      end

      it 'works with :f alias' do
        expect_command_capturing('checkout', '--force', 'main').and_return(command_result)
        command.call('main', f: true)
      end
    end

    context 'with :merge option' do
      it 'adds --merge flag' do
        expect_command_capturing('checkout', '--merge', 'main').and_return(command_result)
        command.call('main', merge: true)
      end

      it 'does not add flag when false' do
        expect_command_capturing('checkout', 'main').and_return(command_result)
        command.call('main', merge: false)
      end

      it 'works with :m alias' do
        expect_command_capturing('checkout', '--merge', 'main').and_return(command_result)
        command.call('main', m: true)
      end
    end

    context 'with :detach option' do
      it 'adds --detach flag' do
        expect_command_capturing('checkout', '--detach', 'main').and_return(command_result)
        command.call('main', detach: true)
      end

      it 'does not add flag when false' do
        expect_command_capturing('checkout', 'main').and_return(command_result)
        command.call('main', detach: false)
      end

      it 'works with :d alias' do
        expect_command_capturing('checkout', '--detach', 'main').and_return(command_result)
        command.call('main', d: true)
      end
    end

    context 'with :b option (creates and switches to new branch)' do
      it 'adds -b flag with branch name' do
        expect_command_capturing('checkout', '-b', 'feature-branch').and_return(command_result)
        command.call(b: 'feature-branch')
      end

      it 'adds start_point after -b branch' do
        expect_command_capturing('checkout', '-b', 'feature-branch', 'main').and_return(command_result)
        command.call('main', b: 'feature-branch')
      end
    end

    context "with :'B' option (creates/resets and switches)" do
      it 'adds -B flag with branch name' do
        expect_command_capturing('checkout', '-B', 'feature-branch').and_return(command_result)
        command.call(B: 'feature-branch')
      end

      it 'adds start_point after -B branch' do
        expect_command_capturing('checkout', '-B', 'feature-branch', 'main').and_return(command_result)
        command.call('main', B: 'feature-branch')
      end
    end

    context 'with :orphan option' do
      it 'adds --orphan flag with branch name' do
        expect_command_capturing('checkout', '--orphan', 'gh-pages').and_return(command_result)
        command.call(orphan: 'gh-pages')
      end

      it 'adds start_point after --orphan branch' do
        expect_command_capturing('checkout', '--orphan', 'gh-pages', 'main').and_return(command_result)
        command.call('main', orphan: 'gh-pages')
      end
    end

    context 'with :track option' do
      context 'when true' do
        it 'adds --track flag' do
          expect_command_capturing('checkout', '--track', 'origin/feature').and_return(command_result)
          command.call('origin/feature', track: true)
        end
      end

      context 'when false' do
        it 'adds --no-track flag' do
          expect_command_capturing('checkout', '--no-track', 'origin/feature').and_return(command_result)
          command.call('origin/feature', no_track: true)
        end
      end

      context 'when "direct"' do
        it 'adds --track=direct flag' do
          expect_command_capturing('checkout', '--track=direct', 'origin/feature').and_return(command_result)
          command.call('origin/feature', track: 'direct')
        end
      end

      context 'when "inherit"' do
        it 'adds --track=inherit flag' do
          expect_command_capturing('checkout', '--track=inherit', 'origin/feature').and_return(command_result)
          command.call('origin/feature', track: 'inherit')
        end
      end

      it 'works with -b to set upstream' do
        expect_command_capturing('checkout', '-b', 'feature', '--track', 'origin/feature').and_return(command_result)
        command.call('origin/feature', b: 'feature', track: true)
      end
    end

    context 'with :guess option' do
      context 'when true' do
        it 'adds --guess flag' do
          expect_command_capturing('checkout', '--guess', 'feature').and_return(command_result)
          command.call('feature', guess: true)
        end
      end

      context 'when false' do
        it 'adds --no-guess flag' do
          expect_command_capturing('checkout', '--no-guess', 'feature').and_return(command_result)
          command.call('feature', no_guess: true)
        end
      end
    end

    context 'with :l option (create reflog)' do
      it 'adds -l flag' do
        expect_command_capturing('checkout', '-b', 'new-branch', '-l').and_return(command_result)
        command.call(l: true, b: 'new-branch')
      end

      it 'does not add flag when false' do
        expect_command_capturing('checkout', '-b', 'new-branch').and_return(command_result)
        command.call(b: 'new-branch', l: false)
      end
    end

    context 'with :ignore_other_worktrees option' do
      it 'adds --ignore-other-worktrees flag' do
        expect_command_capturing('checkout', '--ignore-other-worktrees', 'main').and_return(command_result)
        command.call('main', ignore_other_worktrees: true)
      end

      it 'does not add flag when false' do
        expect_command_capturing('checkout', 'main').and_return(command_result)
        command.call('main', ignore_other_worktrees: false)
      end
    end

    context 'with :recurse_submodules option' do
      context 'when true' do
        it 'adds --recurse-submodules flag' do
          expect_command_capturing('checkout', '--recurse-submodules', 'main').and_return(command_result)
          command.call('main', recurse_submodules: true)
        end
      end

      context 'when :no_recurse_submodules is true' do
        it 'adds --no-recurse-submodules flag' do
          expect_command_capturing('checkout', '--no-recurse-submodules', 'main').and_return(command_result)
          command.call('main', no_recurse_submodules: true)
        end
      end
    end

    context 'with :overwrite_ignore option' do
      it 'adds --overwrite-ignore flag' do
        expect_command_capturing('checkout', '--overwrite-ignore', 'main').and_return(command_result)
        command.call('main', overwrite_ignore: true)
      end

      context 'when :no_overwrite_ignore is true' do
        it 'adds --no-overwrite-ignore flag' do
          expect_command_capturing('checkout', '--no-overwrite-ignore', 'main').and_return(command_result)
          command.call('main', no_overwrite_ignore: true)
        end
      end
    end

    context 'with multiple options combined' do
      it 'includes all specified flags in correct order' do
        expect_command_capturing('checkout',
                                 '--force',
                                 '-b', 'feature',
                                 '--track',
                                 'origin/main').and_return(command_result)
        command.call('origin/main', force: true, b: 'feature', track: true)
      end

      it 'combines detach with force' do
        expect_command_capturing('checkout',
                                 '--force',
                                 '--detach',
                                 'abc123').and_return(command_result)
        command.call('abc123', force: true, detach: true)
      end
    end

    context 'with nil branch' do
      it 'omits the branch from the command' do
        expect_command_capturing('checkout').and_return(command_result)
        command.call(nil)
      end

      it 'allows creating a branch with -b and no start point' do
        expect_command_capturing('checkout', '-b', 'new-feature').and_return(command_result)
        command.call(nil, b: 'new-feature')
      end
    end

    context 'with :chdir execution option' do
      it 'passes chdir to the execution context, not to the CLI' do
        expect(execution_context).to receive(:command_capturing)
          .with('checkout', 'main', chdir: '/tmp', raise_on_failure: false)
          .and_return(command_result)

        command.call('main', chdir: '/tmp')
      end
    end
  end
end
