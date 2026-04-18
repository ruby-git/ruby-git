# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/worktree/move'

RSpec.describe Git::Commands::Worktree::Move do
  # Duck-type collaborator: command specs depend on the #command_capturing interface,
  # not a single concrete ExecutionContext class.
  let(:execution_context) { execution_context_double }
  let(:command) { described_class.new(execution_context) }
  let(:worktree_env) { { 'GIT_INDEX_FILE' => nil } }

  describe '#call' do
    context 'with worktree and new path' do
      it 'runs worktree move with both paths' do
        expected_result = command_result('')
        expect_command_capturing('worktree', 'move', '--', '/tmp/old', '/tmp/new', env: worktree_env)
          .and_return(expected_result)

        result = command.call('/tmp/old', '/tmp/new')

        expect(result).to eq(expected_result)
      end
    end

    context 'with :force option' do
      it 'adds --force flag' do
        expect_command_capturing('worktree', 'move', '--force', '--', '/tmp/old', '/tmp/new', env: worktree_env)
          .and_return(command_result(''))

        command.call('/tmp/old', '/tmp/new', force: true)
      end

      it 'accepts :f alias' do
        expect_command_capturing('worktree', 'move', '--force', '--', '/tmp/old', '/tmp/new', env: worktree_env)
          .and_return(command_result(''))

        command.call('/tmp/old', '/tmp/new', f: true)
      end

      it 'emits --force twice when force: 2' do
        expect_command_capturing(
          'worktree', 'move', '--force', '--force', '--', '/tmp/old', '/tmp/new', env: worktree_env
        ).and_return(command_result(''))

        command.call('/tmp/old', '/tmp/new', force: 2)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError for unsupported options' do
        expect { command.call('/tmp/old', '/tmp/new', invalid: true) }
          .to raise_error(ArgumentError, /Unsupported options/)
      end
    end
  end
end
