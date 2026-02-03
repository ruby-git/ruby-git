# frozen_string_literal: true

require 'git/commands/arguments'
require 'git/commands/branch/list'
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
          static 'branch'
          static '--delete'
          flag %i[force f], args: '--force'
          flag %i[remotes r], args: '--remotes'
          positional :branch_names, variadic: true, required: true
        end.freeze

        # Regex to parse successful deletion lines from stdout
        # Matches: Deleted branch branchname (was abc123).
        # Matches: Deleted remote-tracking branch origin/branchname (was abc123).
        DELETED_BRANCH_REGEX = /^Deleted (?:remote-tracking )?branch ([^ ]+)/

        # Regex to parse error messages from stderr
        # Matches: error: branch 'branchname' not found.
        ERROR_BRANCH_REGEX = /^error: branch '([^']+)'(.*)$/

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

          # Parse results
          deleted_names = parse_deleted_branches(stdout)
          error_map = parse_error_messages(stderr)

          # Build result
          build_result(args.branch_names, existing_branches, deleted_names, error_map)
        end

        private

        # Look up BranchInfo for branches that exist
        #
        # @param args [Arguments::Bound] bound arguments
        # @return [Hash<String, Git::BranchInfo>] map of branch name to BranchInfo
        #
        def lookup_existing_branches(args)
          list_options = args.remotes ? { remotes: true } : {}

          args.branch_names.each_with_object({}) do |name, hash|
            branch_info = Git::Commands::Branch::List.new(@execution_context).call(name, **list_options).first
            hash[name] = branch_info if branch_info
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

        # Parse deleted branch names from stdout
        #
        # @param stdout [String] command stdout
        # @return [Array<String>] names of successfully deleted branches
        #
        def parse_deleted_branches(stdout)
          stdout.scan(DELETED_BRANCH_REGEX).flatten
        end

        # Parse error messages from stderr into a map
        #
        # @param stderr [String] command stderr
        # @return [Hash<String, String>] map of branch name to error message
        #
        def parse_error_messages(stderr)
          stderr.each_line.with_object({}) do |line, hash|
            match = line.match(ERROR_BRANCH_REGEX)
            hash[match[1]] = line.strip if match
          end
        end

        # Build the BranchDeleteResult from parsed data
        #
        # @param requested_names [Array<String>] originally requested branch names
        # @param existing_branches [Hash<String, Git::BranchInfo>] branches that existed before delete
        # @param deleted_names [Array<String>] names confirmed deleted in stdout
        # @param error_map [Hash<String, String>] map of branch name to error message
        # @return [Git::BranchDeleteResult] the result object
        #
        def build_result(requested_names, existing_branches, deleted_names, error_map)
          deleted = deleted_names.filter_map { |name| existing_branches[name] }

          not_deleted = (requested_names - deleted_names).map do |name|
            error_message = error_map[name] || "branch '#{name}' could not be deleted"
            Git::BranchDeleteFailure.new(name: name, error_message: error_message)
          end

          Git::BranchDeleteResult.new(deleted: deleted, not_deleted: not_deleted)
        end
      end
    end
  end
end
