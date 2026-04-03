# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/worktree/prune'

RSpec.describe Git::Commands::Worktree::Prune do
  # Duck-type collaborator: command specs depend on the #command_capturing interface,
  # not a single concrete ExecutionContext class.
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }
  let(:worktree_env) { { 'GIT_INDEX_FILE' => nil } }

  describe '#call' do
    context 'with no options' do
      it 'runs worktree prune with no flags' do
        expected_result = command_result('')
        expect_command_capturing('worktree', 'prune', env: worktree_env)
          .and_return(expected_result)

        result = command.call

        expect(result).to eq(expected_result)
      end
    end

    context 'with :dry_run option' do
      it 'adds --dry-run flag' do
        expect_command_capturing('worktree', 'prune', '--dry-run', env: worktree_env)
          .and_return(command_result(''))

        command.call(dry_run: true)
      end

      it 'accepts :n alias' do
        expect_command_capturing('worktree', 'prune', '--dry-run', env: worktree_env)
          .and_return(command_result(''))

        command.call(n: true)
      end
    end

    context 'with :verbose option' do
      it 'adds --verbose flag' do
        expect_command_capturing('worktree', 'prune', '--verbose', env: worktree_env)
          .and_return(command_result(''))

        command.call(verbose: true)
      end

      it 'accepts :v alias' do
        expect_command_capturing('worktree', 'prune', '--verbose', env: worktree_env)
          .and_return(command_result(''))

        command.call(v: true)
      end
    end

    context 'with :expire option' do
      it 'adds --expire with value' do
        expect_command_capturing('worktree', 'prune', '--expire', '2.weeks.ago', env: worktree_env)
          .and_return(command_result(''))

        command.call(expire: '2.weeks.ago')
      end
    end

    context 'with multiple options' do
      it 'includes all specified flags in correct order' do
        expect_command_capturing('worktree', 'prune', '--dry-run', '--verbose', env: worktree_env)
          .and_return(command_result(''))

        command.call(dry_run: true, verbose: true)
      end
    end
  end
end
