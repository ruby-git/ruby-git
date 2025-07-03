# frozen_string_literal: true

module Git
  # Provides access to the statistics of a diff between two commits,
  # including insertions, deletions, and file-level details.
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
      @stats = nil
    end

    # Returns the total number of lines deleted.
    def deletions
      fetch_stats[:total][:deletions]
    end

    # Returns the total number of lines inserted.
    def insertions
      fetch_stats[:total][:insertions]
    end

    # Returns the total number of lines changed (insertions + deletions).
    def lines
      fetch_stats[:total][:lines]
    end

    # Returns a hash of statistics for each file in the diff.
    #
    # @return [Hash<String, {insertions: Integer, deletions: Integer}>]
    def files
      fetch_stats[:files]
    end

    # Returns a hash of the total statistics for the diff.
    #
    # @return [{insertions: Integer, deletions: Integer, lines: Integer, files: Integer}]
    def total
      fetch_stats[:total]
    end

    private

    # Lazily fetches and caches the stats from the git lib.
    def fetch_stats
      @fetch_stats ||= @base.lib.diff_stats(
        @from, @to, { path_limiter: @path_limiter }
      )
    end
  end
end
