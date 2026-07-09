# frozen_string_literal: true

require 'git/commands/log'
require 'git/log'
require 'git/repository/shared_private'

module Git
  class Repository
    # Facade methods for querying commit history
    #
    # Included by {Git::Repository}.
    #
    # @api private
    #
    module Logging
      # Allowed option keys for {#full_log_commits}
      #
      # @return [Array<Symbol>] the supported option keys
      #
      FULL_LOG_COMMITS_ALLOWED_OPTS = %i[
        count all cherry since until grep author between object path_limiter skip merges
      ].freeze
      private_constant :FULL_LOG_COMMITS_ALLOWED_OPTS

      # Returns commits within the given revision range
      #
      # @example Return commits from all refs
      #   repo.full_log_commits(all: true).first['sha']
      #   #=> "a1b2c3d4..."
      #
      # @example Return commits between two revisions
      #   repo.full_log_commits(between: ['v1.0.0', 'HEAD']).map { |c| c['sha'] }
      #   #=> ["d4e5f6...", "a1b2c3..."]
      #
      # @param opts [Hash] options for the log query
      #
      # @option opts [Integer, nil] :count (nil) maximum number of commits to return
      #
      # @option opts [Boolean, nil] :all (nil) include commits reachable from any ref
      #
      # @option opts [Boolean, nil] :cherry (nil) omit commits equivalent to
      #   cherry-picked commits
      #
      # @option opts [String] :since (nil) include commits newer than this date expression
      #
      # @option opts [String] :until (nil) include commits older than this date expression
      #
      # @option opts [String] :grep (nil) only include commits whose message matches
      #   this pattern
      #
      # @option opts [String] :author (nil) only include commits whose author matches
      #   this pattern
      #
      # @option opts [Array(String, String), nil] :between (nil) revision range as
      #   two commit-ish values
      #
      #   When both `:between` and `:object` are provided, `:between` takes precedence.
      #
      # @option opts [String] :object (nil) single revision range expression for
      #   `git log`
      #
      #   Ignored when `:between` is provided.
      #
      # @option opts [String, Pathname, Array<String, Pathname>, nil] :path_limiter (nil)
      #   only include commits that impact files from the specified path(s)
      #
      # @option opts [Integer, nil] :skip (nil) skip this many commits before output
      #
      # @option opts [Boolean, nil] :merges (nil) include only merge commits
      #
      # @return [Array<Hash>] the parsed raw log output for each commit
      #
      # @raise [ArgumentError] if unsupported options are provided
      #
      # @raise [ArgumentError] if `:count` is not an Integer
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      # @see https://git-scm.com/docs/git-log git-log
      #
      def full_log_commits(opts = {})
        SharedPrivate.assert_valid_opts!(FULL_LOG_COMMITS_ALLOWED_OPTS, **opts)
        Private.validate_log_count_option!(opts)
        Private.validate_log_between_option!(opts)

        call_opts = Private.log_base_call_options(opts, skip: opts[:skip], merges: opts[:merges])
        revision_range_args = Private.log_revision_range_args(opts)
        Private.run_log_command(@execution_context, revision_range_args, call_opts)
      end

      # Returns a new {Git::Log} query builder scoped to this repository
      #
      # @example Build a log query and execute it
      #   results = repo.log(50).author('Alice').since('2 weeks ago').execute
      #   results.each { |commit| puts commit.sha }
      #
      # @param count [Integer, Symbol, nil] the maximum number of commits to return,
      #   or `:all` / `nil` to return all commits; passed directly to {Git::Log#initialize}
      #
      # @return [Git::Log] a new log query builder
      #
      # @see Git::Log
      #
      def log(count = 30)
        Git::Log.new(self, count)
      end

      # Internal helpers for {Logging} that should not be mixed into
      # {Git::Repository} instances
      #
      # @api private
      #
      module Private
        module_function

        # Validates the :count log option
        #
        # @param opts [Hash] the log options
        #
        # @option opts [Integer, nil] :count (nil) the maximum number of commits to
        #   return
        #
        # @return [void]
        #
        # @raise [ArgumentError] if the log count option is not an Integer
        #
        def validate_log_count_option!(opts)
          return if opts[:count].nil? || opts[:count].is_a?(Integer)

          raise ArgumentError, "The log count option must be an Integer but was #{opts[:count].inspect}"
        end

        # Validates the :between log option
        #
        # @param opts [Hash] the log options
        #
        # @option opts [Array(String, String), nil] :between (nil) the two-commit
        #   revision range to validate
        #
        # @return [void]
        #
        # @raise [ArgumentError] if the :between option is not an Array with exactly
        #   two non-nil values
        #
        def validate_log_between_option!(opts)
          between = opts[:between]
          return if between.nil?
          return if between.is_a?(Array) && between.length == 2 && between.none?(&:nil?)

          raise ArgumentError,
                "The log between option must be an Array with exactly two non-nil values but was #{between.inspect}"
        end

        # Builds positional revision arguments for `git log`
        #
        # @param opts [Hash] the log options
        #
        # @option opts [Array(String, String), nil] :between (nil) a two-revision
        #   range where index `0` is the start and index `1` is the end
        #
        # @option opts [String, nil] :object (nil) a single revision range expression
        #
        # @return [Array<String>] zero or one positional revision arguments
        #
        def log_revision_range_args(opts)
          if opts[:between]
            ["#{opts[:between][0]}..#{opts[:between][1]}"]
          elsif opts[:object].is_a?(String)
            [opts[:object]]
          else
            []
          end
        end

        # Builds keyword options passed to {Git::Commands::Log#call}
        #
        # @param opts [Hash] the log options
        #
        # @param extra [Hash] additional keyword options merged into the call options
        #
        # @option opts [Boolean, nil] :all (nil) include commits reachable from any ref
        #
        # @option opts [Boolean, nil] :cherry (nil) omit commits equivalent to
        #   cherry-picked commits
        #
        # @option opts [String, nil] :since (nil) include commits newer than this date
        #   expression
        #
        # @option opts [String, nil] :until (nil) include commits older than this date
        #   expression
        #
        # @option opts [String, nil] :grep (nil) only include commits whose message
        #   matches this pattern
        #
        # @option opts [String, nil] :author (nil) only include commits whose author
        #   matches this pattern
        #
        # @option opts [Integer, nil] :count (nil) maximum number of commits to return
        #
        # @option opts [String, Pathname, Array<String, Pathname>, nil] :path_limiter (nil)
        #   only include commits that impact files from the specified path(s)
        #
        # @option extra [Integer, nil] :skip (nil) skip this many commits before output
        #
        # @option extra [Boolean, nil] :merges (nil) include only merge commits
        #
        # @return [Hash] keyword options for {Git::Commands::Log#call}
        #
        def log_base_call_options(opts, extra = {})
          {
            all: opts[:all],
            cherry: opts[:cherry],
            since: opts[:since],
            until: opts[:until],
            grep: opts[:grep],
            author: opts[:author],
            max_count: opts[:count],
            path: opts[:path_limiter] ? Array(opts[:path_limiter]) : nil
          }.merge(extra).compact
        end

        # Executes git log and parses the raw output
        #
        # @param execution_context [Git::ExecutionContext] the execution context
        #
        # @param revision_range_args [Array<String>] positional revision range arguments
        #
        # @param call_opts [Hash] keyword options for {Git::Commands::Log#call}
        #
        # @return [Array<Hash>] parsed commits from the command output
        #
        # @raise [Git::FailedError] if git exits with a non-zero exit status
        #
        def run_log_command(execution_context, revision_range_args, call_opts)
          log_or_empty_on_unborn do
            result = Git::Commands::Log.new(execution_context).call(
              *revision_range_args,
              no_color: true,
              pretty: 'raw',
              **call_opts
            )
            RawLogParser.new(result.stdout.split("\n")).parse
          end
        end

        # Returns an empty result when the repository has no commits yet
        #
        # @return [Array<Hash>] parsed commits or an empty array for unborn repositories
        #
        # @raise [Git::FailedError] if git fails for a reason other than unborn history
        #
        # @yield [] runs the wrapped log command
        #
        # @yieldreturn [Array<Hash>] the parsed commits from the wrapped command
        #
        def log_or_empty_on_unborn
          yield
        rescue Git::FailedError => e
          raise unless e.result.status.exitstatus == 128 &&
                       e.result.stderr =~ /does not have any commits yet/

          []
        end

        # Parser for `git log --pretty=raw` output into commit hashes
        #
        # @api private
        #
        class RawLogParser
          # Initializes a parser for raw git log output lines
          #
          # @param lines [Array<String>] raw output lines from `git log --pretty=raw`
          #
          # @return [void]
          #
          def initialize(lines)
            @lines = lines
            @commits = []
            @current_commit = nil
            @in_message = false
            @last_metadata_key = nil
          end

          # Parse raw `git log --pretty=raw` lines into commit hashes
          #
          # @return [Array<Hash>] the parsed commits in command output order
          #
          def parse
            @lines.each { |line| process_line(line.chomp) }
            finalize_commit
            @commits
          end

          private

          # Routes a raw line to message or metadata parsing
          #
          # @param line [String] the current raw log output line
          #
          # @return [void]
          #
          def process_line(line)
            if line.empty?
              @in_message = !@in_message
              return
            end

            @in_message = false if @in_message && !line.start_with?('    ')

            @in_message ? process_message_line(line) : process_metadata_line(line)
          end

          # Appends a commit message line to the current commit buffer
          #
          # @param line [String] an indented message line from raw output
          #
          # @return [void]
          #
          def process_message_line(line)
            @current_commit['message'] << "#{line[4..]}\n"
          end

          # Parses metadata lines and multi-line metadata continuations
          #
          # @param line [String] a metadata line from raw output
          #
          # @return [void]
          #
          def process_metadata_line(line)
            if line.start_with?(' ') && @last_metadata_key
              @current_commit[@last_metadata_key] << "\n#{line[1..]}"
              return
            end

            key, *value = line.split
            value = value.join(' ')
            @last_metadata_key = nil
            dispatch_metadata_key(key, value)
          end

          # Applies a metadata key/value pair to the current commit
          #
          # @param key [String] the metadata key from the raw log line
          #
          # @param value [String] the parsed metadata value
          #
          # @return [void]
          #
          def dispatch_metadata_key(key, value)
            case key
            when 'commit'
              start_new_commit(value)
            when 'parent'
              @current_commit['parent'] << value
            else
              @current_commit[key] = value
              @last_metadata_key = key
            end
          end

          # Starts a new commit record in the parser state
          #
          # @param sha [String] the commit SHA for the new record
          #
          # @return [void]
          #
          def start_new_commit(sha)
            finalize_commit
            @current_commit = { 'sha' => sha, 'message' => +'', 'parent' => [] }
            @last_metadata_key = nil
          end

          # Appends the current commit to the parsed results when present
          #
          # @return [void]
          #
          def finalize_commit
            @commits << @current_commit if @current_commit
          end
        end
        private_constant :RawLogParser
      end
      private_constant :Private
    end
  end
end
