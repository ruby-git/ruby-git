# frozen_string_literal: true

require 'git/commands/arguments'
require 'git/commands/branch/list'

module Git
  module Commands
    module Branch
      # Implements the `git branch --copy` command for copying branches
      #
      # This command copies a branch, together with its config and reflog.
      # If the old branch name is omitted, copies the current branch.
      #
      # @see https://git-scm.com/docs/git-branch git-branch
      #
      # @api private
      #
      # @example Copy the current branch
      #   copy = Git::Commands::Branch::Copy.new(execution_context)
      #   copy.call('new-branch-name')
      #
      # @example Copy a specific branch
      #   copy = Git::Commands::Branch::Copy.new(execution_context)
      #   copy.call('old-branch-name', 'new-branch-name')
      #
      # @example Force copy (overwrite existing branch)
      #   copy = Git::Commands::Branch::Copy.new(execution_context)
      #   copy.call('old-branch', 'existing-branch', force: true)
      #
      class Copy
        # Arguments DSL for building command-line arguments
        #
        # NOTE: The positional arguments follow Ruby semantics:
        # - When one positional is provided, it fills new_branch (required)
        # - When two positionals are provided, they fill old_branch and new_branch
        #
        # This matches the git CLI: `git branch -c [<old-branch>] <new-branch>`
        #
        ARGS = Arguments.define do
          static 'branch'
          static '--copy'
          flag %i[force f]
          positional :old_branch
          positional :new_branch, required: true
        end.freeze

        # Initialize the Copy command
        #
        # @param execution_context [Git::ExecutionContext, Git::Lib] the context for executing git commands
        #
        def initialize(execution_context)
          @execution_context = execution_context
        end

        # Execute the git branch --copy command to copy a branch
        #
        # @overload call(new_branch, **options)
        #
        #   Copies the current branch to the new_branch
        #
        #   @param new_branch [String] the new name for the copied branch
        #
        #   @param options [Hash] command options
        #
        #   @option options [Boolean] :force (nil) Allow copying even if new_branch already exists
        #
        # @overload call(old_branch, new_branch, **options)
        #
        #   Copies old_branch to new_branch
        #
        #   @param old_branch [String] branch to copy from
        #
        #   @param new_branch [String] the new name for the copied branch
        #
        #   @param options [Hash] command options
        #
        #   @option options [Boolean] :force (nil) Allow copying even if new_branch already exists
        #
        # @return [Git::BranchInfo] the info for the branch that was created
        #
        # @raise [ArgumentError] if unsupported options are provided
        # @raise [Git::FailedError] if the branch doesn't exist or target exists (without force)
        #
        def call(*positionals, **)
          args = ARGS.build(*positionals, **)
          @execution_context.command(*args)

          # Get branch info for the newly created branch (always the last positional)
          new_branch_name = positionals.last
          Git::Commands::Branch::List.new(@execution_context).call(new_branch_name).first
        end
      end
    end
  end
end
