# frozen_string_literal: true

require 'git/commands/stash'
require 'git/parsers/stash'

module Git
  class Repository
    # Facade methods for stash operations
    #
    # Included by {Git::Repository}.
    #
    # @api public
    #
    module Stashing
      # Returns all stash entries as an array of index and message pairs
      #
      # Lists all stash entries in the repository ordered from oldest to newest.
      # The index is a sequential number starting from 0 for the oldest stash. The
      # message is the stash description with the leading branch prefix (e.g.
      # `"On main:"` or `"WIP on main:"`) stripped.
      #
      # @example List all stashes (oldest first)
      #   repo.stashes_all #=> [[0, "Fix bug"], [1, "Add feature"]]
      #
      # @return [Array<Array(Integer, String)>] array of `[index, message]` pairs
      #   where index is the sequential position (0 is oldest) and message is the
      #   stash description with the branch prefix stripped
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      # @note The sequential index returned here is **not** the same as git's
      #   `stash@{N}` reference used by {#stash_apply}. In git, `stash@{0}` is the
      #   **most recent** stash, while index `0` here is the **oldest**. To apply a
      #   specific stash from this list, convert the entry's position to a git
      #   reference: `'stash@{%d}' % (total - 1 - index)`, or pass the string
      #   reference directly to {#stash_apply}.
      #
      # @see https://git-scm.com/docs/git-stash git-stash documentation
      #
      def stashes_all
        result = Git::Commands::Stash::List.new(@execution_context).call
        stashes = Git::Parsers::Stash.parse_list(result.stdout)
        stashes.reverse.each_with_index.map do |info, i|
          message = info.message.sub(/^(?:WIP on|On)\s+[^:]+:\s*/, '')
          [i, message]
        end
      end

      # Returns stash entries as a formatted string matching `git stash list` output
      #
      # @example List stashes as a formatted string
      #   repo.stash_list #=> "stash@{0}: On main: WIP\nstash@{1}: On feature: Fix bug"
      #
      # @return [String] newline-joined `"stash@{n}: <full message>"` entries, or an
      #   empty string when there are no stashes; the format matches `git stash list`
      #   output
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      # @deprecated Use {#stashes_all} instead
      #
      # @see #stashes_all
      #
      # @see https://git-scm.com/docs/git-stash git-stash documentation
      #
      def stash_list
        Git::Deprecation.warn(
          'Git::Repository#stash_list is deprecated and will be removed in a future version. ' \
          'Use Git::Repository#stashes_all instead.'
        )
        result = Git::Commands::Stash::List.new(@execution_context).call
        stashes = Git::Parsers::Stash.parse_list(result.stdout)
        stashes.map { |info| "#{info.name}: #{info.message}" }.join("\n")
      end

      # Save the current working directory and index state to a new stash
      #
      # @example Save current changes
      #   repo.stash_save('WIP: feature work')
      #
      # @param message [String] the stash message
      #
      # @return [Boolean] true if changes were stashed, false if there were no
      #   local changes to save
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
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
      #   `0`) or `nil` to apply the most recent stash entry. When an Integer is
      #   given it is passed directly to git as `stash@{N}`, where `0` is the
      #   **most recent** stash — the opposite order from {#stashes_all}'s
      #   sequential indices, where `0` is the **oldest** stash.
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
      # @example Clear all stashes
      #   repo.stash_clear #=> ""
      #
      # @return [String] the output from the git stash clear command
      #   (typically empty)
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      # @see https://git-scm.com/docs/git-stash git-stash documentation
      #
      def stash_clear
        Git::Commands::Stash::Clear.new(@execution_context).call.stdout
      end
    end
  end
end
