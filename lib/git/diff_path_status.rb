# frozen_string_literal: true

module Git
  class DiffPathStatus
    include Enumerable

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
      @path_status = nil
    end

    # Iterates over each file's status.
    #
    # @yield [path, status]
    def each(&block)
      fetch_path_status.each(&block)
    end

    # Returns the name-status report as a Hash.
    #
    # @return [Hash<String, String>] A hash where keys are file paths
    #   and values are their status codes.
    def to_h
      fetch_path_status
    end

    private

    # Lazily fetches and caches the path status from the git lib.
    def fetch_path_status
      @path_status ||= @base.lib.diff_path_status(
        @from, @to, { path: @path_limiter }
      )
    end
  end
end
