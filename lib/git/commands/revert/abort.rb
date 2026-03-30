# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Revert
      # Implements `git revert --abort` to cancel an in-progress revert sequence
      #
      # Cancels the in-progress revert and restores the branch to the state it
      # was in before the `git revert` sequence started.
      #
      # @example Abort an in-progress revert
      #   abort_cmd = Git::Commands::Revert::Abort.new(execution_context)
      #   abort_cmd.call
      #
      # @see Git::Commands::Revert
      #
      # @see https://git-scm.com/docs/git-revert git-revert
      #
      # @api private
      #
      class Abort < Git::Commands::Base
        arguments do
          literal 'revert'
          literal '--abort'
        end

        # @!method call(*, **)
        #
        #   @overload call()
        #
        #     Cancel the in-progress revert and restore the branch to its
        #     pre-revert state
        #
        #     @return [Git::CommandLineResult] the result of calling
        #       `git revert --abort`
        #
        #     @raise [Git::FailedError] if no revert is in progress
      end
    end
  end
end
