# frozen_string_literal: true

require 'git/command_line'
require 'git/errors'

module Git
  module CommandLine
    # Abstract base class for git command-line execution strategies
    #
    # Concrete subclasses must implement {#run} to execute a git command and
    # return a {Git::CommandLine::Result}. Two implementations are provided:
    #
    # * {Git::CommandLine::Capturing} — buffers stdout and stderr in memory
    # * {Git::CommandLine::Streaming} — streams stdout to a caller-supplied IO
    #
    # @example Instantiate a concrete subclass
    #   env = { 'GIT_DIR' => '/path/to/git/dir' }
    #   binary_path = '/usr/bin/git'
    #   global_opts = %w[--git-dir /path/to/git/dir]
    #   logger = Logger.new($stdout)
    #   cli = Git::CommandLine::Capturing.new(env, binary_path, global_opts, logger)
    #   cli.run('version') #=> #<Git::CommandLine::Result ...>
    #
    # @abstract Subclass and implement {#run}
    #
    # @api public
    #
    class Base
      # Create a Base (or subclass) object
      #
      # @param env [Hash{String => String, nil}] environment variables to set or
      #   unset. String values set the variable; `nil` values unset it.
      #
      # @param binary_path [String] the path to the git binary
      #
      # @param global_opts [Array<String>] global options to pass to git
      #
      # @param logger [Logger] the logger to use
      #
      def initialize(env, binary_path, global_opts, logger)
        @env = env
        @binary_path = binary_path
        @global_opts = global_opts
        @logger = logger
      end

      # Execute a git command and return the result
      #
      # Concrete subclasses must override this method.
      #
      # @raise [NotImplementedError] always — must be implemented by subclasses
      #
      def run(*)
        raise NotImplementedError, "#{self.class}#run is not implemented"
      end

      # @attribute [r] env
      #
      # Variables to set (or unset) in the git command's environment
      #
      # @example
      #   env = { 'GIT_DIR' => '/path/to/git/dir' }
      #   cli = Git::CommandLine::Capturing.new(env, '/usr/bin/git', [], Logger.new(nil))
      #   cli.env #=> { 'GIT_DIR' => '/path/to/git/dir' }
      #
      # @return [Hash{String => String, nil}]
      #
      # @see https://ruby-doc.org/3.2.1/Process.html#method-c-spawn Process.spawn
      #   for details on how to set environment variables using the `env` parameter
      #
      attr_reader :env

      # @attribute [r] binary_path
      #
      # The path to the command line binary to run
      #
      # @example
      #   cli = Git::CommandLine::Capturing.new({}, '/usr/bin/git', [], Logger.new(nil))
      #   cli.binary_path #=> '/usr/bin/git'
      #
      # @return [String]
      #
      attr_reader :binary_path

      # @attribute [r] global_opts
      #
      # The global options to pass to git
      #
      # These are options that are passed to git before the command name and
      # arguments. For example, in `git --git-dir /path/to/git/dir version`, the
      # global options are %w[--git-dir /path/to/git/dir].
      #
      # @example
      #   global_opts = %w[--git-dir /path/to/git/dir]
      #   cli = Git::CommandLine::Capturing.new({}, '/usr/bin/git', global_opts, Logger.new(nil))
      #   cli.global_opts #=> %w[--git-dir /path/to/git/dir]
      #
      # @return [Array<String>]
      #
      attr_reader :global_opts

      # @attribute [r] logger
      #
      # The logger to use for logging git commands and results
      #
      # @example
      #   logger = Logger.new(nil)
      #   cli = Git::CommandLine::Capturing.new({}, '/usr/bin/git', [], logger)
      #   cli.logger == logger #=> true
      #
      # @return [Logger]
      #
      attr_reader :logger

      private

      # Merge caller-supplied options into `defaults` and raise if any unknown keys are present
      #
      # @param defaults [Hash] the allowed keys and their default values (e.g. RUN_OPTION_DEFAULTS)
      #
      # @param options_hash [Hash] caller-supplied options
      #
      # @return [Hash] defaults with any supplied values overridden
      #
      # @raise [ArgumentError] if options_hash contains keys not present in defaults
      #
      # @api private
      #
      def merge_and_validate_options(defaults, options_hash)
        merged = defaults.merge(options_hash)
        extra = merged.keys - defaults.keys
        raise ArgumentError, "Unknown options: #{extra.join(', ')}" if extra.any?

        merged
      end

      # Merge the instance-level env with any per-call overrides in options_hash[:env]
      #
      # @param options_hash [Hash] options that may include an :env override
      #
      # @return [Hash{String => String, nil}]
      #
      # @api private
      #
      def merged_env(options_hash)
        env.merge(options_hash[:env] || {})
      end

      # Yield to a block that calls ProcessExecuter and translate any ProcessExecuter
      # errors to their ruby-git equivalents
      #
      # @raise [ArgumentError] in place of ProcessExecuter::ArgumentError
      #
      # @raise [Git::ProcessIOError] in place of ProcessExecuter::ProcessIOError
      #
      # @return [Object] the return value of the block
      #
      # @api private
      #
      def run_process_executer
        yield
      rescue ProcessExecuter::ArgumentError => e
        raise ::ArgumentError, e.message
      rescue ProcessExecuter::ProcessIOError => e
        raise Git::ProcessIOError, e.message, cause: e.cause
      end

      # Build the git command line from the available sources to send to `Process.spawn`
      #
      # @param args [Array<String>] command-line arguments to append after global options
      #
      # @return [Array<String>]
      #
      # @raise [ArgumentError] if any element of args is itself an Array
      #
      # @api private
      #
      def build_git_cmd(args)
        raise ArgumentError, 'The args array can not contain an array' if args.any?(Array)

        [binary_path, *global_opts, *args].map(&:to_s)
      end

      # Log the result of a git command at info/debug level
      #
      # @param result [ProcessExecuter::Result] the raw process result
      #
      # @param command [Array<String>] the full command that was run
      #
      # @param processed_out [String] the post-processed stdout string
      #
      # @param processed_err [String] the post-processed stderr string
      #
      # @return [void]
      #
      # @api private
      #
      def log_result(result, command, processed_out, processed_err)
        logger.info { "#{command} exited with status #{result}" }
        logger.debug { "stdout:\n#{processed_out.inspect}\nstderr:\n#{processed_err.inspect}" }
      end

      # Build a {Git::CommandLine::Result} and raise on timeout, signal, or failure
      #
      # @param command [Array<String>] the full command that was run
      #
      # @param result [ProcessExecuter::Result] the raw process result
      #
      # @param processed_out [String] processed stdout string
      #
      # @param processed_err [String] processed stderr string
      #
      # @param timeout [Numeric, nil] the timeout value (for error context)
      #
      # @param raise_on_failure [Boolean] whether to raise on non-zero exit status
      #
      # @return [Git::CommandLine::Result]
      #
      # @raise [Git::TimeoutError] if the command timed out
      #
      # @raise [Git::SignaledError] if the command was terminated by a signal
      #
      # @raise [Git::FailedError] if the command failed and raise_on_failure is true
      #
      # @api private
      #
      # rubocop:disable Metrics/ParameterLists
      def command_line_result(command, result, processed_out, processed_err, timeout, raise_on_failure)
        Git::CommandLine::Result.new(command, result, processed_out, processed_err).tap do |processed_result|
          raise Git::TimeoutError.new(processed_result, timeout) if result.timed_out?

          raise Git::SignaledError, processed_result if result.signaled?

          raise Git::FailedError, processed_result if raise_on_failure && !result.success?
        end
      end
      # rubocop:enable Metrics/ParameterLists
    end
  end
end
