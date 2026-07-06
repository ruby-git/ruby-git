# frozen_string_literal: true

module Git
  # The files and their status (e.g., added, modified, deleted) between two commits
  #
  # @example Iterate over path statuses
  #   git = Git.open('/path/to/repo')
  #   git.diff_path_status.each { |path, status| puts "#{path}: #{status}" }
  #
  # @api public
  #
  class DiffPathStatus
    include Enumerable

    # @private
    def initialize(base_or_hash, from = nil, to = nil, path_limiter = nil)
      if base_or_hash.is_a?(Hash)
        # New form: pre-fetched hash passed directly from Git::Repository::Diffing
        @fetch_path_status = base_or_hash
      else
        # Legacy form: (base, from, to, path_limiter)
        # Used by Git::Diff#path_status_provider and direct instantiation in tests.
        initialize_legacy(base_or_hash, from, to, path_limiter)
      end
    end

    # Iterates over each file path and its status code
    #
    # @example Print each path and status
    #   diff_path_status.each { |path, status| puts "#{path}: #{status}" }
    #
    # @return [Enumerator, Hash{String => String}] an `Enumerator` when no block
    #   is given; the name-status hash when a block is given
    #
    # @yield [path, status] each file path with its git status code
    #
    # @yieldparam path [String] the file path relative to the repository root
    #
    # @yieldparam status [String] the git status code (e.g. `"M"`, `"A"`, `"D"`)
    #
    # @yieldreturn [void]
    #
    def each(&)
      return to_enum(__method__) unless block_given?

      fetch_path_status.each(&)
    end

    # Returns the name-status report as a hash
    #
    # @example Basic usage
    #   diff_path_status.to_h #=> { "README.md" => "M", "lib/foo.rb" => "A" }
    #
    # @return [Hash{String => String}] a mapping of file paths to their status codes
    #
    def to_h
      fetch_path_status
    end

    private

    # Lazily fetches and caches the path status from the git lib
    #
    # @return [Hash{String => String}] a mapping of file paths to status codes
    #
    def fetch_path_status
      @fetch_path_status ||= @base.diff_name_status(@from, @to, path_limiter: @path_limiter).to_h
    end

    # Sets up legacy (base, from, to, path_limiter) instance state
    #
    # @param base [Git::Repository] the git object
    #
    # @param from [String] the first commit or object to compare
    #
    # @param to [String, nil] the second commit or object to compare
    #
    # @param path_limiter [String, Pathname, Array, nil] path(s) to limit the diff
    #
    # @return [void]
    #
    # @raise [ArgumentError] when `from` or `to` starts with `"-"`
    #
    def initialize_legacy(base, from, to, path_limiter)
      [from, to].compact.each do |arg|
        raise ArgumentError, "Invalid argument: '#{arg}'" if arg.start_with?('-')
      end
      @base = base
      @from = from
      @to = to
      @path_limiter = path_limiter
    end
  end
end
