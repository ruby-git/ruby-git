# frozen_string_literal: true

require 'git/commands/worktree/management_base'

module Git
  module Commands
    module Worktree
      # Unlocks a worktree so it can be pruned
      #
      # @example Unlock a worktree
      #   Git::Commands::Worktree::Unlock.new(execution_context).call('/tmp/feature')
      #
      # @see Git::Commands::Worktree Git::Commands::Worktree for the full sub-command list
      #
      # @see https://git-scm.com/docs/git-worktree git-worktree documentation
      #
      # @api private
      #
      class Unlock < ManagementBase
        arguments do
          literal 'worktree'
          literal 'unlock'
          end_of_options
          operand :worktree, required: true
        end

        # @!method call(*, **)
        #
        #   @overload call(worktree)
        #
        #     Unlock a worktree so it can be pruned
        #
        #     @param worktree [String] path or unique suffix identifying the worktree
        #       to unlock
        #
        #     @return [Git::CommandLineResult] the result of calling `git worktree unlock`
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
      end
    end
  end
end
