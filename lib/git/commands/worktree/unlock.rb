# frozen_string_literal: true

require 'git/commands/worktree/management_base'

module Git
  module Commands
    module Worktree
      # Unlocks a worktree, allowing it to be pruned, moved, or deleted
      #
      # @example Unlock a worktree
      #   Git::Commands::Worktree::Unlock.new(execution_context).call('/tmp/feature')
      #
      # @note `arguments` block audited against https://git-scm.com/docs/git-worktree/2.53.0
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
        #     Unlock a worktree, allowing it to be pruned, moved, or deleted
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
