# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Am
      # Implements `git am --abort` to abort an in-progress am session
      #
      # Aborts the in-progress patch application and restores the branch to
      # the state it was in before the `git am` session started.
      #
      # @example Abort an am session
      #   abort_cmd = Git::Commands::Am::Abort.new(execution_context)
      #   abort_cmd.call
      #
      # @see https://git-scm.com/docs/git-am git-am
      #
      # @api private
      #
      class Abort < Git::Commands::Base
        arguments do
          literal 'am'
          literal '--abort'
        end

        # @!method call(*, **)
        #
        #   @overload call()
        #
        #     Abort the in-progress am session and restore the branch
        #
        #     @return [Git::CommandLineResult] the result of calling `git am --abort`
        #
        #     @raise [Git::FailedError] if no am session is in progress
      end
    end
  end
end
