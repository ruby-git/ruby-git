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
      # @example Unset upstream for current branch
      #   unset_upstream = Git::Commands::Branch::UnsetUpstream.new(execution_context)
      #   unset_upstream.call
      #
      # @example Unset upstream for a specific branch
      #   unset_upstream = Git::Commands::Branch::UnsetUpstream.new(execution_context)
      #   unset_upstream.call('feature')
      #
      # @note `arguments` block audited against https://git-scm.com/docs/git-branch/2.53.0
      #
      # @see Git::Commands::Branch
      #
      # @see https://git-scm.com/docs/git-branch git-branch
      #
      # @api private
      #
      class UnsetUpstream < Git::Commands::Base
        # NOTE: The --unset-upstream flag is always present.
        # The branch_name positional is optional; if omitted, git uses the current branch.
        arguments do
          literal 'branch'
          literal '--unset-upstream'
          operand :branch_name
        end

        # @!method call(*, **)
        #
        #   @overload call(branch_name = nil, **options)
        #
        #     Execute the `git branch --unset-upstream` command.
        #
        #     @param branch_name [String, nil] the branch to remove upstream tracking for
        #       (defaults to current branch if omitted)
        #
        #     @param options [Hash] command options
        #
        #     @return [Git::CommandLineResult] the result of calling `git branch --unset-upstream`
        #
        #     @raise [ArgumentError] if unsupported options are provided
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
      end
    end
  end
end
