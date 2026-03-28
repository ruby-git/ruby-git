# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Am
      # Implements `git am --continue` to resume after resolving conflicts
      #
      # After the user has resolved a conflict, the patch can be applied again
      # with `--continue`. The editor is suppressed via `GIT_EDITOR=true` set
      # in the execution environment.
      #
      # @example Resume an am session after resolving conflicts
      #   continue_cmd = Git::Commands::Am::Continue.new(execution_context)
      #   continue_cmd.call
      #
      # @see Git::Commands::Am
      #
      # @see https://git-scm.com/docs/git-am git-am
      #
      # @api private
      #
      class Continue < Git::Commands::Base
        arguments do
          literal 'am'
          literal '--continue'
        end

        # @!method call(*, **)
        #
        #   @overload call()
        #
        #     Resume applying patches after conflicts have been resolved
        #
        #     @return [Git::CommandLineResult] the result of calling `git am --continue`
        #
        #     @raise [Git::FailedError] if no am session is in progress or
        #       conflicts remain unresolved
      end
    end
  end
end
