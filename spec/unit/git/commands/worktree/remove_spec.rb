# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/worktree/remove'

RSpec.describe Git::Commands::Worktree::Remove do
  # Duck-type collaborator: command specs depend on the #command_capturing interface,
  # not a single concrete ExecutionContext class.
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }
  let(:worktree_env) { { 'GIT_INDEX_FILE' => nil } }

  describe '#call' do
    context 'with worktree path' do
      it 'runs worktree remove with the path' do
        expected_result = command_result('')
        expect_command_capturing('worktree', 'remove', '--', '/tmp/feature', env: worktree_env)
          .and_return(expected_result)

        result = command.call('/tmp/feature')

        expect(result).to eq(expected_result)
      end
    end

    context 'with :force option' do
      it 'adds --force flag' do
        expect_command_capturing('worktree', 'remove', '--force', '--', '/tmp/feature', env: worktree_env)
          .and_return(command_result(''))

        command.call('/tmp/feature', force: true)
      end

      it 'accepts :f alias' do
        expect_command_capturing('worktree', 'remove', '--force', '--', '/tmp/feature', env: worktree_env)
          .and_return(command_result(''))

        command.call('/tmp/feature', f: true)
      end
    end
  end
end
