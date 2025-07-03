# frozen_string_literal: true

module Git
  # Return the last n commits that match the specified criteria
  #
  # @example The last (default number) of commits
  #   git = Git.open('.')
  #   Git::Log.new(git).execute #=> Enumerable of the last 30 commits
  #
  # @example The last n commits
  #   Git::Log.new(git).max_commits(50).execute #=> Enumerable of last 50 commits
  #
  # @example All commits returned by `git log`
  #   Git::Log.new(git).max_count(:all).execute #=> Enumerable of all commits
  #
  # @example All commits that match complex criteria
  #   Git::Log.new(git)
  #     .max_count(:all)
  #     .object('README.md')
  #     .since('10 years ago')
  #     .between('v1.0.7', 'HEAD')
  #     .execute
  #
  # @api public
  #
  class Log
    include Enumerable

    # An immutable collection of commits returned by Git::Log#execute
    #
    # This object is an Enumerable that contains Git::Object::Commit objects.
    # It provides methods to access the commit data without executing any
    # further git commands.
    #
    # @api public
    class Result
      include Enumerable

      # @private
      def initialize(commits)
        @commits = commits
      end

      # @return [Integer] the number of commits in the result set
      def size
        @commits.size
      end

      # Iterates over each commit in the result set
      #
      # @yield [Git::Object::Commit]
      def each(&)
        @commits.each(&)
      end

      # @return [Git::Object::Commit, nil] the first commit in the result set
      def first
        @commits.first
      end

      # @return [Git::Object::Commit, nil] the last commit in the result set
      def last
        @commits.last
      end

      # @param index [Integer] the index of the commit to return
      # @return [Git::Object::Commit, nil] the commit at the given index
      def [](index)
        @commits[index]
      end

      # @return [String] a string representation of the log
      def to_s
        map { |c| c.to_s }.join("\n")
      end
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
      dirty_log
      @base = base
      max_count(max_count)
    end

    # Executes the git log command and returns an immutable result object.
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
    def execute
      run_log
      Result.new(@commits)
    end

    # The maximum number of commits to return
    #
    # @example All commits returned by `git log`
    #   git = Git.open('.')
    #   Git::Log.new(git).max_count(:all)
    #
    # @param num_or_all [Integer, Symbol, nil] the number of commits to return, or
    #   `:all` or `nil` to return all
    #
    # @return [self]
    #
    def max_count(num_or_all)
      dirty_log
      @max_count = num_or_all == :all ? nil : num_or_all
      self
    end

    # Adds the --all flag to the git log command
    #
    # This asks for the logs of all refs (basically all commits reachable by HEAD,
    # branches, and tags). This does not control the maximum number of commits
    # returned. To control how many commits are returned, call {#max_count}.
    #
    # @example Return the last 50 commits reachable by all refs
    #   git = Git.open('.')
    #   Git::Log.new(git).max_count(50).all
    #
    # @return [self]
    #
    def all
      dirty_log
      @all = true
      self
    end

    def object(objectish)
      dirty_log
      @object = objectish
      self
    end

    def author(regex)
      dirty_log
      @author = regex
      self
    end

    def grep(regex)
      dirty_log
      @grep = regex
      self
    end

    def path(path)
      dirty_log
      @path = path
      self
    end

    def skip(num)
      dirty_log
      @skip = num
      self
    end

    def since(date)
      dirty_log
      @since = date
      self
    end

    def until(date)
      dirty_log
      @until = date
      self
    end

    def between(sha1, sha2 = nil)
      dirty_log
      @between = [sha1, sha2]
      self
    end

    def cherry
      dirty_log
      @cherry = true
      self
    end

    def merges
      dirty_log
      @merges = true
      self
    end

    def to_s
      deprecate_method(__method__)
      check_log
      @commits.map { |c| c.to_s }.join("\n")
    end

    # forces git log to run

    def size
      deprecate_method(__method__)
      check_log
      begin
        @commits.size
      rescue StandardError
        nil
      end
    end

    def each(&)
      deprecate_method(__method__)
      check_log
      @commits.each(&)
    end

    def first
      deprecate_method(__method__)
      check_log
      begin
        @commits.first
      rescue StandardError
        nil
      end
    end

    def last
      deprecate_method(__method__)
      check_log
      begin
        @commits.last
      rescue StandardError
        nil
      end
    end

    def [](index)
      deprecate_method(__method__)
      check_log
      begin
        @commits[index]
      rescue StandardError
        nil
      end
    end

    private

    def deprecate_method(method_name)
      Git::Deprecation.warn("Calling Git::Log##{method_name} is deprecated and will be removed in a future version. Call #execute and then ##{method_name} on the result object.")
    end

    def dirty_log
      @dirty_flag = true
    end

    def check_log
      return unless @dirty_flag

      run_log
      @dirty_flag = false
    end

    # actually run the 'git log' command
    def run_log
      log = @base.lib.full_log_commits(
        count: @max_count, all: @all, object: @object, path_limiter: @path, since: @since,
        author: @author, grep: @grep, skip: @skip, until: @until, between: @between,
        cherry: @cherry, merges: @merges
      )
      @commits = log.map { |c| Git::Object::Commit.new(@base, c['sha'], c) }
    end
  end
end
