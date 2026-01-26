# frozen_string_literal: true

module Git
  # Object that holds all the available stashes
  #
  class Stashes
    include Enumerable

    # Initialize the stashes collection
    #
    # @param base [Git::Base] the git repository object
    #
    def initialize(base)
      @stashes = []
      @base = base

      @base.lib.stashes_all.each do |(_index, message)|
        @stashes << Git::Stash.new(@base, message, save: true)
      end
    end

    # Returns all stash entries with full metadata
    #
    # @example Listing stashes with metadata
    #   git.stashes.all.each do |info|
    #     puts "#{info.short_sha} #{info.name}: #{info.message}"
    #   end
    #
    # @return [Array<Git::StashInfo>] array of stash info objects
    #
    def all
      @base.lib.stashes_list
    end

    # Returns a multi-dimensional Array of elements that have been stash saved
    #
    # Array is based on position and name.
    #
    # @deprecated Use {#all} instead, which returns {Git::StashInfo} objects.
    #   See the migration guide in the CHANGELOG for updating your code.
    #
    # @example Returns Array of items that have been stashed
    #   git.stashes.all_legacy # => [[0, "testing-stash-all"]]
    #
    # @return [Array<Array(Integer, String)>] array of `[index, message]` pairs
    #
    def all_legacy
      warn '[DEPRECATION] Git::Stashes#all_legacy is deprecated. Use #all instead which returns StashInfo objects.'
      @base.lib.stashes_all
    end

    # Save the current working directory state to a new stash
    #
    # @param message [String] the stash message
    # @return [void]
    #
    def save(message)
      s = Git::Stash.new(@base, message)
      @stashes.unshift(s) if s.saved?
    end

    # Apply a stash to the working directory
    #
    # @param index [Integer, nil] the stash index to apply (default: latest)
    # @return [String] the name of the applied stash (e.g., 'stash@\\{0}')
    #
    def apply(index = nil)
      @base.lib.stash_apply(index)
    end

    # Remove all stash entries
    #
    # @return [void]
    #
    def clear
      @base.lib.stash_clear
      @stashes = []
    end

    # Return the number of stash entries
    #
    # @return [Integer] number of stashes
    #
    def size
      @stashes.size
    end

    # Iterate over stash entries
    #
    # @yield [Git::Stash] each stash entry
    # @return [Enumerator] if no block given
    #
    def each(&)
      @stashes.each(&)
    end

    # Access a stash by index
    #
    # @param index [Integer, #to_i] the stash index
    # @return [Git::Stash, nil] the stash at the given index
    #
    def [](index)
      @stashes[index.to_i]
    end
  end
end
