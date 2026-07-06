# frozen_string_literal: true

module Git
  # Collection of stash entries for a Git repository
  #
  # @example Iterate over stash entries
  #   git.stashes.each { |s| puts s.message }
  #
  # @example Check and apply a stash
  #   git.stashes.size   #=> 2
  #   git.stashes.apply
  #
  # @api public
  #
  class Stashes
    include Enumerable

    # Initialize the stashes collection
    #
    # Loads all existing stash entries from the repository at construction time.
    #
    # @example Load stashes for a repository
    #   stashes = Git::Stashes.new(repo)
    #   stashes.size  #=> 2
    #
    # @param base [Git::Repository] the git repository
    #
    # @return [void]
    #
    # @raise [Git::FailedError] if git exits with a non-zero exit status
    def initialize(base)
      @stashes = []
      @base = base

      stash_repository.stashes_all.each do |stash|
        message = stash[1]
        @stashes.unshift(Git::Stash.new(@base, message, existing: true))
      end
    end

    # Returns all stash entries as an array of index and message pairs
    #
    # Entries are listed in oldest-first order matching {Git::Repository#stashes_all}.
    #
    # @example List all stash entries
    #   git.stashes.all  #=> [[0, "testing-stash-all"], [1, "another-stash"]]
    #
    # @return [Array<Array(Integer, String)>] array of `[index, message]` pairs where
    #   index 0 is the oldest stash
    #
    # @raise [Git::FailedError] if git exits with a non-zero exit status
    #
    def all
      stash_repository.stashes_all
    end

    # Saves the current working-directory state to a new stash entry
    #
    # @example Save current changes to the stash
    #   git.stashes.save('WIP: feature work')
    #   git.stashes.size  #=> 1
    #
    # @param message [String] the stash message
    #
    # @return [void]
    #
    # @raise [Git::FailedError] if git exits with a non-zero exit status
    def save(message)
      s = Git::Stash.new(@base, message)
      @stashes.unshift(s) if s.saved?
    end

    # Applies a stash entry to the working directory
    #
    # @example Apply the most recent stash
    #   git.stashes.apply
    #
    # @example Apply a specific stash by index
    #   git.stashes.apply(1)
    #
    # @param index [Integer, nil] the stash index to apply (default: latest)
    #
    # @return [String] the output from the git stash apply command
    #
    # @raise [Git::FailedError] if git exits with a non-zero exit status
    def apply(index = nil)
      stash_repository.stash_apply(index)
    end

    # Removes all stash entries
    #
    # @example Clear all stashes
    #   git.stashes.clear
    #   git.stashes.size  #=> 0
    #
    # @return [void]
    #
    # @raise [Git::FailedError] if git exits with a non-zero exit status
    def clear
      stash_repository.stash_clear
      @stashes = []
      nil
    end

    # Returns the number of stash entries
    #
    # @example Check how many stashes exist
    #   git.stashes.size  #=> 2
    #
    # @return [Integer] the number of stashes
    def size
      @stashes.size
    end

    # Iterates over each stash entry in newest-first order
    #
    # @example Iterate over stashes
    #   git.stashes.each { |s| puts s.message }
    #
    # @overload each
    #
    #   @return [Enumerator<Git::Stash>] an enumerator over stash entries
    #
    # @overload each(&block)
    #
    #   @yield [stash] each stash entry
    #
    #   @yieldparam stash [Git::Stash] the current stash entry
    #
    #   @yieldreturn [void]
    #
    #   @return [Array<Git::Stash>] the stash entries
    #
    def each(&)
      @stashes.each(&)
    end

    # Returns the stash entry at the given index
    #
    # Stashes are stored in newest-first order; index 0 is the most recent stash.
    #
    # @example Access the most recent stash
    #   git.stashes[0].message  #=> "WIP: feature work"
    #
    # @param index [Integer, #to_i] the stash index (0 = most recent)
    #
    # @return [Git::Stash, nil] the stash entry, or `nil` if the index is out of bounds
    def [](index)
      @stashes[index.to_i]
    end

    private

    # Returns the facade interface for stash operations
    #
    # @return [Git::Repository]
    #
    def stash_repository
      @base
    end
  end
end
