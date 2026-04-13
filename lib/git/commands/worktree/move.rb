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
          flag_option %i[force f], max_times: 2
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
        #     @option options [Boolean, Integer] :force (nil) allow moving a locked worktree
        #
        #       Pass `true` or `1` to emit `--force` once. Pass `2` to emit
        #       `--force --force`, which also handles locked or missing destinations.
        #
        #       Alias: :f
        #
        #     @return [Git::CommandLineResult] the result of calling `git worktree move`
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
      end
    end
  end
end
