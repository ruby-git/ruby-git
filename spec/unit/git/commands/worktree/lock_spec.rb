# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/worktree/lock'

RSpec.describe Git::Commands::Worktree::Lock do
  # Duck-type collaborator: command specs depend on the #command_capturing interface,
  # not a single concrete ExecutionContext class.
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }
  let(:worktree_env) { { 'GIT_INDEX_FILE' => nil } }

  describe '#call' do
    context 'with worktree path only' do
      it 'runs worktree lock with the path' do
        expected_result = command_result('')
        expect_command_capturing('worktree', 'lock', '--', '/tmp/feature', env: worktree_env)
          .and_return(expected_result)

        result = command.call('/tmp/feature')

        expect(result).to eq(expected_result)
      end
    end

    context 'with :reason option' do
      it 'adds --reason with value' do
        expect_command_capturing(
          'worktree', 'lock', '--reason', 'on NFS share', '--', '/tmp/feature', env: worktree_env
        ).and_return(command_result(''))

        command.call('/tmp/feature', reason: 'on NFS share')
      end
    end
  end
end
