# frozen_string_literal: true

require 'git/commands/base'

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
      class Copy < Git::Commands::Base
        # NOTE: The positional arguments follow Ruby semantics:
        # - When one positional is provided, it fills new_branch (required)
        # - When two positionals are provided, they fill old_branch and new_branch
        #
        # This matches the git CLI: `git branch -c [<old-branch>] <new-branch>`
        arguments do
          literal 'branch'
          literal '--copy'
          flag_option %i[force f]
          operand :old_branch
          operand :new_branch, required: true
        end

        # @!method call(*, **)
        #
        #   Execute the git branch --copy command to copy a branch
        #
        #   @overload call(new_branch, **options)
        #
        #     Copies the current branch to the new_branch
        #
        #     @param new_branch [String] the new name for the copied branch
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean] :force (nil) Allow copying even if new_branch already exists.
        #
        #       Alias: :f
        #
        #   @overload call(old_branch, new_branch, **options)
        #
        #     Copies old_branch to new_branch
        #
        #     @param old_branch [String] branch to copy from
        #
        #     @param new_branch [String] the new name for the copied branch
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean] :force (nil) Allow copying even if new_branch already exists.
        #
        #       Alias: :f
        #
        #     @return [Git::CommandLineResult] the result of calling `git branch --copy`
        #
        #     @raise [ArgumentError] if unsupported options are provided
        #
        #     @raise [Git::FailedError] if the branch doesn't exist or target exists (without force)
      end
    end
  end
end
