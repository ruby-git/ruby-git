# frozen_string_literal: true

require 'git/commands/arguments'

module Git
  module Commands
    # @api private
    #
    # Base class for git command implementations.
    #
    # Provides default {#initialize} and {#call} methods so that simple commands
    # only need to declare their arguments:
    #
    #   class Add < Git::Commands::Base
    #     arguments do
    #       literal 'add'
    #       flag_option :all
    #       flag_option :force
    #       end_of_options
    #       operand :paths, repeatable: true
    #     end
    #
    #     # Execute the git add command
    #     # ...YARD docs...
    #     def call(...) = super
    #   end
    #
    # Commands whose git process may exit with a non-zero status that is
    # *not* an error can declare the acceptable range of exit codes:
    #
    #   class Delete < Git::Commands::Base
    #     arguments do
    #       literal 'branch'
    #       literal '--delete'
    #       operand :branch_names, repeatable: true, required: true
    #     end
    #
    #     allow_exit_status 0..1
    #
    #     # Execute the git branch --delete command
    #     # ...YARD docs...
    #     def call(...) = super
    #   end
    #
    # Commands with execution options (e.g., timeout) work with the default
    # `call` — execution options are extracted and forwarded automatically.
    class Base
      class << self
        # @return [Git::Commands::Arguments, nil] the frozen argument definition for this command
        attr_reader :args_definition

        # Define the command's arguments using the {Arguments} DSL.
        #
        # @yield the block passed to {Arguments.define}
        #
        # @raise [ArgumentError] if called more than once on the same class
        #
        # @return [void]
        def arguments(&)
          raise ArgumentError, "arguments already defined for #{name}" if @args_definition

          @args_definition = Arguments.define(&).freeze
        end

        # @return [Range, nil] range of exit status values accepted by this command
        attr_reader :allowed_exit_status_range

        # Declare the acceptable range of exit status values for this command.
        #
        # @example git-diff exits 1 when a diff is found (not an error)
        #   allow_exit_status 0..1
        #
        # @example git-fsck uses exit codes 0-7 as bit flags
        #   allow_exit_status 0..7
        #
        # @param range [Range] range of accepted exit status values
        #
        # @raise [ArgumentError] if range is invalid
        #
        # @return [void]
        def allow_exit_status(range)
          raise ArgumentError, 'allow_exit_status expects a Range' unless range.is_a?(Range)
          unless range.begin.is_a?(Integer) && range.end.is_a?(Integer)
            raise ArgumentError, 'allow_exit_status bounds must be Integers'
          end

          raise ArgumentError, 'allow_exit_status range must not be empty' if range.begin > range.end

          @allowed_exit_status_range = range
        end
      end

      # @param execution_context [Git::ExecutionContext, Git::Lib] context that provides
      #   {Git::Lib#command_capturing} and {Git::Lib#command_streaming}
      def initialize(execution_context)
        @execution_context = execution_context
      end

      # Execute the git command.
      #
      # @overload call(*args, **kwargs)
      #   Bind arguments and execute the command.
      #
      #   Execution options (declared via `execution_option` in the Arguments
      #   DSL) are extracted from the bound arguments via
      #   {Git::Commands::Arguments::Bound#execution_options} and forwarded as
      #   keyword arguments to the execution context via {#execute_command}.
      #
      #   When the `:out` execution option is present, stdout is streamed using
      #   `@execution_context.command_streaming`. Otherwise, stdout is captured
      #   using `@execution_context.command_capturing`.
      #
      #   @example
      #     # In a command subclass:
      #     # result = command.call('HEAD', timeout: 10)
      #
      #   @param args [Array] positional arguments forwarded to {Arguments#bind}
      #
      #   @param kwargs [Hash] keyword arguments forwarded to {Arguments#bind}
      #
      # @return [Git::CommandLineResult] the result of calling `git`
      #
      # @raise [ArgumentError] if no arguments definition is declared on the command class
      #
      # @raise [Git::FailedError] if git returns an exit code outside the allowed range
      def call(*, **)
        bound = args_definition.bind(*, **)
        result = execute_command(bound)
        validate_exit_status!(result)
        result
      end

      private

      def args_definition
        self.class.args_definition || raise(ArgumentError, "arguments not defined for #{self.class.name}")
      end

      def execute_command(bound)
        exec_opts = execution_opts(bound)

        if exec_opts.key?(:out)
          @execution_context.command_streaming(*bound, **exec_opts, raise_on_failure: false)
        else
          @execution_context.command_capturing(*bound, **capturing_opts(exec_opts), raise_on_failure: false)
        end
      end

      def execution_opts(bound)
        caller_env = bound.execution_options.fetch(:env, {}) || {}
        merged_env = caller_env.merge(env)
        opts = bound.execution_options.except(:env)
        merged_env.empty? ? opts : opts.merge(env: merged_env)
      end

      def capturing_opts(exec_opts)
        opts = exec_opts
        opts = opts.merge(normalize: false) unless normalize_captured_stdout?
        opts = opts.merge(chomp: false) unless chomp_captured_stdout?
        opts
      end

      # Whether {#execute_command} should apply Ruby string normalization to
      # `result.stdout` on the capturing path.
      #
      # When `true` (the default), `command_capturing` normalizes the encoding of
      # captured stdout. Override to return `false` in subclasses whose output is
      # intrinsically binary (e.g. `git archive`), so that stdout bytes in
      # `result.stdout` are returned unchanged.
      #
      # This hook only affects the **capturing** path — when an `out:` execution
      # option is present, stdout is streamed directly to the caller-supplied IO
      # object and is never normalized or chomped regardless of this setting.
      #
      # @return [Boolean]
      def normalize_captured_stdout?
        true
      end

      # Whether {#execute_command} should chomp trailing newlines from
      # `result.stdout` on the capturing path.
      #
      # When `true` (the default), `command_capturing` strips the trailing
      # newline from captured stdout. Override to return `false` in subclasses
      # whose output must preserve trailing whitespace (e.g. `git show`, which
      # can return blob content with significant trailing newlines).
      #
      # This hook only affects the **capturing** path — when an `out:` execution
      # option is present, stdout is streamed directly to the caller-supplied IO
      # object and is never chomped regardless of this setting.
      #
      # @return [Boolean]
      def chomp_captured_stdout?
        true
      end

      # Environment variable overrides to pass to the subprocess.
      #
      # Returns an empty hash by default. Subclasses may override this method
      # to inject process-level environment changes required for correctness
      # (e.g. unsetting `GIT_INDEX_FILE` for worktree management commands).
      #
      # The returned hash is merged with any environment overrides the caller
      # supplies via the `env:` execution option — this hook's values win on
      # conflict so that safety invariants cannot be accidentally overridden.
      #
      # @return [Hash] environment variable overrides (key: variable name, value: new value or nil to unset)
      #
      def env
        {}
      end

      def allowed_exit_status_range
        self.class.allowed_exit_status_range || (0..0)
      end

      def validate_exit_status!(result)
        raise Git::FailedError, result unless allowed_exit_status_range.include?(result.status.exitstatus)
      end

      # Opens an in-memory IO pipe, spawns a background thread to write
      # `content` to the write end (then close it), and immediately yields
      # the read end. The write and close happen concurrently with the block.
      #
      # The read end can be passed as the `in:` keyword to
      # {Git::Lib#command_capturing} / {Git::CommandLine#run_with_capture}, connecting it directly to
      # the spawned git process's stdin without an intermediate file or shell
      # heredoc. This is required because `Process.spawn` only accepts real IO
      # objects with a file descriptor — `StringIO` does not work.
      #
      # The threaded write prevents deadlocks when `content` exceeds the OS
      # pipe buffer: the subprocess can drain the pipe concurrently while the
      # writer thread continues writing.
      #
      # Pass an empty string when the process should receive no input (e.g.
      # when `--batch-all-objects` is used and git enumerates objects itself).
      #
      # @example Feed bound object names to a git batch command
      #   bound = args_definition.bind(*, **)
      #   stdin_content = Array(bound.objects).map { |object| "#{object}\n" }.join
      #   with_stdin(stdin_content) do |reader|
      #     @execution_context.command_capturing('cat-file', '--batch-check', in: reader, raise_on_failure: false)
      #   end
      #
      # @param content [String] text to write to the process's stdin
      #
      # @yield [reader [IO]] the read end of the pipe; valid only for the
      #   duration of the block
      #
      # @return [Object] the value returned by the block
      #
      def with_stdin(content)
        reader, writer = IO.pipe
        writer_thread = start_stdin_writer(content, writer)
        yield reader
      ensure
        reader.close unless reader.closed?
        writer_thread&.join
      end

      # Spawns a thread that writes content to writer then closes it.
      # Rescues EPIPE/IOError so the thread exits cleanly when the subprocess
      # closes its stdin early (e.g. on error exit before reading all input).
      def start_stdin_writer(content, writer)
        Thread.new do
          writer.write(content) unless content.empty?
        rescue Errno::EPIPE, IOError
          nil # subprocess closed stdin early
        ensure
          writer.close unless writer.closed?
        end
      end
    end
  end
end
