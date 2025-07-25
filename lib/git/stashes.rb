# frozen_string_literal: true

module Git
  # object that holds all the available stashes
  class Stashes
    include Enumerable

    def initialize(base)
      @stashes = []

      @base = base

      @base.lib.stashes_all.each do |indexed_message|
        _index, message = indexed_message
        @stashes.unshift(Git::Stash.new(@base, message, save: true))
      end
    end

    #
    # Returns an multi-dimensional Array of elements that have been stash saved.
    # Array is based on position and name. See Example
    #
    # @example Returns Array of items that have been stashed
    #     .all - [0, "testing-stash-all"]]
    # @return [Array]
    def all
      @base.lib.stashes_all
    end

    def save(message)
      s = Git::Stash.new(@base, message)
      @stashes.unshift(s) if s.saved?
    end

    def apply(index = nil)
      @base.lib.stash_apply(index)
    end

    def clear
      @base.lib.stash_clear
      @stashes = []
    end

    def size
      @stashes.size
    end

    def each(&)
      @stashes.each(&)
    end

    def [](index)
      @stashes[index.to_i]
    end
  end
end
