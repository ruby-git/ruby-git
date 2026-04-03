# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/worktree/unlock'

RSpec.describe Git::Commands::Worktree::Unlock do
  # Duck-type collaborator: command specs depend on the #command_capturing interface,
  # not a single concrete ExecutionContext class.
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }
  let(:worktree_env) { { 'GIT_INDEX_FILE' => nil } }

  describe '#call' do
    context 'with worktree path' do
      it 'runs worktree unlock with the path' do
        expected_result = command_result('')
        expect_command_capturing('worktree', 'unlock', '--', '/tmp/feature', env: worktree_env)
          .and_return(expected_result)

        result = command.call('/tmp/feature')

        expect(result).to eq(expected_result)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError when no worktree is provided' do
        expect { command.call }
          .to raise_error(ArgumentError, /worktree is required/)
      end

      it 'raises ArgumentError for unsupported options' do
        expect { command.call('/tmp/feature', foo: true) }
          .to raise_error(ArgumentError, /Unsupported options/)
      end
    end
  end
end
