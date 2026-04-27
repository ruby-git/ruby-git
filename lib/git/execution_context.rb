# frozen_string_literal: true

require 'logger'

module Git
  # Base class for execution contexts that run git commands
  #
  # An execution context bundles three concerns that together describe *how* and
  # *where* a git command runs:
  #
  # 1. **Repository scope** — the public accessors `git_dir`, `git_work_dir`,
  #    `git_index_file`, and `git_ssh` identify which repository git targets and
  #    which SSH wrapper to use. Their values are translated into `GIT_*` environment
  #    variable overrides by the private `env_overrides` method. A `nil` value
  #    unsets the variable (see `Process.spawn` semantics).
  #
  # 2. **CLI global options** — the private `global_opts` method returns the array
  #    of git flags prepended to every invocation: `--git-dir` / `--work-tree` when
  #    those attributes are set, plus the static options in {STATIC_GLOBAL_OPTS} that
  #    ensure deterministic, script-friendly output.
  #
  # 3. **Execution defaults** — {COMMAND_CAPTURING_ARG_DEFAULTS} and
  #    {COMMAND_STREAMING_ARG_DEFAULTS} define the default values for I/O, encoding,
  #    and behavioral options (`in:`, `out:`, `normalize:`, `timeout:`, etc.) accepted
  #    by {#command_capturing} and {#command_streaming}.
  #
  # Subclasses override the repository-scope accessors to supply context-specific
  # values. The `env_overrides` and `global_opts` methods are implemented here and
  # call those accessors, so subclasses do not need to override them directly.
  #
  # Concrete subclasses:
  # - {Git::ExecutionContext::Repository} — for repository-bound commands (`add`, `commit`, …)
  # - {Git::ExecutionContext::Global} — for commands that do not require an existing repository
  #   (`init`, `clone`, `version`)
  #
  # @example Using a concrete subclass
  #   context = Git::ExecutionContext::Global.new(binary_path: '/usr/local/bin/git2')
  #   context.binary_path  #=> "/usr/local/bin/git2"
  #
  # @api private
  #
  class ExecutionContext
    # Default keyword arguments accepted by {#command_capturing}.
    #
    # Derived from {Git::CommandLine::Capturing::RUN_OPTION_DEFAULTS} with two
    # overrides: `normalize: true` and `chomp: true` so callers receive clean
    # UTF-8 strings by default. New options added to the CommandLine layer are
    # automatically accepted here without requiring a coordinated edit.
    #
    # `timeout: nil` is intentional — the global timeout from {Git.config} is
    # applied at call-time so that changes to the config are respected.
    #
    COMMAND_CAPTURING_ARG_DEFAULTS =
      Git::CommandLine::Capturing::RUN_OPTION_DEFAULTS
      .merge(normalize: true, chomp: true)
      .freeze

    # Default keyword arguments accepted by {#command_streaming}.
    #
    # Identical to {Git::CommandLine::Streaming::RUN_OPTION_DEFAULTS}. Defined
    # here so callers interact with a stable constant on this class, and so that
    # new options added to the CommandLine layer are automatically accepted.
    #
    COMMAND_STREAMING_ARG_DEFAULTS =
      Git::CommandLine::Streaming::RUN_OPTION_DEFAULTS.dup.freeze

    # Static git global options applied to every invocation.
    #
    # These ensure deterministic, script-friendly output regardless of the
    # user's local git configuration.
    #
    STATIC_GLOBAL_OPTS = %w[
      -c core.quotePath=true
      -c core.editor=false
      -c color.ui=false
      -c color.advice=false
      -c color.diff=false
      -c color.grep=false
      -c color.push=false
      -c color.remote=false
      -c color.showBranch=false
      -c color.status=false
      -c color.transport=false
    ].freeze

    # Creates a new execution context
    #
    # @param binary_path [String, :use_global_config] path to the git binary
    #
    #   Give `:use_global_config` (the default) to use `Git::Base.config.binary_path`.
    #
    #   Passing `nil` raises `ArgumentError` — there is no "unset the
    #   binary" semantic.
    #
    # @param git_ssh [String, nil, :use_global_config] the SSH wrapper path
    #
    #   Give `nil` to unset `GIT_SSH`, or `:use_global_config` (default) to use `Git::Base.config.git_ssh`.
    #
    # @param logger [Logger, nil] the logger to use in the CommandLine layer
    #
    #   Give `nil` to use a null logger (`Logger.new(nil)`).
    #
    # @raise [NotImplementedError] if called directly on {Git::ExecutionContext} rather than a subclass
    #
    # @raise [ArgumentError] if `binary_path` is `nil`
    #
    def initialize(binary_path: :use_global_config, git_ssh: :use_global_config, logger: nil)
      if instance_of?(Git::ExecutionContext)
        raise NotImplementedError, 'Git::ExecutionContext is an abstract base class'
      end
      raise ArgumentError, 'binary_path must not be nil' if binary_path.nil?

      @binary_path = binary_path
      @git_ssh = git_ssh
      @logger = logger || Logger.new(nil)
    end

    # Returns the `GIT_DIR` path for this context
    #
    # `nil` means `GIT_DIR` will be explicitly **unset** in the child process
    # (per `Process.spawn` semantics — unset is not the same as inherited).
    # Subclasses override this to supply a repository-specific path.
    #
    # @example Base class returns nil; subclasses return the actual path
    #   context = Git::ExecutionContext::Global.new
    #   context.git_dir  #=> nil
    #
    # @return [String, nil] the `GIT_DIR` path, or `nil` to unset the variable
    #
    def git_dir = nil

    # Returns the `GIT_WORK_TREE` path for this context
    #
    # `nil` means `GIT_WORK_TREE` will be explicitly **unset** in the child process.
    #
    # @example Base class returns nil; subclasses return the actual path
    #   context = Git::ExecutionContext::Global.new
    #   context.git_work_dir  #=> nil
    #
    # @return [String, nil] the `GIT_WORK_TREE` path, or `nil` to unset the variable
    #
    def git_work_dir = nil

    # Returns the `GIT_INDEX_FILE` path for this context
    #
    # `nil` means `GIT_INDEX_FILE` will be explicitly **unset** in the child process.
    #
    # @example Base class returns nil; subclasses return the actual path
    #   context = Git::ExecutionContext::Global.new
    #   context.git_index_file  #=> nil
    #
    # @return [String, nil] the `GIT_INDEX_FILE` path, or `nil` to unset the variable
    #
    def git_index_file = nil

    # Returns the resolved git binary path for this context
    #
    # `:use_global_config` is resolved to `Git::Base.config.binary_path` each time a
    # command method is called, so runtime changes to `Git::Base.config.binary_path`
    # are reflected per command invocation.
    #
    # @example With the default sentinel (resolves from Git::Base.config at call-time)
    #   context = Git::ExecutionContext::Global.new
    #   context.binary_path  #=> "git"
    #
    # @example With an explicit path
    #   context = Git::ExecutionContext::Global.new(binary_path: '/usr/local/bin/git2')
    #   context.binary_path  #=> "/usr/local/bin/git2"
    #
    # @return [String] the resolved git binary path
    #
    def binary_path
      return Git::Base.config.binary_path if @binary_path == :use_global_config

      @binary_path
    end

    # Returns the resolved `GIT_SSH` wrapper path for this context
    #
    # `:use_global_config` is resolved to `Git::Base.config.git_ssh` each time a
    # command method is called, so runtime changes to `Git::Base.config.git_ssh`
    # are reflected per command invocation. `nil` means the variable will be
    # explicitly unset.
    #
    # @example With the default sentinel (resolves from Git::Base.config at call-time)
    #   context = Git::ExecutionContext::Global.new
    #   context.git_ssh  #=> nil
    #
    # @example With an explicit path
    #   context = Git::ExecutionContext::Global.new(git_ssh: '/usr/bin/ssh-wrapper')
    #   context.git_ssh  #=> "/usr/bin/ssh-wrapper"
    #
    # @return [String, nil] the resolved `GIT_SSH` wrapper path, or `nil` to unset
    #
    def git_ssh
      return Git::Base.config.git_ssh if @git_ssh == :use_global_config

      @git_ssh
    end

    # Runs a git command and returns the result
    #
    # By default, raises {Git::FailedError} if the command exits with a non-zero
    # status. Pass `raise_on_failure: false` to suppress this behavior.
    #
    # @overload command_capturing(*args, **options_hash)
    #
    #   Runs a git command and returns the result
    #
    #   Args should exclude the 'git' command itself and global options. Remember to
    #   splat the arguments if given as an array.
    #
    #   @example Run git log
    #     result = command_capturing('log', '--pretty=oneline')
    #     result.stdout #=> "abc123 First commit\ndef456 Second commit\n"
    #
    #   @example Using an array of arguments
    #     args = ['log', '--pretty=oneline']
    #     result = command_capturing(*args)
    #
    #   @example Suppress raising on failure
    #     result = command_capturing('show', 'nonexistent', raise_on_failure: false)
    #     result.status.success? #=> false
    #
    #   @param args [Array<String>] the command and its arguments
    #
    #   @param options_hash [Hash] the options to pass to the command
    #
    #   @option options_hash [IO, nil] :in the IO object to use as stdin, or nil to
    #     inherit the parent process stdin
    #
    #     Must be a real IO object with a file descriptor.
    #
    #   @option options_hash [IO, String, #write, nil] :out the destination for
    #     captured stdout
    #
    #   @option options_hash [IO, String, #write, nil] :err the destination for
    #     captured stderr
    #
    #   @option options_hash [Boolean] :normalize true to normalize the output
    #     encoding to UTF-8
    #
    #   @option options_hash [Boolean] :chomp true to remove trailing newlines from
    #     the output
    #
    #   @option options_hash [Boolean] :merge true to merge stdout and stderr into a
    #     single output
    #
    #   @option options_hash [String, nil] :chdir the directory to run the command in
    #
    #   @option options_hash [Hash] :env additional environment variable overrides
    #     for this command
    #
    #   @option options_hash [Boolean] :raise_on_failure (true) whether to raise on
    #     non-zero exit
    #
    #   @option options_hash [Numeric, nil] :timeout the maximum seconds to wait for
    #     the command to complete
    #
    #     If timeout is nil, the global timeout from {Git::Config} is used.
    #
    #     If timeout is zero, the timeout will not be enforced.
    #
    #     If the command times out, it is killed via a `SIGKILL` signal and
    #     `Git::TimeoutError` is raised.
    #
    #     If the command does not respond to SIGKILL, it will hang this method.
    #
    #   @return [Git::CommandLineResult] the result of the command
    #
    #   @raise [ArgumentError] if an unknown option is passed
    #
    #   @raise [Git::FailedError] if the command failed (when raise_on_failure is
    #     true)
    #
    #   @raise [Git::SignaledError] if the command was signaled
    #
    #   @raise [Git::TimeoutError] if the command times out
    #
    #   @raise [Git::ProcessIOError] if an exception was raised while collecting
    #     subprocess output
    #
    #     The exception's `result` attribute is a {Git::CommandLineResult} which will
    #     contain the result of the command including the exit status, stdout, and stderr.
    #
    # @note Individual command classes (under {Git::Commands}) can selectively expose
    #   `:timeout` and `:env` and other options to their callers by declaring them as
    #   execution options in their Arguments DSL definition and forwarding them to
    #   this method. See {Git::Commands::Clone#call} for an example of a command that
    #   exposes `:timeout`.
    #
    # @see Git::CommandLine::Capturing#run
    #
    def command_capturing(*, **options_hash)
      options_hash = COMMAND_CAPTURING_ARG_DEFAULTS.merge(options_hash)
      options_hash[:timeout] ||= Git.config.timeout

      extra_options = options_hash.keys - COMMAND_CAPTURING_ARG_DEFAULTS.keys
      raise ArgumentError, "Unknown options: #{extra_options.join(', ')}" if extra_options.any?

      env = options_hash.delete(:env)
      raise_on_failure = options_hash.delete(:raise_on_failure)
      command_line_capturing.run(*, raise_on_failure: raise_on_failure, env: env, **options_hash)
    end

    # Runs a git command using the streaming (non-capturing) execution path
    #
    # Unlike {#command_capturing}, stdout is NOT buffered in memory. It is
    # written only to the IO object provided via the `out:` option. Stderr is
    # captured internally via a StringIO for error diagnostics.
    #
    # Use this entry point when you want to stream large output (e.g. blob
    # content from cat-file) without creating memory pressure.
    #
    # @overload command_streaming(*args, **options_hash)
    #
    #   Streams a git command's output to the provided IO object
    #
    #   @example Stream blob content to a file
    #     File.open('blob.bin', 'wb') do |f|
    #       command_streaming('cat-file', 'blob', 'HEAD:large_file.bin', out: f)
    #     end
    #
    #   @param args [Array<String>] the git command and its arguments
    #
    #   @param options_hash [Hash] the options to pass to the command
    #
    #   @option options_hash [IO, nil] :in the IO object to use as stdin, or nil to
    #     inherit the parent process stdin
    #
    #     Must be a real IO object with a file descriptor.
    #
    #   @option options_hash [#write, nil] :out destination for streamed stdout
    #
    #   @option options_hash [#write, nil] :err an optional additional destination
    #     to receive stderr output in real time
    #
    #     Stderr is always captured internally; when `err:` is supplied, writes are
    #     teed to both the internal buffer and this destination. `result.stderr`
    #     always reflects the internal capture.
    #
    #   @option options_hash [String, nil] :chdir the directory to run the command in
    #
    #   @option options_hash [Hash] :env additional environment variable overrides
    #     for this command
    #
    #   @option options_hash [Boolean] :raise_on_failure (true) whether to raise on
    #     non-zero exit
    #
    #   @option options_hash [Numeric, nil] :timeout
    #     the maximum seconds to wait for the command to complete
    #
    #     If timeout is nil, the global timeout from {Git::Config} is used.
    #
    #     If timeout is zero, the timeout will not be enforced.
    #
    #     If the command times out, it is killed via a `SIGKILL` signal and
    #     `Git::TimeoutError` is raised.
    #
    #     If the command does not respond to SIGKILL, it will hang this method.
    #
    #   @return [Git::CommandLineResult] the result of the command
    #
    #     `result.stdout` will always be `''` — stdout was streamed to `out:`.
    #
    #     `result.stderr` contains any stderr output captured for diagnostics.
    #
    #   @raise [ArgumentError] if an unknown option is passed
    #
    #   @raise [Git::FailedError] if the command failed (when raise_on_failure is true)
    #
    #   @raise [Git::SignaledError] if the command was signaled
    #
    #   @raise [Git::TimeoutError] if the command times out
    #
    #   @raise [Git::ProcessIOError] if an exception was raised while collecting
    #     subprocess output
    #
    # @see Git::CommandLine::Streaming#run
    #
    def command_streaming(*, **options_hash)
      options_hash = COMMAND_STREAMING_ARG_DEFAULTS.merge(options_hash)
      options_hash[:timeout] ||= Git.config.timeout

      extra_options = options_hash.keys - COMMAND_STREAMING_ARG_DEFAULTS.keys
      raise ArgumentError, "Unknown options: #{extra_options.join(', ')}" if extra_options.any?

      env = options_hash.delete(:env)
      raise_on_failure = options_hash.delete(:raise_on_failure)
      command_line_streaming.run(*, raise_on_failure: raise_on_failure, env: env, **options_hash)
    end

    # Returns the installed git version
    #
    # The result is memoized per instance.
    #
    # @example Get the installed git version
    #   context = Git::ExecutionContext::Global.new
    #   context.git_version  #=> #<Git::Version 2.42.0>
    #
    # @return [Git::Version] the installed git version
    #
    # @raise [Git::UnexpectedResultError] if the version string cannot be parsed
    #
    def git_version
      @git_version ||= begin
        output = Git::Commands::Version.new(self).call.stdout
        Git::Version.parse(output)
      end
    end

    private

    # Returns a Hash of environment variable overrides for this context
    #
    # Builds the standard git environment from the public accessor methods
    # ({#git_dir}, {#git_work_dir}, {#git_index_file}, {#git_ssh}), then
    # merges any per-call `additional_overrides` on top.
    #
    # Per `Process.spawn` semantics, a value of `nil` unsets the variable.
    #
    # @param additional_overrides [Hash<String, String|nil>] per-call overrides
    #
    # @return [Hash<String, String|nil>] the merged environment variable overrides
    #
    def env_overrides(**additional_overrides)
      {
        'GIT_DIR' => git_dir,
        'GIT_WORK_TREE' => git_work_dir,
        'GIT_INDEX_FILE' => git_index_file,
        'GIT_SSH' => git_ssh,
        'GIT_EDITOR' => 'true',
        'LC_ALL' => 'en_US.UTF-8'
      }.merge(additional_overrides)
    end

    # Returns the Array of git global option strings for this context
    #
    # Prepends `--git-dir` and `--work-tree` when the corresponding attributes
    # are set, then appends {STATIC_GLOBAL_OPTS}.
    #
    # @return [Array<String>] the global options to prepend to every git invocation
    #
    def global_opts
      [].tap do |opts|
        opts << "--git-dir=#{git_dir}" unless git_dir.nil?
        opts << "--work-tree=#{git_work_dir}" unless git_work_dir.nil?
        opts.concat(STATIC_GLOBAL_OPTS)
      end
    end

    # Creates a {Git::CommandLine::Capturing} instance for the current invocation.
    #
    # A new instance is created per call so that {#binary_path} — resolved from
    # `Git::Base.config` when set to `:use_global_config` — and {#env_overrides}
    # — including {#git_ssh} resolution for `:use_global_config` — reflect the
    # state of `Git::Base.config` at the time of each command invocation.
    #
    # @return [Git::CommandLine::Capturing] the capturing command line instance
    #
    def command_line_capturing
      Git::CommandLine::Capturing.new(env_overrides, binary_path, global_opts, @logger)
    end

    # Creates a {Git::CommandLine::Streaming} instance for the current invocation.
    #
    # A new instance is created per call so that {#binary_path} — resolved from
    # `Git::Base.config` when set to `:use_global_config` — and {#env_overrides}
    # — including {#git_ssh} resolution for `:use_global_config` — reflect the
    # state of `Git::Base.config` at the time of each command invocation.
    #
    # @return [Git::CommandLine::Streaming] the streaming command line instance
    #
    def command_line_streaming
      Git::CommandLine::Streaming.new(env_overrides, binary_path, global_opts, @logger)
    end
  end
end

require 'git/execution_context/global'
require 'git/execution_context/repository'
