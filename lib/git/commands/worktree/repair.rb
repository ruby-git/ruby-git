# frozen_string_literal: true

require 'git/commands/worktree/management_base'

module Git
  module Commands
    module Worktree
      # Repairs worktree administrative files
      #
      # Resolves broken links between the repository and one or more linked
      # worktrees. Useful after a worktree directory is moved manually.
      #
      # @example Repair all registered worktrees
      #   Git::Commands::Worktree::Repair.new(execution_context).call
      #
      # @example Repair specific moved worktrees
      #   Git::Commands::Worktree::Repair.new(execution_context).call('/tmp/moved1', '/tmp/moved2')
      #
      # @see Git::Commands::Worktree Git::Commands::Worktree for the full sub-command list
      # @see https://git-scm.com/docs/git-worktree git-worktree documentation
      #
      # @api private
      #
      class Repair < ManagementBase
        arguments do
          literal 'worktree'
          literal 'repair'
          end_of_options
          operand :path, repeatable: true
        end

        # @!method call(*, **)
        #
        #   @overload call(*path)
        #
        #     Repair worktree administrative files
        #
        #     @param path [Array<String>] paths to specific worktrees to repair
        #
        #       When omitted, all registered worktrees are repaired.
        #
        #     @return [Git::CommandLineResult] the result of calling `git worktree repair`
        #
        #     @raise [Git::FailedError] if git exits with a non-zero status
      end
    end
  end
end
