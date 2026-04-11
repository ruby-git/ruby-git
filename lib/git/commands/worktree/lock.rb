# frozen_string_literal: true

require 'git/commands/worktree/management_base'

module Git
  module Commands
    module Worktree
      # Locks a worktree to prevent it from being pruned
      #
      # @example Lock a worktree
      #   Git::Commands::Worktree::Lock.new(execution_context).call('/tmp/feature')
      #
      # @example Lock with a reason message
      #   Git::Commands::Worktree::Lock.new(execution_context).call('/tmp/feature', reason: 'on NFS share')
      #
      # @note `arguments` block audited against https://git-scm.com/docs/git-worktree/2.53.0
      #
      # @see Git::Commands::Worktree Git::Commands::Worktree for the full sub-command list
      #
      # @see https://git-scm.com/docs/git-worktree git-worktree documentation
      #
      # @api private
      #
      class Lock < ManagementBase
        arguments do
          literal 'worktree'
          literal 'lock'
          value_option :reason # --reason
          end_of_options
          operand :worktree, required: true
        end

        # @!method call(*, **)
        #
        #   @overload call(worktree, **options)
        #
        #     Lock a worktree to prevent it from being pruned
        #
        #     @param worktree [String] path or unique suffix identifying the worktree to lock
        #
        #     @param options [Hash] command options
        #
        #     @option options [String] :reason (nil) human-readable explanation stored alongside the lock
        #
        #     @return [Git::CommandLineResult] the result of calling `git worktree lock`
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
      end
    end
  end
end
