# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Merge
      # Implements `git merge --abort` to abort an in-progress merge
      #
      # Aborts the current merge and reconstructs the pre-merge state.
      # If an autostash entry is present, applies it to the worktree.
      #
      # @see https://git-scm.com/docs/git-merge git-merge
      #
      # @api private
      #
      # @example Abort a merge
      #   abort_cmd = Git::Commands::Merge::Abort.new(execution_context)
      #   abort_cmd.call
      #
      class Abort < Git::Commands::Base
        arguments do
          literal 'merge'
          literal '--abort'
        end

        # @!method call(*, **)
        #
        #   @overload call()
        #
        #     Execute the git merge --abort command
        #
        #     @return [Git::CommandLineResult] the result of the command
        #
        #     @raise [Git::FailedError] if no merge is in progress
      end
    end
  end
end
