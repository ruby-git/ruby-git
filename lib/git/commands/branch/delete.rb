# frozen_string_literal: true

require 'git/commands/arguments'
require 'git/commands/branch/list'
require 'git/parsers/branch'
require 'git/branch_delete_result'
require 'git/branch_delete_failure'

module Git
  module Commands
    module Branch
      # Implements the `git branch --delete` command for deleting branches
      #
      # This command deletes one or more branch heads. It uses "best effort"
      # semantics - it deletes as many branches as possible and reports which
      # branches were deleted and which failed.
      #
      # @see https://git-scm.com/docs/git-branch git-branch
      #
      # @api private
      #
      # @example Delete a single branch
      #   delete = Git::Commands::Branch::Delete.new(execution_context)
      #   result = delete.call('feature-branch')
      #   result.success?            #=> true
      #   result.deleted.first.name  #=> 'feature-branch'
      #
      # @example Delete multiple branches with partial failure
      #   delete = Git::Commands::Branch::Delete.new(execution_context)
      #   result = delete.call('branch1', 'nonexistent', 'branch2')
      #   result.success?                    #=> false
      #   result.deleted.map(&:name)         #=> ['branch1', 'branch2']
      #   result.not_deleted.first.name      #=> 'nonexistent'
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
        ARGS = Arguments.define do
          literal 'branch'
          literal '--delete'
          flag_option %i[force f], args: '--force'
          flag_option %i[remotes r], args: '--remotes'
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
        # This method captures branch information before deletion and returns a
        # structured result showing which branches were deleted and which failed.
        # It does not raise an error for partial failures (when some branches don't
        # exist or can't be deleted), but will re-raise unexpected errors.
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
        # @return [Git::BranchDeleteResult] result containing deleted branches and failures
        #
        # @raise [ArgumentError] if no branch names are provided
        # @raise [Git::FailedError] for unexpected errors (not partial deletion failures)
        #
        def call(*, **)
          args = ARGS.bind(*, **)

          # Capture branch info BEFORE deletion for branches that exist
          existing_branches = lookup_existing_branches(args)

          # Execute the delete command
          stdout, stderr = execute_delete(args)

          # Parse results and build result using BranchParser
          deleted_names = Git::Parsers::Branch.parse_deleted_branches(stdout)
          error_map = Git::Parsers::Branch.parse_error_messages(stderr)

          Git::Parsers::Branch.build_delete_result(args.branch_names, existing_branches, deleted_names, error_map)
        end

        private

        # Look up BranchInfo for branches that exist
        #
        # @param args [Arguments::Bound] bound arguments
        # @return [Hash<String, Git::BranchInfo>] map of branch name to BranchInfo
        #
        def lookup_existing_branches(args)
          list_options = args.remotes ? { remotes: true } : {}
          branches = Git::Commands::Branch::List.new(@execution_context).call(*args.branch_names, **list_options)
          branches.each_with_object({}) do |info, hash|
            # For remote branches, strip 'remotes/' prefix to match user input
            # e.g., 'remotes/origin/main' -> 'origin/main'
            # For local branches, keep the name as-is (including if literally named 'remotes/...')
            key = args.remotes ? info.refname.sub(%r{^remotes/}, '') : info.refname
            hash[key] = info
          end
        end

        # Execute git branch --delete and capture output
        #
        # Exit code 1 indicates some branches couldn't be deleted (e.g., not found).
        # This is git's standard behavior for partial failures in batch delete operations.
        # Other exit codes indicate fatal errors (e.g., not a git repository).
        #
        # @param args [Arguments::Bound] bound arguments
        # @return [Array<String, String>] [stdout, stderr]
        # @raise [Git::FailedError] for fatal errors (exit code > 1)
        #
        def execute_delete(args)
          result = @execution_context.command(*args, raise_on_failure: false)

          # Exit code > 1 indicates fatal error; exit 1 is partial failure (expected)
          raise Git::FailedError, result if result.status.exitstatus > 1

          [result.stdout, result.stderr]
        end
      end
    end
  end
end
