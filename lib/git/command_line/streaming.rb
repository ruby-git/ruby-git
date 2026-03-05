# frozen_string_literal: true

require 'git/command_line'
require 'stringio'

module Git
  module CommandLine
    # Executes a git command in streaming mode without buffering stdout in memory
    #
    # {Git::CommandLine::Streaming} is the non-buffering strategy: it calls
    # `ProcessExecuter.run` and streams stdout directly to the caller-supplied `out:`
    # IO object.  Stderr is always captured internally in a `StringIO` for error
    # diagnostics and is available as `result.stderr`.
    #
    # Use this class (via {Git::Lib#command_streaming}) for commands such as
    # `cat-file -p <blob>` whose stdout may be too large to buffer in memory.
    #
    # {Git::CommandLine::Capturing} is the complementary strategy for the common case
    # where buffering stdout is acceptable.
    #
    # @example Stream a blob to a file
    #   streaming = Git::CommandLine::Streaming.new(
    #     {}, '/usr/bin/git', %w[--git-dir /repo/.git], Logger.new($stdout)
    #   )
    #   File.open('/tmp/blob', 'wb') do |f|
    #     streaming.run('cat-file', 'blob', sha, out: f)
    #   end
    #
    # @see Git::Lib#command_streaming
    #
    # @see Git::CommandLine::Capturing
    #
    class Streaming < Git::CommandLine::Base
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
        env: {}
      }.freeze

      # Execute a git command in streaming mode and return the result
      #
      # Unlike {Git::CommandLine::Capturing#run}, this method does **not** buffer
      # stdout in memory.  Stdout is written only to the IO object provided via the
      # `out:` option.  Stderr is captured internally via a `StringIO` for error
      # diagnostics.
      #
      # Use this entry point for commands that stream large content (e.g. blobs)
      # where capturing stdout in memory would be unacceptable.
      #
      # @example Stream a blob to a file
      #   file = File.open('/tmp/blob', 'wb')
      #   streaming.run('cat-file', 'blob', sha, out: file)
      #
      # @param options_hash [Hash] the options to pass to the command
      #
      # @option options_hash [IO, nil] :in the IO object to use as stdin for the
      #   command, or nil to inherit the parent process stdin.  Must be a real IO
      #   object with a file descriptor (not StringIO).
      #
      # @option options_hash [#write, nil] :out the IO/object to stream stdout into.
      #   Stdout is NOT buffered in the returned result; this is the only way to
      #   read it.
      #
      # @option options_hash [#write, nil] :err an optional additional destination to
      #   receive stderr output in real time (e.g. `$stderr` or a `File`).  Stderr is
      #   always captured internally in a `StringIO` for error diagnostics.  When
      #   `err:` is provided, writes are teed to both the internal buffer and this
      #   destination.  `result.stderr` always reflects what was captured in the
      #   internal buffer, regardless of whether `err:` is supplied.
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
      #   `result.stdout` will always be `''` (empty) — stdout was streamed to `out:`.
      #   `result.stderr` contains any stderr output captured for diagnostics.
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

        internal_err = StringIO.new
        # Tee stderr to the caller-provided destination (if any) AND the internal
        # StringIO.  This ensures result.stderr is always available even when err:
        # is a non-StringIO IO object.
        err_dest = options[:err] ? build_stderr_tee(internal_err, options[:err]) : internal_err
        result = execute(*, err_io: err_dest, **options)
        process_result(result, internal_err, options)
      end

      private

      # @return [ProcessExecuter::Result] the result of running the command (non-capturing)
      #
      # @api private
      def execute(*args, err_io:, **options_hash)
        git_cmd = build_git_cmd(args)
        options = execute_options(err_io:, **options_hash)
        run_process_executer do
          ProcessExecuter.run(merged_env(options_hash), *git_cmd, **options)
        end
      end

      # Build the ProcessExecuter options hash for a streaming run
      #
      # @return [Hash]
      #
      # @api private
      def execute_options(err_io:, **options_hash)
        chdir = options_hash[:chdir] || :not_set
        timeout_after = options_hash[:timeout]

        { chdir:, timeout_after:, raise_errors: false, err: err_io }.tap do |options|
          options[:in] = options_hash[:in] unless options_hash[:in].nil?
          options[:out] = options_hash[:out] unless options_hash[:out].nil?
        end
      end

      # Build a tee writer that forwards #write calls to two destinations simultaneously.
      #
      # Used to capture stderr in an internal StringIO while also streaming to a
      # caller-provided destination.
      #
      # @param primary [StringIO] the internal capture buffer
      #
      # @param secondary [#write] the caller-supplied destination
      #
      # @return [#write] an object whose #write method delegates to both destinations
      #
      # @api private
      def build_stderr_tee(primary, secondary)
        ::Object.new.tap do |tee|
          tee.define_singleton_method(:write) do |data|
            primary.write(data)
            secondary.write(data)
            data.bytesize
          end
        end
      end

      # Process the result of a streaming command and return a Git::CommandLineResult
      #
      # Constructs stdout as `''` (not captured) and stderr from the internal StringIO.
      #
      # @param result [ProcessExecuter::Result] the raw process result
      #
      # @param err_io [StringIO] the internal StringIO that captured stderr
      #
      # @param options [Hash] the merged run options
      #
      # @return [Git::CommandLineResult]
      #
      # @api private
      def process_result(result, err_io, options)
        command = result.command
        stderr = err_io.string
        log_result(result, command, '', stderr)
        command_line_result(
          command, result, '', stderr, options[:timeout], options[:raise_on_failure]
        )
      end
    end
  end
end
