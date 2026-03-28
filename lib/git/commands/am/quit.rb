# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Am
      # Wrapper for `git am --quit` that aborts the in-progress am session
      #
      # Aborts the in-progress patch application but keeps the current HEAD
      # position (does not restore the branch to its pre-am state).
      #
      # @example Quit an am session without restoring HEAD
      #   quit_cmd = Git::Commands::Am::Quit.new(execution_context)
      #   quit_cmd.call
      #
      # @see https://git-scm.com/docs/git-am git-am
      #
      # @api private
      #
      class Quit < Git::Commands::Base
        arguments do
          literal 'am'
          literal '--quit'
        end

        # @!method call(*, **)
        #
        #   @overload call()
        #
        #     Abort the am session but keep the current HEAD position
        #
        #     @return [Git::CommandLineResult] the result of calling `git am --quit`
        #
        #     @raise [Git::FailedError] if no am session is in progress
      end
    end
  end
end
