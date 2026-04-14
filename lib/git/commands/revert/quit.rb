# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Revert
      # Implements `git revert --quit` to forget an in-progress revert sequence
      #
      # Clears the sequencer state without restoring the branch, leaving the
      # working tree and index in their current state. If no revert is in
      # progress, this is a no-op and still succeeds.
      #
      # @example Forget an in-progress revert session
      #   quit_cmd = Git::Commands::Revert::Quit.new(execution_context)
      #   quit_cmd.call
      #
      # @note `arguments` block audited against https://git-scm.com/docs/git-revert/2.53.0
      #
      # @see Git::Commands::Revert
      #
      # @see https://git-scm.com/docs/git-revert git-revert
      #
      # @api private
      #
      class Quit < Git::Commands::Base
        arguments do
          literal 'revert'
          literal '--quit'
        end

        # @!method call(*, **)
        #
        #   @overload call()
        #
        #     Clear any in-progress revert sequencer state, leaving the
        #     working tree as-is. If no revert is in progress, this is a
        #     no-op and still succeeds.
        #
        #     @return [Git::CommandLineResult] the result of calling
        #       `git revert --quit`
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
      end
    end
  end
end
