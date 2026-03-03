# frozen_string_literal: true

require 'git/base'
require 'git/command_line_result'
require 'git/errors'
require 'stringio'

module Git
  # Runs a git command and returns the result
  #
  # @api public
  #
  # rubocop:disable Metrics/ClassLength
  class CommandLine
    # Create a Git::CommandLine object
    #
    # @example
    #   env = { 'GIT_DIR' => '/path/to/git/dir' }
    #   binary_path = '/usr/bin/git'
    #   global_opts = %w[--git-dir /path/to/git/dir]
    #   logger = Logger.new(STDOUT)
    #   cli = CommandLine.new(env, binary_path, global_opts, logger)
    #   cli.run_with_capture('version') #=> #<Git::CommandLineResult:0x00007f9b0c0b0e00
    #
    # @param env [Hash<String, String>] environment variables to set
    # @param global_opts [Array<String>] global options to pass to git
    # @param logger [Logger] the logger to use
    #
    def initialize(env, binary_path, global_opts, logger)
      @env = env
      @binary_path = binary_path
      @global_opts = global_opts
      @logger = logger
    end

    # @attribute [r] env
    #
    # Variables to set (or unset) in the git command's environment
    #
    # @example
    #   env = { 'GIT_DIR' => '/path/to/git/dir' }
    #   command_line = Git::CommandLine.new(env, '/usr/bin/git', [], Logger.new(STDOUT))
    #   command_line.env #=> { 'GIT_DIR' => '/path/to/git/dir' }
    #
    # @return [Hash<String, String>]
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
    #   binary_path = '/usr/bin/git'
    #   command_line = Git::CommandLine.new({}, binary_path, ['version'], Logger.new(STDOUT))
    #   command_line.binary_path #=> '/usr/bin/git'
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
    #   env = {}
    #   global_opts = %w[--git-dir /path/to/git/dir]
    #   logger = Logger.new(nil)
    #   cli = CommandLine.new(env, '/usr/bin/git', global_opts, logger)
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
    #   env = {}
    #   global_opts = %w[]
    #   logger = Logger.new(STDOUT)
    #   cli = CommandLine.new(env, '/usr/bin/git', global_opts, logger)
    #   cli.logger == logger #=> true
    #
    # @return [Logger]
    #
    attr_reader :logger

    # Execute a git command, wait for it to finish, and return the result
    #
    # Non-option the command line arguements to pass to git. If you collect
    # the command line arguments in an array, make sure you splat the array
    # into the parameter list.
    #
    # NORMALIZATION
    #
    # The command output is returned as a Unicde string containing the binary output
    # from the command. If the binary output is not valid UTF-8, the output will
    # cause problems because the encoding will be invalid.
    #
    # Normalization is a process that trys to convert the binary output to a valid
    # UTF-8 string. It uses the `rchardet` gem to detect the encoding of the binary
    # output and then converts it to UTF-8.
    #
    # Normalization is not enabled by default. Pass `normalize: true` to Git::CommandLine#run_with_capture
    # to enable it. Normalization will only be performed on stdout and only if the `out:` option
    # is nil or is a StringIO object. If the out: option is set to a file or other IO object,
    # the normalize option will be ignored.
    #
    # @example Run a command and return the output
    #   result = cli.run_with_capture('version')
    #   result.stdout #=> "git version 2.39.1\n"
    #
    # @example The args array should be splatted into the parameter list
    #   args = %w[log -n 1 --oneline]
    #   result = cli.run_with_capture(*args)
    #   result.stdout #=> "f5baa11 beginning of Ruby/Git project\n"
    #
    # @example Run a command and return the chomped output
    #   result = cli.run_with_capture('version', chomp: true)
    #   result.stdout #=> "git version 2.39.1"
    #
    # @example Run a command and without normalizing the output
    #   cli.run_with_capture('version', normalize: false) #=> "git version 2.39.1\n"
    #
    # @example Capture stdout in a temporary file
    #   require 'tempfile'
    #   tempfile = Tempfile.create('git') do |file|
    #     cli.run_with_capture('version', out: file)
    #     file.rewind
    #     file.read #=> "git version 2.39.1\n"
    #   end
    #
    # @example Capture stderr in a StringIO object
    #   require 'stringio'
    #   stderr = StringIO.new
    #   begin
    #     cli.run_with_capture('log', 'nonexistent-branch', err: stderr)
    #   rescue Git::FailedError => e
    #     stderr.string #=> "unknown revision or path not in the working tree.\n"
    #   end
    #
    # @param options_hash [Hash] the options to pass to the command
    #
    # @option options_hash [IO, nil] :in the IO object to use as stdin for the command, or nil to
    #   inherit the parent process stdin. Must be a real IO object with a file descriptor (not StringIO).
    #
    # @option options_hash [#write, nil] :out the object to write stdout to or nil to ignore stdout
    #
    #   If this is a 'StringIO' object, then `stdout_writer.string` will be returned.
    #
    #   In general, only specify a `stdout_writer` object when you want to redirect
    #   stdout to a file or some other object that responds to `#write`. The default
    #   behavior will return the output of the command.
    #
    # @option options_hash [#write, nil] :err the object to write stderr to or nil to ignore stderr
    #
    #   If this is a 'StringIO' object and `merged_output` is `true`, then
    #   `stderr_writer.string` will be merged into the output returned by this method.
    #
    # @option options_hash [Boolean] :normalize whether to normalize the output of stdout and stderr
    #
    # @option options_hash [Boolean] :chomp whether to chomp both stdout and stderr output
    #
    # @option options_hash [Boolean] :merge whether to merge stdout and stderr in the string returned
    #
    # @option options_hash [String, nil] :chdir the directory to run the command in
    #
    # @option options_hash [Numeric, nil] :timeout the maximum seconds to wait for the command to complete
    #
    #   If timeout is zero, the timeout will not be enforced.
    #
    #   If the command times out, it is killed via a `SIGKILL` signal and `Git::TimeoutError` is raised.
    #
    #   If the command does not respond to SIGKILL, it will hang this method.
    #
    # @option options_hash [Boolean] :raise_on_failure whether to raise Git::FailedError on non-zero exit status
    #
    #   Defaults to `true`. When `false`, non-zero exit status will not raise an exception,
    #   but Git::TimeoutError and Git::SignaledError are always raised regardless of this setting.
    #
    # @option options_hash [Hash] :env additional environment variable overrides for this command
    #
    #   These are merged with the environment variables set in the constructor.
    #   Keys should be environment variable names (String) and values should be either:
    #   * A String value to set the environment variable
    #   * `nil` to unset the environment variable
    #
    # @return [Git::CommandLineResult] the output of the command
    #
    #   This result of running the command.
    #
    # @raise [ArgumentError] if `args` is not an array of strings
    #
    # @raise [Git::SignaledError] if the command was terminated because of an uncaught signal
    #
    # @raise [Git::FailedError] if the command returned a non-zero exitstatus
    #
    # @raise [Git::ProcessIOError] if an exception was raised while collecting subprocess output
    #
    # @raise [Git::TimeoutError] if the command times out
    #
    def run_with_capture(*, **options_hash)
      options_hash = RUN_ARGS.merge(options_hash)
      extra_options = options_hash.keys - RUN_ARGS.keys
      raise ArgumentError, "Unknown options: #{extra_options.join(', ')}" if extra_options.any?

      result = execute_with_capture(*, **options_hash)
      process_result(result, options_hash[:normalize], options_hash[:chomp], options_hash[:timeout],
                     options_hash[:raise_on_failure])
    end

    # Execute a git command in streaming mode and return the result
    #
    # Unlike {#run_with_capture}, this method does NOT buffer stdout in memory.
    # Stdout is written only to the IO object provided via the `out:` option.
    # Stderr is captured internally via a +StringIO+ for error diagnostics.
    #
    # Use this entry point for commands that stream large content (e.g. blobs)
    # where capturing stdout in memory would be unacceptable.
    #
    # @example Stream a blob to a file
    #   file = File.open('/tmp/blob', 'wb')
    #   cli.run('cat-file', 'blob', sha, out: file)
    #
    # @param options_hash [Hash] the options to pass to the command
    #
    # @option options_hash [IO, nil] :in the IO object to use as stdin for the command, or nil to
    #   inherit the parent process stdin. Must be a real IO object with a file descriptor (not StringIO).
    #
    # @option options_hash [#write, nil] :out the IO/object to stream stdout into.
    #   Stdout is NOT buffered in the returned result; this is the only way to read it.
    #
    # @option options_hash [String, nil] :chdir the directory to run the command in
    #
    # @option options_hash [Numeric, nil] :timeout the maximum seconds to wait for the command to complete
    #
    #   If timeout is zero, the timeout will not be enforced.
    #
    #   If the command times out, it is killed via a `SIGKILL` signal and `Git::TimeoutError` is raised.
    #
    # @option options_hash [Boolean] :raise_on_failure whether to raise Git::FailedError on non-zero exit status
    #
    #   Defaults to `true`. When `false`, non-zero exit status will not raise an exception,
    #   but Git::TimeoutError and Git::SignaledError are always raised regardless of this setting.
    #
    # @option options_hash [Hash] :env additional environment variable overrides for this command
    #
    # @return [Git::CommandLineResult] the result of the command
    #
    #   `result.stdout` will always be `''` (empty) — stdout was streamed to `out:`.
    #   `result.stderr` contains any stderr output captured for diagnostics.
    #
    # @raise [ArgumentError] if `args` is not an array of strings
    #
    # @raise [Git::SignaledError] if the command was terminated because of an uncaught signal
    #
    # @raise [Git::FailedError] if the command returned a non-zero exitstatus
    #
    # @raise [Git::ProcessIOError] if an exception was raised while collecting subprocess output
    #
    # @raise [Git::TimeoutError] if the command times out
    #
    def run(*, **options_hash)
      options_hash = RUN_STREAMING_ARGS.merge(options_hash)
      extra_options = options_hash.keys - RUN_STREAMING_ARGS.keys
      raise ArgumentError, "Unknown options: #{extra_options.join(', ')}" if extra_options.any?

      err_io = options_hash[:err] || StringIO.new
      result = execute(*, err_io:, **options_hash)
      process_streaming_result(result, err_io, options_hash[:timeout], options_hash[:raise_on_failure])
    end

    RUN_STREAMING_ARGS = {
      in: nil,
      out: nil,
      err: nil,
      chdir: nil,
      timeout: nil,
      raise_on_failure: true,
      env: {}
    }.freeze

    RUN_ARGS = {
      normalize: false,
      chomp: false,
      merge: false,
      in: nil,
      out: nil,
      err: nil,
      chdir: nil,
      timeout: nil,
      raise_on_failure: true,
      env: {}
    }.freeze

    private

    # @return [ProcessExecuter::Result] the result of running the command (non-capturing)
    def execute(*args, err_io:, **options_hash)
      git_cmd = build_git_cmd(args)
      options = execute_options(err_io:, **options_hash)
      merged_env = env.merge(options_hash[:env] || {})
      ProcessExecuter.run(merged_env, *git_cmd, **options)
    rescue ProcessExecuter::ProcessIOError => e
      raise Git::ProcessIOError.new(e.message), cause: e.exception.cause
    end

    def execute_options(err_io:, **options_hash)
      chdir = options_hash[:chdir] || :not_set
      timeout_after = options_hash[:timeout]

      { chdir:, timeout_after:, raise_errors: false, err: err_io }.tap do |options|
        options[:in] = options_hash[:in] unless options_hash[:in].nil?
        options[:out] = options_hash[:out] unless options_hash[:out].nil?
      end
    end

    # Process the result of a streaming command and return a Git::CommandLineResult
    #
    # Constructs stdout as '' (not captured) and stderr from the internal StringIO.
    #
    # @api private
    #
    def process_streaming_result(result, err_io, timeout, raise_on_failure)
      command = result.command
      stderr = err_io.string
      log_result(result, command, '', stderr)
      command_line_result(command, result, '', stderr, timeout, raise_on_failure)
    end

    # @return [Git::CommandLineResult] the result of running the command
    def execute_with_capture(*args, **options_hash)
      git_cmd = build_git_cmd(args)
      options = execute_with_capture_options(**options_hash)
      merged_env = env.merge(options_hash[:env] || {})
      ProcessExecuter.run_with_capture(merged_env, *git_cmd, **options)
    rescue ProcessExecuter::ProcessIOError => e
      raise Git::ProcessIOError.new(e.message), cause: e.exception.cause
    end

    def execute_with_capture_options(**options_hash)
      chdir = options_hash[:chdir] || :not_set
      timeout_after = options_hash[:timeout]
      merge_output = options_hash[:merge] || false

      { chdir:, timeout_after:, merge_output:, raise_errors: false }.tap do |options|
        redirect_options(options_hash).each { |k, v| options[k] = v }
      end
    end

    def redirect_options(options_hash)
      %i[in out err].filter_map do |key|
        val = options_hash[key]
        [key, val] unless val.nil?
      end.to_h
    end

    # Build the git command line from the available sources to send to `Process.spawn`
    # @return [Array<String>]
    # @api private
    #
    def build_git_cmd(args)
      raise ArgumentError, 'The args array can not contain an array' if args.any?(Array)

      [binary_path, *global_opts, *args].map(&:to_s)
    end

    # Process the result of the command and return a Git::CommandLineResult
    #
    # Post process output, log the command and result, and raise an error if the
    # command failed.
    #
    # @param result [ProcessExecuter::Command::Result] the result it is a
    #   Process::Status and include command, stdout, and stderr
    #
    # @param normalize [Boolean] whether to normalize the output of each writer
    #
    # @param chomp [Boolean] whether to chomp the output of each writer
    #
    # @param timeout [Numeric, nil] the maximum seconds to wait for the command to
    #   complete
    #
    # @return [Git::CommandLineResult] the result of the command to return to the
    #   caller
    #
    # @raise [Git::FailedError] if the command failed
    #
    # @raise [Git::SignaledError] if the command was signaled
    #
    # @raise [Git::TimeoutError] if the command times out
    #
    # @raise [Git::ProcessIOError] if an exception was raised while collecting
    #   subprocess output
    #
    # @api private
    #
    def process_result(result, normalize, chomp, timeout, raise_on_failure)
      command = result.command
      processed_out, processed_err = post_process_output(result, normalize, chomp)
      log_result(result, command, processed_out, processed_err)
      command_line_result(command, result, processed_out, processed_err, timeout, raise_on_failure)
    end

    def log_result(result, command, processed_out, processed_err)
      logger.info { "#{command} exited with status #{result}" }
      logger.debug { "stdout:\n#{processed_out.inspect}\nstderr:\n#{processed_err.inspect}" }
    end

    # rubocop:disable Metrics/ParameterLists
    def command_line_result(command, result, processed_out, processed_err, timeout, raise_on_failure)
      Git::CommandLineResult.new(command, result, processed_out, processed_err).tap do |processed_result|
        raise Git::TimeoutError.new(processed_result, timeout) if result.timed_out?

        raise Git::SignaledError, processed_result if result.signaled?

        raise Git::FailedError, processed_result if raise_on_failure && !result.success?
      end
    end
    # rubocop:enable Metrics/ParameterLists

    # Post-process and return an array of raw output strings
    #
    # For each raw output string:
    #
    # * If normalize: is true, normalize the encoding by transcoding each line from
    #   the detected encoding to UTF-8.
    # * If chomp: is true chomp the output after normalization.
    #
    # Even if no post-processing is done based on the options, the strings returned
    # are a copy of the raw output strings. The raw output strings are not modified.
    #
    # @param result [ProcessExecuter::ResultWithCapture] the command's output to post-process
    #
    # @param normalize [Boolean] whether to normalize the output of each writer
    # @param chomp [Boolean] whether to chomp the output of each writer
    #
    # @return [Array<String>]
    #
    # @api private
    #
    def post_process_output(result, normalize, chomp)
      [result.stdout, result.stderr].map do |raw_output|
        output = raw_output.dup
        output = output.lines.map { |l| Git::EncodingUtils.normalize_encoding(l) }.join if normalize
        output.chomp! if chomp
        output
      end
    end
  end
  # rubocop:enable Metrics/ClassLength
end
