# frozen_string_literal: true

require 'git/command_line'

module Git
  module CommandLine
    # Executes a git command and captures both stdout and stderr in memory
    #
    # {Git::CommandLine::Capturing} is the buffering strategy: it calls
    # `ProcessExecuter.run_with_capture`, which reads all subprocess output into
    # `String` objects before returning.  Use this class (via
    # {Git::Lib#command_capturing}) for the vast majority of git subcommands whose
    # output fits comfortably in memory.
    #
    # {Git::CommandLine::Streaming} is the complementary strategy for commands
    # (such as `cat-file -p <blob>`) whose stdout may be too large to buffer.
    #
    # @example
    #   capturing = Git::CommandLine::Capturing.new(
    #     {}, '/usr/bin/git', %w[--git-dir /repo/.git], Logger.new($stdout)
    #   )
    #   result = capturing.run('log', '--oneline', '-5')
    #   result.stdout   # => "abc1234 Initial commit\n..."
    #   result.stderr   # => ""
    #
    # @see Git::Lib#command_capturing
    #
    # @see Git::CommandLine::Streaming
    #
    class Capturing < Git::CommandLine::Base
      # Default options accepted by {#run}
      #
      # @api private
      RUN_OPTION_DEFAULTS = {
        in: nil,
        out: nil,
        err: nil,
        chdir: nil,
        timeout: nil,
        raise_on_failure: true,
        env: {},
        normalize: false,
        chomp: false,
        merge: false
      }.freeze

      # Execute a git command, capture stdout and stderr, and return the result
      #
      # Non-option command-line arguments to pass to git. If you collect the
      # arguments in an array, splat the array into the parameter list.
      #
      # NORMALIZATION
      #
      # The command output is returned as a Unicode string containing the binary
      # output from the command.  If the binary output is not valid UTF-8, the
      # output will cause problems because the encoding will be invalid.
      #
      # Normalization is a process that tries to convert the binary output to a
      # valid UTF-8 string.  It uses the `rchardet` gem to detect the encoding of
      # the binary output and then converts it to UTF-8.
      #
      # Normalization is not enabled by default.  Pass `normalize: true` to enable
      # it. When enabled, normalization is applied to both stdout and stderr in
      # the returned result object, regardless of the `out:` or `err:` options.
      # Only the captured in-memory strings are normalized; any external IO you
      # provide will receive the raw subprocess output.
      #
      # @example Run a command and return the output
      #   result = capturing.run('version')
      #   result.stdout #=> "git version 2.39.1\n"
      #
      # @example The args array should be splatted into the parameter list
      #   args = %w[log -n 1 --oneline]
      #   result = capturing.run(*args)
      #   result.stdout #=> "f5baa11 beginning of Ruby/Git project\n"
      #
      # @example Run a command and return the chomped output
      #   result = capturing.run('version', chomp: true)
      #   result.stdout #=> "git version 2.39.1"
      #
      # @example Run a command without normalizing the output
      #   capturing.run('version', normalize: false) #=> "git version 2.39.1\n"
      #
      # @example Capture stdout in a temporary file
      #   require 'tempfile'
      #   Tempfile.create('git') do |file|
      #     capturing.run('version', out: file)
      #     file.rewind
      #     file.read #=> "git version 2.39.1\n"
      #   end
      #
      # @example Capture stderr in a StringIO object
      #   require 'stringio'
      #   stderr = StringIO.new
      #   begin
      #     capturing.run('log', 'nonexistent-branch', err: stderr)
      #   rescue Git::FailedError => e
      #     stderr.string #=> "unknown revision or path not in the working tree.\n"
      #   end
      #
      # @param options_hash [Hash] the options to pass to the command
      #
      # @option options_hash [IO, nil] :in the IO object to use as stdin for the
      #   command, or nil to inherit the parent process stdin.  Must be a real IO
      #   object with a file descriptor (not StringIO).
      #
      # @option options_hash [#write, nil] :out the object to write stdout to, or
      #   nil to capture stdout in the returned result.
      #
      #   If this is a `StringIO` object, `stdout_writer.string` will be returned.
      #
      #   In general, only specify a `stdout_writer` when you want to redirect
      #   stdout to a file or other `#write`-responding object.  The default
      #   behaviour returns the command output.
      #
      # @option options_hash [#write, nil] :err the object to write stderr to, or
      #   nil to capture stderr in the returned result.
      #
      # @option options_hash [Boolean] :normalize (false) whether to normalize the
      #   encoding of stdout and stderr output
      #
      # @option options_hash [Boolean] :chomp (false) whether to chomp both stdout
      #   and stderr output
      #
      # @option options_hash [Boolean] :merge (false) whether to merge stdout and
      #   stderr in the returned string
      #
      # @option options_hash [String, nil] :chdir the directory to run the command in
      #
      # @option options_hash [Numeric, nil] :timeout the maximum seconds to wait for
      #   the command to complete.  Zero means no timeout.  A timeout kills the
      #   process via `SIGKILL` and raises {Git::TimeoutError}.
      #
      # @option options_hash [Boolean] :raise_on_failure (true) whether to raise
      #   {Git::FailedError} on non-zero exit status.
      #   {Git::TimeoutError} and {Git::SignaledError} are always raised regardless.
      #
      # @option options_hash [Hash] :env ({}) additional environment variable
      #   overrides for this command.  String keys map to String values (to set) or
      #   `nil` (to unset).
      #
      # @return [Git::CommandLineResult] the result of the command
      #
      # @raise [ArgumentError] if `args` contains an array or an unknown option is
      #   passed
      #
      # @raise [Git::SignaledError] if the command was terminated by an uncaught signal
      #
      # @raise [Git::FailedError] if the command returned a non-zero exit status
      #
      # @raise [Git::ProcessIOError] if an exception was raised while collecting
      #   subprocess output
      #
      # @raise [Git::TimeoutError] if the command times out
      #
      def run(*, **options_hash)
        options = merge_and_validate_options(RUN_OPTION_DEFAULTS, options_hash)

        result = execute(*, **options)
        process_result(result, options)
      end

      private

      # @return [ProcessExecuter::ResultWithCapture] the process result with captured output
      #
      # @api private
      def execute(*args, **options_hash)
        git_cmd = build_git_cmd(args)
        options = execute_options(**options_hash)
        run_process_executer do
          ProcessExecuter.run_with_capture(merged_env(options_hash), *git_cmd, **options)
        end
      end

      # Build the ProcessExecuter options hash for a capturing run
      #
      # @return [Hash]
      #
      # @api private
      def execute_options(**options_hash)
        chdir = options_hash[:chdir] || :not_set
        timeout_after = options_hash[:timeout]
        merge_output = options_hash[:merge] || false

        { chdir:, timeout_after:, merge_output:, raise_errors: false }.tap do |options|
          redirect_options(options_hash).each { |k, v| options[k] = v }
        end
      end

      # Extract non-nil redirect options (`:in`, `:out`, `:err`) from options_hash
      #
      # @return [Hash]
      #
      # @api private
      def redirect_options(options_hash)
        %i[in out err].filter_map do |key|
          val = options_hash[key]
          [key, val] unless val.nil?
        end.to_h
      end

      # Post-process and return the stdout/stderr strings from the captured result,
      # then log and raise on failure if required.
      #
      # @param result [ProcessExecuter::ResultWithCapture] the raw result
      #
      # @param options [Hash] the merged run options
      #
      # @return [Git::CommandLineResult]
      #
      # @raise [Git::FailedError] if the command failed and raise_on_failure is true
      #
      # @raise [Git::SignaledError] if the command was signaled
      #
      # @raise [Git::TimeoutError] if the command timed out
      #
      # @api private
      def process_result(result, options)
        command = result.command
        processed_out, processed_err = post_process_output(result, options[:normalize], options[:chomp])
        log_result(result, command, processed_out, processed_err)
        command_line_result(
          command, result, processed_out, processed_err, options[:timeout], options[:raise_on_failure]
        )
      end

      # Normalize and/or chomp the raw stdout and stderr strings.
      #
      # @param result [ProcessExecuter::ResultWithCapture] the raw result
      #
      # @param normalize [Boolean]
      #
      # @param chomp [Boolean]
      #
      # @return [Array<String>] two-element array: [processed_stdout, processed_stderr]
      #
      # @api private
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
end
