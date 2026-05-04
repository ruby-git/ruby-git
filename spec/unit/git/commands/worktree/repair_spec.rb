# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/worktree/repair'

RSpec.describe Git::Commands::Worktree::Repair do
  # Duck-type collaborator: command specs depend on the #command_capturing interface,
  # not a single concrete ExecutionContext class.
  let(:execution_context) { execution_context_double }
  let(:command) { described_class.new(execution_context) }
  let(:worktree_env) { { 'GIT_INDEX_FILE' => nil } }

  describe '#call' do
    context 'with no arguments' do
      it 'runs worktree repair with no operands' do
        expected_result = command_result('')
        expect_command_capturing('worktree', 'repair', env: worktree_env)
          .and_return(expected_result)

        result = command.call

        expect(result).to eq(expected_result)
      end
    end

    context 'with specific paths' do
      it 'passes each path as an operand' do
        expect_command_capturing('worktree', 'repair', '--', '/tmp/moved1', env: worktree_env)
          .and_return(command_result(''))

        command.call('/tmp/moved1')
      end

      it 'passes multiple paths' do
        expect_command_capturing('worktree', 'repair', '--', '/tmp/moved1', '/tmp/moved2', env: worktree_env)
          .and_return(command_result(''))

        command.call('/tmp/moved1', '/tmp/moved2')
      end
    end

    context 'with :relative_paths option' do
      context 'when true' do
        it 'adds --relative-paths flag' do
          expect_command_capturing('worktree', 'repair', '--relative-paths', env: worktree_env)
            .and_return(command_result(''))

          command.call(relative_paths: true)
        end
      end

      context 'when :no_relative_paths is true' do
        it 'adds --no-relative-paths flag' do
          expect_command_capturing('worktree', 'repair', '--no-relative-paths', env: worktree_env)
            .and_return(command_result(''))

          command.call(no_relative_paths: true)
        end
      end

      it 'combines --relative-paths with a path operand' do
        expect_command_capturing('worktree', 'repair', '--relative-paths', '--', '/tmp/moved1', env: worktree_env)
          .and_return(command_result(''))

        command.call('/tmp/moved1', relative_paths: true)
      end
    end
  end
end
