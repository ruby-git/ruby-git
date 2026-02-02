# frozen_string_literal: true

require 'git/commands/arguments'

module Git
  module Commands
    module Branch
      # Implements the `git branch --set-upstream-to` command for configuring upstream tracking
      #
      # This command sets up tracking information so the specified upstream branch is considered
      # the upstream for the given branch (or current branch if not specified).
      #
      # @see https://git-scm.com/docs/git-branch git-branch
      #
      # @api private
      #
      # @example Set upstream for current branch
      #   set_upstream = Git::Commands::Branch::SetUpstream.new(execution_context)
      #   set_upstream.call(set_upstream_to: 'origin/main')
      #
      # @example Set upstream for a specific branch
      #   set_upstream = Git::Commands::Branch::SetUpstream.new(execution_context)
      #   set_upstream.call('feature', set_upstream_to: 'origin/main')
      #
      class SetUpstream
        # Arguments DSL for building command-line arguments
        #
        # NOTE: The set_upstream_to option maps to git's --set-upstream-to=<upstream> syntax.
        # The branch_name positional is optional; if omitted, git uses the current branch.
        # The set_upstream_to keyword is required by the Ruby method signature, not the DSL.
        #
        ARGS = Arguments.define do
          static 'branch'
          value :set_upstream_to, inline: true, required: true, allow_nil: false
          positional :branch_name
        end.freeze

        # Initialize the SetUpstream command
        #
        # @param execution_context [Git::ExecutionContext, Git::Lib] the context for executing git commands
        #
        def initialize(execution_context)
          @execution_context = execution_context
        end

        # Execute the git branch --set-upstream-to command
        #
        # @overload call(**options)
        #
        #   Sets upstream for the current branch
        #
        #   @param options [Hash] command options
        #
        #   @option options [String] :set_upstream_to (required) the upstream branch (e.g., 'origin/main')
        #
        # @overload call(branch_name, **options)
        #
        #    Set upstream for the specified branch
        #
        #   @param branch_name [String] the branch to set upstream for
        #
        #   @param options [Hash] command options
        #
        #   @option options [String] :set_upstream_to (required) the upstream branch (e.g., 'origin/main')
        #
        # @return [Git::CommandLineResult] the result of the command
        #
        # @raise [ArgumentError] if set_upstream_to is not provided
        # @raise [ArgumentError] if unsupported options are provided
        # @raise [Git::FailedError] if the branch or upstream doesn't exist
        #
        def call(*, **)
          args = ARGS.build(*, **)
          @execution_context.command(*args)
        end
      end
    end
  end
end
