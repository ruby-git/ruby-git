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
  class CommandLine
    # Create a Git::CommandLine object
    #
    # @example
    #   env = { 'GIT_DIR' => '/path/to/git/dir' }
    #   binary_path = '/usr/bin/git'
    #   global_opts = %w[--git-dir /path/to/git/dir]
    #   logger = Logger.new(STDOUT)
    #   cli = CommandLine.new(env, binary_path, global_opts, logger)
    #   cli.run('version') #=> #<Git::CommandLineResult:0x00007f9b0c0b0e00
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
    # Normalization is not enabled by default. Pass `normalize: true` to Git::CommandLine#run
    # to enable it. Normalization will only be performed on stdout and only if the `out:`` option
    # is nil or is a StringIO object. If the out: option is set to a file or other IO object,
    # the normalize option will be ignored.
    #
    # @example Run a command and return the output
    #   cli.run('version') #=> "git version 2.39.1\n"
    #
    # @example The args array should be splatted into the parameter list
    #   args = %w[log -n 1 --oneline]
    #   cli.run(*args) #=> "f5baa11 beginning of Ruby/Git project\n"
    #
    # @example Run a command and return the chomped output
    #   cli.run('version', chomp: true) #=> "git version 2.39.1"
    #
    # @example Run a command and without normalizing the output
    #   cli.run('version', normalize: false) #=> "git version 2.39.1\n"
    #
    # @example Capture stdout in a temporary file
    #   require 'tempfile'
    #   tempfile = Tempfile.create('git') do |file|
    #     cli.run('version', out: file)
    #     file.rewind
    #     file.read #=> "git version 2.39.1\n"
    #   end
    #
    # @example Capture stderr in a StringIO object
    #   require 'stringio'
    #   stderr = StringIO.new
    #   begin
    #     cli.run('log', 'nonexistent-branch', err: stderr)
    #   rescue Git::FailedError => e
    #     stderr.string #=> "unknown revision or path not in the working tree.\n"
    #   end
    #
    # @param options_hash [Hash] the options to pass to the command
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
    def run(*, **options_hash)
      options_hash = RUN_ARGS.merge(options_hash)
      extra_options = options_hash.keys - RUN_ARGS.keys
      raise ArgumentError, "Unknown options: #{extra_options.join(', ')}" if extra_options.any?

      result = run_with_capture(*, **options_hash)
      process_result(result, options_hash[:normalize], options_hash[:chomp], options_hash[:timeout],
                     options_hash[:raise_on_failure])
    end

    # @return [Git::CommandLineResult] the result of running the command
    #
    # @api private
    #
    def run_with_capture(*args, **options_hash)
      git_cmd = build_git_cmd(args)
      options = run_with_capture_options(**options_hash)
      merged_env = env.merge(options_hash[:env] || {})
      ProcessExecuter.run_with_capture(merged_env, *git_cmd, **options)
    rescue ProcessExecuter::ProcessIOError => e
      raise Git::ProcessIOError.new(e.message), cause: e.exception.cause
    end

    def run_with_capture_options(**options_hash)
      chdir = options_hash[:chdir] || :not_set
      timeout_after = options_hash[:timeout]
      out = options_hash[:out]
      err = options_hash[:err]
      merge_output = options_hash[:merge] || false

      { chdir:, timeout_after:, merge_output:, raise_errors: false }.tap do |options|
        options[:out] = out unless out.nil?
        options[:err] = err unless err.nil?
      end
    end

    RUN_ARGS = {
      normalize: false,
      chomp: false,
      merge: false,
      out: nil,
      err: nil,
      chdir: nil,
      timeout: nil,
      raise_on_failure: true,
      env: {}
    }.freeze

    private

    # Build the git command line from the available sources to send to `Process.spawn`
    # @return [Array<String>]
    # @api private
    #
    def build_git_cmd(args)
      raise ArgumentError, 'The args array can not contain an array' if args.any? { |a| a.is_a?(Array) }

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
end
