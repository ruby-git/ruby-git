# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Am
      # Implements `git am --continue` to resume after resolving conflicts
      #
      # After the user has resolved a conflict in the working tree and updated
      # the index, this command continues applying the remaining patches.
      #
      # @example Resume an am session after resolving conflicts
      #   continue_cmd = Git::Commands::Am::Continue.new(execution_context)
      #   continue_cmd.call
      #
      # @note `arguments` block audited against https://git-scm.com/docs/git-am/2.53.0
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
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
      end
    end
  end
end
