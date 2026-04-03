# frozen_string_literal: true

require 'git/commands/worktree/management_base'

module Git
  module Commands
    module Worktree
      # Removes a linked worktree
      #
      # @example Remove a clean worktree
      #   Git::Commands::Worktree::Remove.new(execution_context).call('/tmp/feature')
      #
      # @example Force-remove an unclean worktree
      #   Git::Commands::Worktree::Remove.new(execution_context).call('/tmp/feature', force: true)
      #
      # @see Git::Commands::Worktree Git::Commands::Worktree for the full sub-command list
      #
      # @see https://git-scm.com/docs/git-worktree git-worktree documentation
      #
      # @api private
      #
      class Remove < ManagementBase
        arguments do
          literal 'worktree'
          literal 'remove'
          flag_option %i[force f]
          end_of_options
          operand :worktree, required: true
        end

        # @!method call(*, **)
        #
        #   @overload call(worktree, **options)
        #
        #     Remove a linked worktree
        #
        #     @param worktree [String] path or unique suffix identifying the worktree to remove
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean] :force (nil) remove even if the worktree has uncommitted changes
        #
        #       Note: removing locked worktrees (requires `--force` twice) is not yet supported.
        #       See {https://github.com/ruby-git/ruby-git/issues/1178 issue #1178}.
        #
        #       Alias: :f
        #
        #     @return [Git::CommandLineResult] the result of calling `git worktree remove`
        #
        #     @raise [Git::FailedError] if git exits with a non-zero status
      end
    end
  end
end
