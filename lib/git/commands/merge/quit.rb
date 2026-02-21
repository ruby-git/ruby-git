# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Merge
      # Implements `git merge --quit` to quit an in-progress merge
      #
      # Forgets about the current merge in progress. Leaves the index and
      # working tree as-is. If an autostash entry is present, saves it to
      # the stash list.
      #
      # @see https://git-scm.com/docs/git-merge git-merge
      #
      # @api private
      #
      # @example Quit the merge, leaving working tree as-is
      #   quit_cmd = Git::Commands::Merge::Quit.new(execution_context)
      #   quit_cmd.call
      #
      class Quit < Git::Commands::Base
        arguments do
          literal 'merge'
          literal '--quit'
        end

        # @!method call(*, **)
        #
        #   @overload call()
        #
        #     Execute the git merge --quit command
        #
        #     @return [Git::CommandLineResult] the result of the command
        #
        #     @raise [Git::FailedError] if the underlying git command exits non-zero
        #       (for example, on Git versions before 2.35 when no merge is in progress)
      end
    end
  end
end
