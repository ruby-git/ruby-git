module Git

  # Return the last n commits that match the specified criteria
  #
  # @example The last (default number) of commits
  #   git = Git.open('.')
  #   Git::Log.new(git) #=> Enumerable of the last 30 commits
  #
  # @example The last n commits
  #   Git::Log.new(git).max_commits(50) #=> Enumerable of last 50 commits
  #
  # @example All commits returned by `git log`
  #   Git::Log.new(git).max_count(:all) #=> Enumerable of all commits
  #
  # @example All commits that match complex criteria
  #   Git::Log.new(git)
  #     .max_count(:all)
  #     .object('README.md')
  #     .since('10 years ago')
  #     .between('v1.0.7', 'HEAD')
  #
  # @api public
  #
  class Log
    include Enumerable

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
      @max_count = (num_or_all == :all) ? nil : num_or_all
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
      return self
    end

    def author(regex)
      dirty_log
      @author = regex
      return self
    end

    def grep(regex)
      dirty_log
      @grep = regex
      return self
    end

    def path(path)
      dirty_log
      @path = path
      return self
    end

    def skip(num)
      dirty_log
      @skip = num
      return self
    end

    def since(date)
      dirty_log
      @since = date
      return self
    end

    def until(date)
      dirty_log
      @until = date
      return self
    end

    def between(sha1, sha2 = nil)
      dirty_log
      @between = [sha1, sha2]
      return self
    end

    def cherry
      dirty_log
      @cherry = true
      return self
    end

    def to_s
      self.map { |c| c.to_s }.join("\n")
    end


    # forces git log to run

    def size
      check_log
      @commits.size rescue nil
    end

    def each(&block)
      check_log
      @commits.each(&block)
    end

    def first
      check_log
      @commits.first rescue nil
    end

    def last
      check_log
      @commits.last rescue nil
    end

    def [](index)
      check_log
      @commits[index] rescue nil
    end


    private

      def dirty_log
        @dirty_flag = true
      end

      def check_log
        if @dirty_flag
          run_log
          @dirty_flag = false
        end
      end

      # actually run the 'git log' command
      def run_log
        log = @base.lib.full_log_commits(
          count: @max_count, all: @all, object: @object, path_limiter: @path, since: @since,
          author: @author, grep: @grep, skip: @skip, until: @until, between: @between,
          cherry: @cherry
        )
        @commits = log.map { |c| Git::Object::Commit.new(@base, c['sha'], c) }
      end

  end

end
