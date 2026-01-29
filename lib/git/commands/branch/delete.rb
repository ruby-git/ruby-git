# frozen_string_literal: true

require 'git/commands/arguments'

module Git
  module Commands
    module Branch
      # Implements the `git branch --delete` command for deleting branches
      #
      # This command deletes one or more branch heads. The branch must be fully
      # merged in its upstream branch, or in HEAD if no upstream was set, unless
      # the `:force` option is provided.
      #
      # @see https://git-scm.com/docs/git-branch git-branch
      #
      # @api private
      #
      # @example Basic branch deletion (safe - fails if not merged)
      #   delete = Git::Commands::Branch::Delete.new(execution_context)
      #   delete.call('feature-branch')
      #
      # @example Force delete (works even if not merged)
      #   delete = Git::Commands::Branch::Delete.new(execution_context)
      #   delete.call('feature-branch', force: true)
      #
      # @example Delete remote-tracking branch
      #   delete = Git::Commands::Branch::Delete.new(execution_context)
      #   delete.call('origin/feature', remotes: true)
      #
      # @example Delete multiple branches at once
      #   delete = Git::Commands::Branch::Delete.new(execution_context)
      #   delete.call('branch1', 'branch2', 'branch3')
      #
      # @example Force delete with quiet mode
      #   delete = Git::Commands::Branch::Delete.new(execution_context)
      #   delete.call('feature-branch', force: true, quiet: true)
      #
      class Delete
        # Arguments DSL for building command-line arguments
        ARGS = Arguments.define do
          static 'branch'
          static '--delete'
          flag %i[force f], args: '--force'
          flag %i[remotes r], args: '--remotes'
          flag %i[quiet q], args: '--quiet'
          positional :branch_names, variadic: true, required: true
        end.freeze

        # Initialize the Delete command
        #
        # @param execution_context [Git::ExecutionContext, Git::Lib] the context for executing git commands
        #
        def initialize(execution_context)
          @execution_context = execution_context
        end

        # Execute the git branch --delete command to delete branches
        #
        # @overload call(*branch_names, **options)
        #
        #   @param branch_names [Array<String>] One or more branch names to delete.
        #
        #   @param options [Hash] command options
        #
        #   @option options [Boolean] :force (nil) Allow deleting the branch irrespective of its merged
        #     status, or whether it even points to a valid commit. This is equivalent
        #     to the `-D` shortcut (`--delete --force`).
        #
        #   @option options [Boolean] :remotes (nil) Delete remote-tracking branches. Use this together
        #     with `--delete` to delete remote-tracking branches. Note that this only
        #     makes sense if the remote-tracking branches no longer exist in the remote
        #     repository or if `git fetch` was configured not to fetch them again.
        #
        #   @option options [Boolean] :quiet (nil) Be more quiet when deleting a branch, suppressing
        #     non-error messages.
        #
        # @return [Git::CommandLineResult] the result of the command
        #
        # @raise [ArgumentError] if unsupported options are provided
        # @raise [Git::FailedError] if the branch is not fully merged (without force)
        #
        def call(*, **)
          args = ARGS.build(*, **)
          @execution_context.command(*args)
        end
      end
    end
  end
end
