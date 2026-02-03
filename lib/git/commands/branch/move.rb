# frozen_string_literal: true

require 'git/commands/arguments'
require 'git/commands/branch/list'

module Git
  module Commands
    module Branch
      # Implements the `git branch --move` command for renaming branches
      #
      # This command moves/renames a branch, together with its config and reflog.
      # If the old branch name is omitted, renames the current branch.
      #
      # @see https://git-scm.com/docs/git-branch git-branch
      #
      # @api private
      #
      # @example Rename the current branch
      #   move = Git::Commands::Branch::Move.new(execution_context)
      #   move.call('new-branch-name')
      #
      # @example Rename a specific branch
      #   move = Git::Commands::Branch::Move.new(execution_context)
      #   move.call('old-branch-name', 'new-branch-name')
      #
      # @example Force rename (overwrite existing branch)
      #   move = Git::Commands::Branch::Move.new(execution_context)
      #   move.call('old-branch', 'existing-branch', force: true)
      #
      class Move
        # Arguments DSL for building command-line arguments
        #
        # NOTE: The positional arguments follow Ruby semantics:
        # - When one positional is provided, it fills new_branch (required)
        # - When two positionals are provided, they fill old_branch and new_branch
        #
        # This matches the git CLI: `git branch -m [<old-branch>] <new-branch>`
        #
        ARGS = Arguments.define do
          static 'branch'
          static '--move'
          flag %i[force f]
          positional :old_branch
          positional :new_branch, required: true
        end.freeze

        # Initialize the Move command
        #
        # @param execution_context [Git::ExecutionContext, Git::Lib] the context for executing git commands
        #
        def initialize(execution_context)
          @execution_context = execution_context
        end

        # Execute the git branch --move command to rename a branch
        #
        # @overload call(new_branch, **options)
        #
        #   Rename the current branch to new_branch
        #
        #   @param new_branch [String] the new name for the branch
        #
        #   @param options [Hash] command options
        #
        #   @option options [Boolean] :force (nil) Allow renaming even if new_branch already exists
        #
        # @overload call(old_branch, new_branch, **options)
        #
        #   Rename old_branch to new_branch
        #
        #   @param old_branch [String] the current name of the branch
        #
        #   @param new_branch [String] the new name for the branch
        #
        #   @param options [Hash] command options
        #
        #   @option options [Boolean] :force (nil) Allow renaming even if new_branch already exists
        #
        # @return [Git::BranchInfo] the info for the renamed branch
        #
        # @raise [ArgumentError] if unsupported options are provided
        # @raise [Git::FailedError] if the branch doesn't exist or target exists (without force)
        #
        def call(*, **)
          args = ARGS.bind(*, **)

          @execution_context.command(*args)

          # Get branch info for the renamed branch (always the last positional)
          Git::Commands::Branch::List.new(@execution_context).call(args.new_branch).first
        end
      end
    end
  end
end
