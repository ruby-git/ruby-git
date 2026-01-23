# frozen_string_literal: true

require 'git/commands/arguments'

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
          static '--copy'
          flag :force
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
        # @overload call(new_branch, force: nil)
        #   Copy the current branch
        #   @param new_branch [String] The new name for the copied branch
        #   @param force [Boolean] Allow copying even if new_branch already exists
        #
        # @overload call(old_branch, new_branch, force: nil)
        #   Copy a specific branch
        #   @param old_branch [String] The name of the branch to copy
        #   @param new_branch [String] The new name for the copied branch
        #   @param force [Boolean] Allow copying even if new_branch already exists
        #
        # @return [String] the command output
        #
        # @raise [ArgumentError] if unsupported options are provided
        # @raise [Git::FailedError] if the branch doesn't exist or target exists (without force)
        #
        def call(*, **)
          args = ARGS.build(*, **)
          @execution_context.command('branch', *args)
        end
      end
    end
  end
end
