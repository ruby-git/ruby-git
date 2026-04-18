# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/worktree/add'

RSpec.describe Git::Commands::Worktree::Add do
  # Duck-type collaborator: command specs depend on the #command_capturing interface,
  # not a single concrete ExecutionContext class.
  let(:execution_context) { execution_context_double }
  let(:command) { described_class.new(execution_context) }
  let(:worktree_env) { { 'GIT_INDEX_FILE' => nil } }

  describe '#call' do
    context 'with path only' do
      it 'runs worktree add with the path' do
        expected_result = command_result('')
        expect_command_capturing('worktree', 'add', '--', '/tmp/feature', env: worktree_env)
          .and_return(expected_result)

        result = command.call('/tmp/feature')

        expect(result).to eq(expected_result)
      end
    end

    context 'with path and commit-ish' do
      it 'passes the commit-ish after path' do
        expect_command_capturing('worktree', 'add', '--', '/tmp/hotfix', 'main', env: worktree_env)
          .and_return(command_result(''))

        command.call('/tmp/hotfix', 'main')
      end
    end

    context 'with :force option' do
      it 'adds --force flag' do
        expect_command_capturing('worktree', 'add', '--force', '--', '/tmp/feat', env: worktree_env)
          .and_return(command_result(''))

        command.call('/tmp/feat', force: true)
      end

      it 'accepts :f alias' do
        expect_command_capturing('worktree', 'add', '--force', '--', '/tmp/feat', env: worktree_env)
          .and_return(command_result(''))

        command.call('/tmp/feat', f: true)
      end

      it 'emits --force twice when force: 2' do
        expect_command_capturing('worktree', 'add', '--force', '--force', '--', '/tmp/feat', env: worktree_env)
          .and_return(command_result(''))

        command.call('/tmp/feat', force: 2)
      end
    end

    context 'with :detach option' do
      it 'adds --detach flag' do
        expect_command_capturing('worktree', 'add', '--detach', '--', '/tmp/exp', env: worktree_env)
          .and_return(command_result(''))

        command.call('/tmp/exp', detach: true)
      end

      it 'accepts :d alias' do
        expect_command_capturing('worktree', 'add', '--detach', '--', '/tmp/exp', env: worktree_env)
          .and_return(command_result(''))

        command.call('/tmp/exp', d: true)
      end
    end

    context 'with :checkout option' do
      it 'adds --checkout when true' do
        expect_command_capturing('worktree', 'add', '--checkout', '--', '/tmp/wt', env: worktree_env)
          .and_return(command_result(''))

        command.call('/tmp/wt', checkout: true)
      end

      it 'adds --no-checkout when false' do
        expect_command_capturing('worktree', 'add', '--no-checkout', '--', '/tmp/wt', env: worktree_env)
          .and_return(command_result(''))

        command.call('/tmp/wt', checkout: false)
      end
    end

    context 'with :lock option' do
      it 'adds --lock flag' do
        expect_command_capturing('worktree', 'add', '--lock', '--', '/tmp/wt', env: worktree_env)
          .and_return(command_result(''))

        command.call('/tmp/wt', lock: true)
      end
    end

    context 'with :quiet option' do
      it 'adds --quiet flag' do
        expect_command_capturing('worktree', 'add', '--quiet', '--', '/tmp/wt', env: worktree_env)
          .and_return(command_result(''))

        command.call('/tmp/wt', quiet: true)
      end

      it 'accepts :q alias' do
        expect_command_capturing('worktree', 'add', '--quiet', '--', '/tmp/wt', env: worktree_env)
          .and_return(command_result(''))

        command.call('/tmp/wt', q: true)
      end
    end

    context 'with :b option' do
      it 'adds -b with branch name' do
        expect_command_capturing('worktree', 'add', '-b', 'feature/new', '--', '/tmp/wt', env: worktree_env)
          .and_return(command_result(''))

        command.call('/tmp/wt', b: 'feature/new')
      end
    end

    context 'with :B option' do
      it 'adds -B with branch name' do
        expect_command_capturing('worktree', 'add', '-B', 'feature/new', '--', '/tmp/wt', env: worktree_env)
          .and_return(command_result(''))

        command.call('/tmp/wt', B: 'feature/new')
      end
    end

    context 'with :guess_remote option' do
      it 'adds --guess-remote when true' do
        expect_command_capturing('worktree', 'add', '--guess-remote', '--', '/tmp/wt', env: worktree_env)
          .and_return(command_result(''))

        command.call('/tmp/wt', guess_remote: true)
      end

      it 'adds --no-guess-remote when false' do
        expect_command_capturing('worktree', 'add', '--no-guess-remote', '--', '/tmp/wt', env: worktree_env)
          .and_return(command_result(''))

        command.call('/tmp/wt', guess_remote: false)
      end
    end

    context 'with :track option' do
      it 'adds --track when true' do
        expect_command_capturing('worktree', 'add', '--track', '--', '/tmp/wt', env: worktree_env)
          .and_return(command_result(''))

        command.call('/tmp/wt', track: true)
      end

      it 'adds --no-track when false' do
        expect_command_capturing('worktree', 'add', '--no-track', '--', '/tmp/wt', env: worktree_env)
          .and_return(command_result(''))

        command.call('/tmp/wt', track: false)
      end
    end

    context 'with :relative_paths option' do
      it 'adds --relative-paths when true' do
        expect_command_capturing('worktree', 'add', '--relative-paths', '--', '/tmp/wt', env: worktree_env)
          .and_return(command_result(''))

        command.call('/tmp/wt', relative_paths: true)
      end

      it 'adds --no-relative-paths when false' do
        expect_command_capturing('worktree', 'add', '--no-relative-paths', '--', '/tmp/wt', env: worktree_env)
          .and_return(command_result(''))

        command.call('/tmp/wt', relative_paths: false)
      end
    end

    context 'with :orphan option' do
      it 'adds --orphan flag' do
        expect_command_capturing('worktree', 'add', '--orphan', '--', '/tmp/wt', env: worktree_env)
          .and_return(command_result(''))

        command.call('/tmp/wt', orphan: true)
      end
    end

    context 'with :reason option' do
      it 'adds --lock --reason with value (primary usage)' do
        expect_command_capturing(
          'worktree', 'add', '--lock', '--reason', 'archived', '--', '/tmp/wt', env: worktree_env
        ).and_return(command_result(''))

        command.call('/tmp/wt', lock: true, reason: 'archived')
      end
    end
  end
end
