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
      # @example Abort a merge
      #   abort_cmd = Git::Commands::Merge::Abort.new(execution_context)
      #   abort_cmd.call
      #
      # @note `arguments` block audited against https://git-scm.com/docs/git-merge/2.53.0
      #
      # @see Git::Commands::Merge
      #
      # @see https://git-scm.com/docs/git-merge git-merge
      #
      # @api private
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
        #     Abort the current merge and reconstruct the pre-merge state
        #
        #     @return [Git::CommandLineResult] the result of calling
        #       `git merge --abort`
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
      end
    end
  end
end
