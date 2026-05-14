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
      # @raise [Git::FailedError] if git exits with a non-zero exit status
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

      # Apply a stash to the working directory
      #
      # Applies the changes recorded in a stash entry to the working directory
      # without removing the entry from the stash list. Unlike `git stash pop`,
      # the stash entry is preserved after applying.
      #
      # @example Apply the most recent stash
      #   repo.stash_apply #=> "HEAD is now at abc1234 Initial commit"
      #
      # @example Apply a specific stash entry by reference
      #   repo.stash_apply('stash@{1}') #=> "HEAD is now at abc1234 Initial commit"
      #
      # @param id [String, Integer, nil] the stash identifier (e.g., `'stash@{0}'`,
      #   `0`) or `nil` to apply the most recent stash entry
      #
      # @return [String] the output from the git stash apply command
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      # @see https://git-scm.com/docs/git-stash git-stash documentation
      #
      def stash_apply(id = nil)
        Git::Commands::Stash::Apply.new(@execution_context).call(id).stdout
      end

      # Remove all stash entries
      #
      # Removes all entries from the stash list. Use with caution as this
      # operation cannot be undone.
      #
      # @return [String] the output from the git stash clear command
      #   (typically empty)
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      # @example Clear all stashes
      #   repo.stash_clear #=> ""
      #
      # @see https://git-scm.com/docs/git-stash git-stash documentation
      #
      def stash_clear
        Git::Commands::Stash::Clear.new(@execution_context).call.stdout
      end
    end
  end
end
