# frozen_string_literal: true

require 'git/commands/arguments'
require 'git/commands/branch/list'

module Git
  module Commands
    module Branch
      # Implements the `git branch --unset-upstream` command for removing upstream tracking
      #
      # This command removes the upstream tracking information for the given branch
      # (or current branch if not specified).
      #
      # @see https://git-scm.com/docs/git-branch git-branch
      #
      # @api private
      #
      # @example Unset upstream for current branch
      #   unset_upstream = Git::Commands::Branch::UnsetUpstream.new(execution_context)
      #   unset_upstream.call
      #
      # @example Unset upstream for a specific branch
      #   unset_upstream = Git::Commands::Branch::UnsetUpstream.new(execution_context)
      #   unset_upstream.call('feature')
      #
      class UnsetUpstream
        # Arguments DSL for building command-line arguments
        #
        # NOTE: The --unset-upstream flag is always present.
        # The branch_name positional is optional; if omitted, git uses the current branch.
        #
        ARGS = Arguments.define do
          static 'branch'
          static '--unset-upstream'
          positional :branch_name
        end.freeze

        # Initialize the UnsetUpstream command
        #
        # @param execution_context [Git::ExecutionContext, Git::Lib] the context for executing git commands
        #
        def initialize(execution_context)
          @execution_context = execution_context
        end

        # Execute the git branch --unset-upstream command
        #
        # @overload call(branch_name = nil, **options)
        #
        #   @param branch_name [String, nil] The branch to configure (defaults to current branch if nil)
        #
        #   @param options [Hash] command options (none currently supported)
        #
        # @return [Git::BranchInfo] branch info for the configured branch with upstream unset
        #
        # @raise [ArgumentError] if unsupported options are provided
        # @raise [Git::FailedError] if the branch doesn't exist or has no upstream
        #
        def call(*, **)
          args = ARGS.bind(*, **)
          @execution_context.command(*args)
          fetch_branch_info(args.branch_name)
        end

        private

        # Fetch branch info for the specified or current branch
        #
        # @param branch_name [String, nil] the branch name, or nil for current branch
        # @return [Git::BranchInfo] the branch info
        #
        def fetch_branch_info(branch_name)
          list = List.new(@execution_context)
          branches = list.call(branch_name)
          branches.find { |b| branch_name.nil? ? b.current : b.refname == branch_name }
        end
      end
    end
  end
end
