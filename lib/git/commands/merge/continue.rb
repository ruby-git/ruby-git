# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Merge
      # Implements `git merge --continue` to complete a merge after conflict resolution
      #
      # Completes the merge after conflicts have been resolved and staged.
      # The editor is suppressed via GIT_EDITOR=true set in the execution environment.
      #
      # @see https://git-scm.com/docs/git-merge git-merge
      #
      # @api private
      #
      # @example Continue after resolving conflicts
      #   continue_cmd = Git::Commands::Merge::Continue.new(execution_context)
      #   continue_cmd.call
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
        #     Execute the git merge --continue command
        #
        #     @return [Git::CommandLineResult] the result of the command
        #
        #     @raise [Git::FailedError] if no merge is in progress or conflicts remain unresolved
      end
    end
  end
end
