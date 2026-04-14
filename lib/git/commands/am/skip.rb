# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Am
      # Implements `git am --skip` to skip the current patch
      #
      # Skips the current patch and continues applying remaining patches.
      #
      # @example Skip a conflicting patch
      #   skip_cmd = Git::Commands::Am::Skip.new(execution_context)
      #   skip_cmd.call
      #
      # @note `arguments` block audited against https://git-scm.com/docs/git-am/2.53.0
      #
      # @see Git::Commands::Am
      #
      # @see https://git-scm.com/docs/git-am git-am
      #
      # @api private
      #
      class Skip < Git::Commands::Base
        arguments do
          literal 'am'
          literal '--skip'
        end

        # @!method call(*, **)
        #
        #   @overload call()
        #
        #     Skip the current patch and continue with remaining patches
        #
        #     @return [Git::CommandLineResult] the result of calling `git am --skip`
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
      end
    end
  end
end
