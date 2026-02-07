# frozen_string_literal: true

require 'git/commands/arguments'

module Git
  module Commands
    module Branch
      # Implements the `git branch --delete` command for deleting branches
      #
      # @see https://git-scm.com/docs/git-branch git-branch
      #
      # @api private
      #
      # @example Delete a single branch
      #   delete = Git::Commands::Branch::Delete.new(execution_context)
      #   result = delete.call('feature-branch')
      #
      # @example Delete multiple branches
      #   delete = Git::Commands::Branch::Delete.new(execution_context)
      #   result = delete.call('branch1', 'branch2')
      #
      # @example Force delete (works even if not merged)
      #   delete = Git::Commands::Branch::Delete.new(execution_context)
      #   result = delete.call('feature-branch', force: true)
      #
      # @example Delete remote-tracking branch
      #   delete = Git::Commands::Branch::Delete.new(execution_context)
      #   result = delete.call('origin/feature', remotes: true)
      #
      class Delete
        # Arguments DSL for building command-line arguments
        #
        ARGS = Arguments.define do
          literal 'branch'
          literal '--delete'
          flag_option %i[force f]
          flag_option %i[remotes r]
          operand :branch_names, repeatable: true, required: true
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
        #     Alias: :f
        #
        #   @option options [Boolean] :remotes (nil) Delete remote-tracking branches. Use this together
        #     with `--delete` to delete remote-tracking branches. Note that this only
        #     makes sense if the remote-tracking branches no longer exist in the remote
        #     repository or if `git fetch` was configured not to fetch them again.
        #
        #     Alias: :r
        #
        # @return [Git::CommandLineResult] the result of calling `git branch --delete`
        #
        # @raise [ArgumentError] if no branch names are provided
        #
        # @raise [Git::FailedError] for unexpected errors (exit code > 1)
        #
        def call(*, **)
          bound_args = ARGS.bind(*, **)

          # git branch --delete exit codes: 0 = all deleted, 1 = partial failure, 2+ = error
          @execution_context.command(*bound_args, raise_on_failure: false).tap do |result|
            raise Git::FailedError, result if result.status.exitstatus > 1
          end
        end
      end
    end
  end
end
