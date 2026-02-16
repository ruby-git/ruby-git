# frozen_string_literal: true

require 'git/commands/base'

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
      class UnsetUpstream < Base
        # NOTE: The --unset-upstream flag is always present.
        # The branch_name positional is optional; if omitted, git uses the current branch.
        arguments do
          literal 'branch'
          literal '--unset-upstream'
          operand :branch_name
        end

        # Execute the git branch --unset-upstream command
        #
        # @overload call(branch_name = nil, **options)
        #
        #   @param branch_name [String, nil] The branch to configure (defaults to current branch if nil)
        #
        #   @param options [Hash] command options (none currently supported)
        #
        # @return [Git::CommandLineResult] the result of calling `git branch --unset-upstream`
        #
        # @raise [ArgumentError] if unsupported options are provided
        #
        # @raise [Git::FailedError] if the branch doesn't exist or has no upstream
        #
        def call(...) = super # rubocop:disable Lint/UselessMethodDefinition
      end
    end
  end
end
