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
      # @example Quit the merge, leaving working tree as-is
      #   quit_cmd = Git::Commands::Merge::Quit.new(execution_context)
      #   quit_cmd.call
      #
      # @note `arguments` block audited against https://git-scm.com/docs/git-merge/2.53.0
      #
      # @see Git::Commands::Merge
      #
      # @see https://git-scm.com/docs/git-merge git-merge
      #
      # @api private
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
        #     Forget about the current merge in progress, leaving the index
        #     and working tree as-is
        #
        #     @return [Git::CommandLineResult] the result of calling
        #       `git merge --quit`
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
      end
    end
  end
end
