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
    #
    # @api public
    Result = Data.define(:commits) do
      include Enumerable

      # Iterates over each commit in query order
      #
      # @overload each
      #   @example Get an enumerator
      #     results.each.map(&:sha)
      #
      #   @return [Enumerator<Git::Object::Commit>] an enumerator over commits
      #
      # @overload each(&block)
      #   @example Iterate with a block
      #     results.each { |commit| puts commit.sha }
      #
      #   @yield [commit] each commit from the result
      #
      #   @yieldparam commit [Git::Object::Commit] a commit in query order
      #
      #   @yieldreturn [void]
      #
      #   @return [Array<Git::Object::Commit>] the commit array
      #
      def each(&block) = commits.each(&block)

      # Returns the last commit in the result
      #
      # @return [Git::Object::Commit, nil] the last commit, or `nil` when empty
      #
      def last = commits.last

      # Returns a commit by index or a slice of commits by range
      #
      # @param index [Integer, Range] the commit index or range to retrieve
      #
      # @return [Git::Object::Commit, Array<Git::Object::Commit>, nil] the selected
      #   commit or commits
      #
      def [](index) = commits[index]

      # Returns the commits joined with newlines
      #
      # @return [String] newline-separated commits
      #
      def to_s = commits.join("\n")

      # Returns the number of commits in the result
      #
      # @return [Integer] the commit count
      #
      def size = commits.size
    end

    # Create a new Git::Log object
    #
    # @example
    #   git = Git.open('.')
    #   Git::Log.new(git)
    #
    # @param base [Git::Repository] the git repository object
    #
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
    # Sets the maximum number of commits to return
    #
    # @param num [Integer, Symbol, nil] the maximum commit count, or `:all` / `nil`
    #   for no limit
    #
    # @return [Git::Log] the current query builder
    #
    def max_count(num)      = set_option(:count, num == :all ? nil : num)

    # Includes commits reachable from all refs
    #
    # @return [Git::Log] the current query builder
    #
    def all                 = set_option(:all, true)

    # Sets the revision range expression for the log query
    #
    # @param objectish [String] a git revision expression to pass to `git log`
    #
    # @return [Git::Log] the current query builder
    #
    def object(objectish)   = set_option(:object, objectish)

    # Filters commits by author pattern
    #
    # @param regex [String] a pattern matched against author names
    #
    # @return [Git::Log] the current query builder
    #
    def author(regex)       = set_option(:author, regex)

    # Filters commits by commit message pattern
    #
    # @param regex [String] a pattern matched against commit messages
    #
    # @return [Git::Log] the current query builder
    #
    def grep(regex)         = set_option(:grep, regex)

    # Limits commits to those that touch the given path or paths
    #
    # @param path [String, Pathname, Array<String, Pathname>] path limiter input
    #
    # @return [Git::Log] the current query builder
    #
    def path(path)          = set_option(:path_limiter, path)

    # Skips a number of commits before returning results
    #
    # @param num [Integer] the number of commits to skip
    #
    # @return [Git::Log] the current query builder
    #
    def skip(num)           = set_option(:skip, num)

    # Includes only commits newer than the given date expression
    #
    # @param date [String] a git-compatible date expression
    #
    # @return [Git::Log] the current query builder
    #
    def since(date)         = set_option(:since, date)

    # Includes only commits older than the given date expression
    #
    # @param date [String] a git-compatible date expression
    #
    # @return [Git::Log] the current query builder
    #
    def until(date)         = set_option(:until, date)

    # Limits commits to the given revision range
    #
    # @param val1 [String] the first revision
    #
    # @param val2 [String, nil] the second revision; when `nil`, validation fails
    #   at execution time
    #
    # @return [Git::Log] the current query builder
    #
    def between(val1, val2 = nil) = set_option(:between, [val1, val2])

    # Omits commits equivalent to cherry-picked commits
    #
    # @return [Git::Log] the current query builder
    #
    def cherry              = set_option(:cherry, true)

    # Includes only merge commits
    #
    # @return [Git::Log] the current query builder
    #
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
      @commits.size
    end

    # @deprecated Use {#execute} and call `to_s` on the result.
    def to_s
      Git::Deprecation.warn(
        'Calling Git::Log#to_s is deprecated. Call #execute and then #to_s on the result object.'
      )
      run_log_if_dirty
      @commits.join("\n")
    end

    # @deprecated Use {#execute} and call the method on the result.
    def first
      Git::Deprecation.warn(
        'Calling Git::Log#first is deprecated. Call #execute and then #first on the result object.'
      )
      run_log_if_dirty
      @commits.first
    end

    # @deprecated Use {#execute} and call the method on the result.
    def last
      Git::Deprecation.warn(
        'Calling Git::Log#last is deprecated. Call #execute and then #last on the result object.'
      )
      run_log_if_dirty
      @commits.last
    end

    # @param index [Integer, Range] the commit index or range to retrieve
    #
    # @return [Git::Object::Commit, Array<Git::Object::Commit>, nil] the selected
    #   commit or commits
    #
    # @deprecated Use {#execute} and call the method on the result.
    #
    def [](index)
      Git::Deprecation.warn(
        'Calling Git::Log#[] is deprecated. Call #execute and then #[] on the result object.'
      )
      run_log_if_dirty
      @commits[index]
    end

    # @!endgroup

    private

    # Sets a log query option and marks cached results dirty
    #
    # @param key [Symbol] the option key
    #
    # @param value [Object] the option value
    #
    # @return [Git::Log] the current query builder
    #
    def set_option(key, value)
      @dirty = true
      @options[key] = value
      self
    end

    # @return [Git::Repository]
    #
    def log_repository
      @base
    end

    # Refreshes cached commits when query options have changed
    #
    # @return [void]
    #
    # @raise [ArgumentError] if configured query options are invalid
    #
    # @raise [Git::FailedError] if the underlying `git log` command fails
    #
    def run_log_if_dirty
      return unless @dirty

      log_data = log_repository.full_log_commits(@options)
      @commits = log_data.map { |c| Git::Object::Commit.new(@base, c['sha'], c) }
      @dirty = false
    end
  end
end
