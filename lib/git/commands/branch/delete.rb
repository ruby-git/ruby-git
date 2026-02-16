# frozen_string_literal: true

require 'git/commands/base'

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
      class Delete < Base
        arguments do
          literal 'branch'
          literal '--delete'
          flag_option %i[force f]
          flag_option %i[remotes r]
          operand :branch_names, repeatable: true, required: true
        end

        # git branch --delete exits 1 when one or more branches cannot be deleted
        allow_exit_status 0..1

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
        def call(...) = super
      end
    end
  end
end
