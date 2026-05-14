# frozen_string_literal: true

require 'git/commands/stash'

module Git
  class Repository
    # Facade methods for stash operations
    #
    # Included by {Git::Repository}.
    #
    # @api public
    #
    module Stashing
      # Save the current working directory and index state to a new stash
      #
      # @param message [String] the stash message
      #
      # @return [Boolean] true if changes were stashed, false if there were no
      #   local changes to save
      #
      # @raise [Git::FailedError] when git exits with a non-zero exit status
      #
      # @example Save current changes
      #   repo.stash_save('WIP: feature work')
      #
      # @see https://git-scm.com/docs/git-stash git-stash documentation
      #
      def stash_save(message) # rubocop:disable Naming/PredicateMethod
        result = Git::Commands::Stash::Push.new(@execution_context).call(message: message)
        !result.stdout.include?('No local changes to save')
      end
    end
  end
end
