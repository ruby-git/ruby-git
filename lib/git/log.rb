# frozen_string_literal: true

module Git
  # Builds and executes a `git log` query
  #
  # This class provides a fluent interface for building complex `git log` queries.
  #
  # Queries default to returning 30 commits; call {#max_count} with `:all` to
  # return every matching commit. Calling {#all} adds the `--all` flag to include
  # all refs in the search but does not change the number of commits returned.
  #
  # The query is lazily executed when results are requested either via the modern
  # `#execute` method or the deprecated Enumerable methods.
  #
  # @example Using the modern `execute` API
  #   log = git.log.max_count(50).between('v1.0', 'v1.1').author('Scott')
  #   results = log.execute
  #   puts "Found #{results.size} commits."
  #   results.each { |commit| puts commit.sha }
  #
  # @api public
  #
  class Log
    include Enumerable

    # An immutable, Enumerable collection of `Git::Object::Commit` objects.
    # Returned by `Git::Log#execute`.
    # @api public
    Result = Data.define(:commits) do
      include Enumerable

      def each(&block) = commits.each(&block)
      def last = commits.last
      def [](index) = commits[index]
      def to_s = commits.join("\n")
      def size = commits.size
    end

    # Create a new Git::Log object
    #
    # @example
    #   git = Git.open('.')
    #   Git::Log.new(git)
    #
    # @param base [Git::Base] the git repository object
    # @param max_count [Integer, Symbol, nil] the number of commits to return, or
    #   `:all` or `nil` to return all
    #
    #   Passing max_count to {#initialize} is equivalent to calling {#max_count} on the object.
    #
    def initialize(base, max_count = 30)
      @base = base
      @options = {}
      @dirty = true
      self.max_count(max_count)
    end

    # Set query options using a fluent interface.
    # Each method returns `self` to allow for chaining.
    #
    def max_count(num)      = set_option(:count, num == :all ? nil : num)
    def all                 = set_option(:all, true)
    def object(objectish)   = set_option(:object, objectish)
    def author(regex)       = set_option(:author, regex)
    def grep(regex)         = set_option(:grep, regex)
    def path(path)          = set_option(:path_limiter, path)
    def skip(num)           = set_option(:skip, num)
    def since(date)         = set_option(:since, date)
    def until(date)         = set_option(:until, date)
    def between(val1, val2 = nil) = set_option(:between, [val1, val2])
    def cherry              = set_option(:cherry, true)
    def merges              = set_option(:merges, true)

    # Executes the git log command and returns an immutable result object
    #
    # This is the preferred way to get log data. It separates the query
    # building from the execution, making the API more predictable.
    #
    # @example
    #   query = g.log.since('2 weeks ago').author('Scott')
    #   results = query.execute
    #   puts "Found #{results.size} commits"
    #   results.each do |commit|
    #     # ...
    #   end
    #
    # @return [Git::Log::Result] an object containing the log results
    #
    def execute
      run_log_if_dirty
      Result.new(@commits)
    end

    # @!group Deprecated Enumerable Interface

    # @deprecated Use {#execute} and call `each` on the result.
    def each(&)
      Git::Deprecation.warn(
        'Calling Git::Log#each is deprecated. Call #execute and then #each on the result object.'
      )
      run_log_if_dirty
      @commits.each(&)
    end

    # @deprecated Use {#execute} and call `size` on the result.
    def size
      Git::Deprecation.warn(
        'Calling Git::Log#size is deprecated. Call #execute and then #size on the result object.'
      )
      run_log_if_dirty
      @commits&.size
    end

    # @deprecated Use {#execute} and call `to_s` on the result.
    def to_s
      Git::Deprecation.warn(
        'Calling Git::Log#to_s is deprecated. Call #execute and then #to_s on the result object.'
      )
      run_log_if_dirty
      @commits&.join("\n")
    end

    # @deprecated Use {#execute} and call the method on the result.
    def first
      Git::Deprecation.warn(
        'Calling Git::Log#first is deprecated. Call #execute and then #first on the result object.'
      )
      run_log_if_dirty
      @commits&.first
    end

    # @deprecated Use {#execute} and call the method on the result.
    def last
      Git::Deprecation.warn(
        'Calling Git::Log#last is deprecated. Call #execute and then #last on the result object.'
      )
      run_log_if_dirty
      @commits&.last
    end

    # @deprecated Use {#execute} and call the method on the result.
    def [](index)
      Git::Deprecation.warn(
        'Calling Git::Log#[] is deprecated. Call #execute and then #[] on the result object.'
      )
      run_log_if_dirty
      @commits&.[](index)
    end

    # @!endgroup

    private

    def set_option(key, value)
      @dirty = true
      @options[key] = value
      self
    end

    def run_log_if_dirty
      return unless @dirty

      log_data = @base.lib.full_log_commits(@options)
      @commits = log_data.map { |c| Git::Object::Commit.new(@base, c['sha'], c) }
      @dirty = false
    end
  end
end
