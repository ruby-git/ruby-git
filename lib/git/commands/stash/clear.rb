# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Stash
      # Remove all stash entries
      #
      # Removes all stash entries. Use with caution as this cannot be undone.
      #
      # @example Clear all stashes
      #   Git::Commands::Stash::Clear.new(execution_context).call
      #
      # @note `arguments` block audited against https://git-scm.com/docs/git-stash/2.53.0
      #
      # @see Git::Commands::Stash Git::Commands::Stash for usage examples
      #
      # @see https://git-scm.com/docs/git-stash git-stash documentation
      #
      # @api private
      #
      class Clear < Git::Commands::Base
        arguments do
          literal 'stash'
          literal 'clear'
        end

        # @!method call(*)
        #
        #   @overload call()
        #
        #     Clear all stash entries
        #
        #   @return [Git::CommandLine::Result] the result of calling `git stash clear`
        #
        #   @raise [Git::FailedError] if git exits with a non-zero exit status
        #
        #   @api public
      end
    end
  end
end
