# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Am
      # Implements `git am --quit` to abort the in-progress am session
      #
      # Aborts the in-progress patch application but keeps the current HEAD
      # position (does not restore the branch to its pre-am state).
      #
      # @example Quit an am session without restoring HEAD
      #   quit_cmd = Git::Commands::Am::Quit.new(execution_context)
      #   quit_cmd.call
      #
      # @note `arguments` block audited against https://git-scm.com/docs/git-am/2.53.0
      #
      # @see Git::Commands::Am
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
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
      end
    end
  end
end
