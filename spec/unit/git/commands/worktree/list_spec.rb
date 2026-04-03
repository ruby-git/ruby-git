# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/worktree/list'

RSpec.describe Git::Commands::Worktree::List do
  # Duck-type collaborator: command specs depend on the #command_capturing interface,
  # not a single concrete ExecutionContext class.
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with no options' do
      it 'runs worktree list with no flags' do
        expected_result = command_result("/repo  abc1234 [main]\n")
        expect_command_capturing('worktree', 'list').and_return(expected_result)

        result = command.call

        expect(result).to eq(expected_result)
      end
    end

    context 'with :porcelain option' do
      it 'includes the --porcelain flag' do
        expect_command_capturing('worktree', 'list', '--porcelain')
          .and_return(command_result("worktree /repo\nHEAD abc1234\nbranch refs/heads/main\n\n"))

        command.call(porcelain: true)
      end
    end
  end
end
