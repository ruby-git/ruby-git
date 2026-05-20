# frozen_string_literal: true

module Git
  # Lazy diff statistics for a comparison between two trees
  #
  # Supports comparing (1) two commits, (2) a commit against the working tree,
  # or (3) the index against the working tree.
  #
  # @example Get the insertion and deletion counts
  #   stats = repo.diff_stats
  #   stats.insertions #=> 3
  #   stats.deletions  #=> 1
  #
  # @api public
  class DiffStats
    # @private
    def initialize(base, from, to, path_limiter = nil)
      # Eagerly check for invalid arguments
      [from, to].compact.each do |arg|
        raise ArgumentError, "Invalid argument: '#{arg}'" if arg.start_with?('-')
      end

      @base = base
      @from = from
      @to = to
      @path_limiter = path_limiter
      @fetch_stats = nil
    end

    # Returns the total number of lines deleted
    #
    # @example Get the deletion count
    #   stats = repo.diff_stats
    #   stats.deletions #=> 5
    #
    # @return [Integer] the total deletion count
    def deletions
      fetch_stats[:total][:deletions]
    end

    # Returns the total number of lines inserted
    #
    # @example Get the insertion count
    #   stats = repo.diff_stats
    #   stats.insertions #=> 3
    #
    # @return [Integer] the total insertion count
    def insertions
      fetch_stats[:total][:insertions]
    end

    # Returns the total number of lines changed (insertions + deletions)
    #
    # @example Get the total changed-line count
    #   stats = repo.diff_stats
    #   stats.lines #=> 8
    #
    # @return [Integer] the total changed-line count
    def lines
      fetch_stats[:total][:lines]
    end

    # Returns a hash of statistics for each file in the diff
    #
    # @example Get per-file statistics
    #   stats = repo.diff_stats
    #   stats.files #=> { "lib/foo.rb" => { insertions: 3, deletions: 1 } }
    #
    # @return [Hash{String=>Hash{Symbol=>Integer}}]
    #   per-file statistics keyed by file path
    def files
      fetch_stats[:files]
    end

    # Returns a hash of the total statistics for the diff
    #
    # @example Get total statistics
    #   stats = repo.diff_stats
    #   stats.total #=> { insertions: 3, deletions: 1, lines: 4, files: 1 }
    #
    # @return [Hash{Symbol=>Integer}]
    #   aggregate statistics for the entire diff
    def total
      fetch_stats[:total]
    end

    private

    # Lazily fetches and caches the stats from the git lib
    #
    # When `@base` implements `#diff_numstat`, delegates directly to that
    # method. Otherwise falls back to the legacy `@base.lib.diff_stats` call
    # so that existing `Git::Base`-backed callers continue to work unchanged.
    #
    # @return [Hash] the fetched stats hash
    def fetch_stats
      @fetch_stats ||= if @base.respond_to?(:diff_numstat)
                         @base.diff_numstat(@from, @to, path_limiter: @path_limiter)
                       else
                         @base.lib.diff_stats(@from, @to, { path_limiter: @path_limiter })
                       end
    end
  end
end
