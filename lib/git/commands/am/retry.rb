# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Am
      # Command that retries the current in-progress `git am` patch
      #
      # Tries to apply the last conflicting patch again. Generally only useful
      # when retrying with extra options (e.g. `--3way`), or in scripts where
      # stdin is not a tty and the implicit retry heuristic does not trigger.
      #
      # @example Retry the current patch
      #   retry_cmd = Git::Commands::Am::Retry.new(execution_context)
      #   retry_cmd.call
      #
      # @note Requires git 2.46 or later
      #
      #   Earlier versions do not recognise the `--retry` flag; the option was
      #   introduced in git 2.46.0.
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

        # @!method call(*, **)
        #
        #   @overload call()
        #
        #     Retry applying the current patch
        #
        #     @return [Git::CommandLineResult] the result of calling `git am`
        #
        #     @raise [Git::FailedError] if no am session is in progress
      end
    end
  end
end
