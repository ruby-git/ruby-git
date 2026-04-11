# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Branch
      # Implements the `git branch --move` command for renaming branches
      #
      # This command moves/renames a branch, together with its config and reflog.
      # If the old branch name is omitted, renames the current branch.
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
      # @note `arguments` block audited against https://git-scm.com/docs/git-branch/2.53.0
      #
      # @see Git::Commands::Branch
      #
      # @see https://git-scm.com/docs/git-branch git-branch
      #
      # @api private
      #
      class Move < Git::Commands::Base
        # NOTE: The positional arguments follow Ruby semantics:
        # - When one positional is provided, it fills new_branch (required)
        # - When two positionals are provided, they fill old_branch and new_branch
        #
        # This matches the git CLI: `git branch -m [<old-branch>] <new-branch>`
        arguments do
          literal 'branch'
          literal '--move'
          flag_option %i[force f]

          end_of_options

          operand :old_branch
          operand :new_branch, required: true
        end

        # @!method call(*, **)
        #
        #   Execute the git branch --move command to rename a branch
        #
        #   @overload call(new_branch, **options)
        #
        #     Rename the current branch to new_branch
        #
        #     @param new_branch [String] the new name for the branch
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean] :force (nil) allow renaming even if new_branch already exists
        #
        #       Alias: :f
        #
        #     @return [Git::CommandLineResult] the result of calling `git branch --move`
        #
        #     @raise [ArgumentError] if unsupported options are provided
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
        #
        #   @overload call(old_branch, new_branch, **options)
        #
        #     Rename old_branch to new_branch
        #
        #     @param old_branch [String] the current name of the branch
        #
        #     @param new_branch [String] the new name for the branch
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean] :force (nil) allow renaming even if new_branch already exists
        #
        #       Alias: :f
        #
        #     @return [Git::CommandLineResult] the result of calling `git branch --move`
        #
        #     @raise [ArgumentError] if unsupported options are provided
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
      end
    end
  end
end
