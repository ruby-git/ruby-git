# frozen_string_literal: true

require 'git/commands/base'

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
      class SetUpstream < Base
        # NOTE: The set_upstream_to option maps to git's --set-upstream-to=<upstream> syntax.
        # The branch_name positional is optional; if omitted, git uses the current branch.
        # The set_upstream_to keyword is required by the Ruby method signature, not the DSL.
        arguments do
          literal 'branch'
          value_option %i[set_upstream_to u], inline: true, required: true, allow_nil: false
          operand :branch_name
        end

        # Execute the git branch --set-upstream-to command
        #
        # @overload call(**options)
        #
        #   Sets upstream for the current branch
        #
        #   @param options [Hash] command options
        #
        #   @option options [String] :set_upstream_to (required) the upstream branch (e.g., 'origin/main').
        #
        #     Alias: :u
        #
        # @overload call(branch_name, **options)
        #
        #    Set upstream for the specified branch
        #
        #   @param branch_name [String] the branch to set upstream for
        #
        #   @param options [Hash] command options
        #
        #   @option options [String] :set_upstream_to (required) the upstream branch (e.g., 'origin/main').
        #
        #     Alias: :u
        #
        # @return [Git::CommandLineResult] the result of calling `git branch --set-upstream-to`
        #
        # @raise [ArgumentError] if set_upstream_to is not provided
        #
        # @raise [ArgumentError] if unsupported options are provided
        #
        # @raise [Git::FailedError] if the branch or upstream doesn't exist
        #
        def call(...) = super # rubocop:disable Lint/UselessMethodDefinition
      end
    end
  end
end
