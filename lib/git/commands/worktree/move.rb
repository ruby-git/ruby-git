# frozen_string_literal: true

require 'git/commands/worktree/management_base'

module Git
  module Commands
    module Worktree
      # Moves a linked worktree to a new filesystem location
      #
      # @example Move a worktree to a new path
      #   Git::Commands::Worktree::Move.new(execution_context).call('/tmp/old', '/tmp/new')
      #
      # @example Force-move a locked worktree
      #   Git::Commands::Worktree::Move.new(execution_context).call('/tmp/feat', '/tmp/feat2', force: true)
      #
      # @see Git::Commands::Worktree Git::Commands::Worktree for the full sub-command list
      #
      # @see https://git-scm.com/docs/git-worktree git-worktree documentation
      #
      # @api private
      #
      class Move < ManagementBase
        arguments do
          literal 'worktree'
          literal 'move'
          flag_option %i[force f]
          end_of_options
          operand :worktree, required: true
          operand :new_path, required: true
        end

        # @!method call(*, **)
        #
        #   @overload call(worktree, new_path, **options)
        #
        #     Move a linked worktree to a new filesystem location
        #
        #     @param worktree [String] path or unique suffix identifying the worktree to move
        #
        #     @param new_path [String] destination path for the worktree
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean] :force (nil) allow moving a locked worktree
        #
        #       Note: force-moving when the destination is also locked or missing (requires
        #       `--force` twice) is not yet supported.
        #       See {https://github.com/ruby-git/ruby-git/issues/1178 issue #1178}.
        #
        #       Alias: :f
        #
        #     @return [Git::CommandLineResult] the result of calling `git worktree move`
        #
        #     @raise [Git::FailedError] if git exits with a non-zero status
      end
    end
  end
end
