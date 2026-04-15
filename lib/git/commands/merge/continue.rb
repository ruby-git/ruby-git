# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Merge
      # Implements `git merge --continue` to complete a merge after conflict resolution
      #
      # After the user has resolved conflicts and staged the changes, the
      # merge can be concluded with this command.
      #
      # @example Continue after resolving conflicts
      #   continue_cmd = Git::Commands::Merge::Continue.new(execution_context)
      #   continue_cmd.call
      #
      # @note `arguments` block audited against https://git-scm.com/docs/git-merge/2.53.0
      #
      # @see Git::Commands::Merge
      #
      # @see https://git-scm.com/docs/git-merge git-merge
      #
      # @api private
      #
      class Continue < Git::Commands::Base
        arguments do
          literal 'merge'
          literal '--continue'
        end

        # @!method call(*, **)
        #
        #   @overload call()
        #
        #     Resume the in-progress merge after conflicts have been resolved
        #
        #     @return [Git::CommandLineResult] the result of calling
        #       `git merge --continue`
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
      end
    end
  end
end
