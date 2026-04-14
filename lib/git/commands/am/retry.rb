# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Am
      # Implements `git am --retry` to retry the most-recently-failed patch
      #
      # Tries to apply the last conflicting patch again. Generally only useful
      # when retrying with extra options (e.g. `--3way`), or in scripts where
      # stdin is not a tty and the implicit retry heuristic does not trigger.
      #
      # @example Retry the current patch
      #   retry_cmd = Git::Commands::Am::Retry.new(execution_context)
      #   retry_cmd.call
      #
      # @note `arguments` block audited against https://git-scm.com/docs/git-am/2.53.0
      #
      # @see Git::Commands::Am
      #
      # @see https://git-scm.com/docs/git-am git-am
      #
      # @api private
      #
      class Retry < Git::Commands::Base
        arguments do
          literal 'am'
          literal '--retry'
        end

        # git am --retry was introduced in git 2.46.0
        requires_git_version '2.46.0'

        # @!method call(*, **)
        #
        #   @overload call()
        #
        #     Retry applying the most-recently-failed patch
        #
        #     @return [Git::CommandLineResult] the result of calling `git am --retry`
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
      end
    end
  end
end
