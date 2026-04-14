# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Revert
      # Implements `git revert --skip` to skip the current commit in a sequence
      #
      # Skips the current commit and continues applying the remaining commits
      # in the revert sequence.
      #
      # @example Skip a conflicting commit during a revert sequence
      #   skip_cmd = Git::Commands::Revert::Skip.new(execution_context)
      #   skip_cmd.call
      #
      # @note `arguments` block audited against https://git-scm.com/docs/git-revert/2.53.0
      #
      # @see Git::Commands::Revert
      #
      # @see https://git-scm.com/docs/git-revert git-revert
      #
      # @api private
      #
      class Skip < Git::Commands::Base
        arguments do
          literal 'revert'
          literal '--skip'
        end

        # @!method call(*, **)
        #
        #   @overload call()
        #
        #     Skip the current commit and continue with the remaining sequence
        #
        #     @return [Git::CommandLineResult] the result of calling
        #       `git revert --skip`
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
      end
    end
  end
end
