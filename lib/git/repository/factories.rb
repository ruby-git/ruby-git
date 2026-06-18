# frozen_string_literal: true

require 'git/commands/clone'
require 'git/commands/init'
require 'git/execution_context/global'
require 'git/execution_context/repository'
require 'git/repository/path_resolver'
require 'pathname'

module Git
  class Repository
    # Factory class methods for constructing {Git::Repository} instances
    #
    # The four public factories — {clone}, {init}, {open}, {bare} — mirror the
    # top-level `Git.*` entry points and return a {Git::Repository}.
    #
    # Extended by {Git::Repository}.
    #
    # @api public
    #
    module Factories # rubocop:disable Metrics/ModuleLength
      # Clone a repository into a new directory
      #
      # @example Clone into the default directory
      #   repository = Git::Repository.clone('https://github.com/ruby-git/ruby-git.git')
      #
      # @example Clone into a specific directory
      #   repo_url = 'https://github.com/ruby-git/ruby-git.git'
      #   repository = Git::Repository.clone(repo_url, 'local')
      #
      # @example Clone a bare repository
      #   repo_url = 'https://github.com/ruby-git/ruby-git.git'
      #   repository = Git::Repository.clone(repo_url, nil, bare: true)
      #
      # @param repository_url [String] the URL or path of the repository to clone
      #
      # @param directory [String, nil] the local directory name to clone into;
      #   git derives the name from the URL when `nil`
      #
      # @param options [Hash] options that control cloning
      #
      #   Some options configure the returned {Git::Repository} instance after
      #   the clone completes. Supported `git clone` options are forwarded.
      #
      # @option options [String, nil] :template template directory to use
      #
      # @option options [Boolean, nil] :local use the local clone optimization
      #
      # @option options [Boolean, nil] :no_local disable the local clone optimization
      #
      # @option options [Boolean, nil] :shared set up a shared clone
      #
      # @option options [Boolean, nil] :no_hardlinks copy files instead of hardlinks
      #
      # @option options [Boolean, nil] :quiet suppress progress output
      #
      # @option options [Boolean, nil] :verbose run verbosely
      #
      # @option options [Boolean, nil] :progress force progress output
      #
      # @option options [Boolean, nil] :no_checkout skip checking out `HEAD`
      #
      # @option options [Boolean, nil] :bare clone as a bare repository
      #
      # @option options [Boolean, nil] :mirror set up a mirror of the source
      #   (implies `:bare`)
      #
      # @option options [String, nil] :origin remote name to use instead of `origin`
      #
      # @option options [String, nil] :branch the branch or tag to check out after cloning
      #
      # @option options [String, nil] :revision revision to check out after cloning
      #
      # @option options [String, nil] :upload_pack remote `git-upload-pack` path
      #
      # @option options [String, Array<String>, nil] :reference reference repository
      #
      # @option options [String, Array<String>, nil] :reference_if_able
      #   optional reference repository
      #
      # @option options [Boolean, nil] :dissociate stop borrowing from references
      #
      # @option options [String, nil] :separate_git_dir alternate git directory path
      #
      # @option options [String, Array<String>, nil] :server_option
      #   protocol-v2 server options
      #
      # @option options [Integer, String, nil] :depth create a shallow clone
      #
      # @option options [String, nil] :shallow_since create a shallow clone by date
      #
      # @option options [String, Array<String>, nil] :shallow_exclude
      #   exclude commits reachable from a ref
      #
      # @option options [Boolean, nil] :single_branch clone one branch's history
      #
      # @option options [Boolean, nil] :no_single_branch clone all branch history
      #
      # @option options [Boolean, nil] :tags include tags in the clone
      #
      # @option options [Boolean, nil] :no_tags exclude tags from the clone
      #
      # @option options [Boolean, String, Array<String>, nil] :recurse_submodules
      #   initialize submodules after cloning
      #
      #   Pass `true` to initialize all submodules, or pass a pathspec string or
      #   array for a subset.
      #
      # @option options [Boolean, nil] :shallow_submodules use depth 1 for submodules
      #
      # @option options [Boolean, nil] :no_shallow_submodules use full submodule history
      #
      # @option options [Boolean, nil] :remote_submodules use submodule remote branches
      #
      # @option options [Boolean, nil] :no_remote_submodules use recorded submodule SHAs
      #
      # @option options [Integer, String, nil] :jobs submodule jobs to run concurrently
      #
      # @option options [Boolean, nil] :sparse enable sparse checkout
      #
      # @option options [Boolean, nil] :reject_shallow reject shallow source repositories
      #
      # @option options [Boolean, nil] :no_reject_shallow allow shallow sources
      #
      # @option options [String, nil] :filter specify a partial clone filter
      #
      # @option options [Boolean, nil] :also_filter_submodules filter submodules too
      #
      # @option options [String, Array<String>, nil] :config repository config entries
      #
      # @option options [String, nil] :bundle_uri bundle URI to prefetch
      #
      # @option options [String, nil] :ref_format ref storage format
      #
      # @option options [Numeric, nil] :timeout command timeout in seconds
      #
      # @option options [String, nil] :repository alternate git directory path
      #
      #   Preferred facade spelling for `git clone --separate-git-dir`.
      #
      # @option options [String, nil, :use_global_config] :git_ssh path to a custom
      #   SSH executable
      #
      #   Pass `:use_global_config` (the default) to use
      #   `Git.config.git_ssh`.
      #
      # @option options [String, :use_global_config] :binary_path path to the git
      #   binary
      #
      #   Pass `:use_global_config` (the default) to use
      #   `Git.config.binary_path`.
      #
      # @option options [Logger, nil] :log logger used for git operations
      #
      # @option options [String, nil] :index a non-standard path to the index file
      #
      # @option options [String, Pathname, nil] :chdir run `git clone` from within
      #   this directory
      #
      # @option options [String, Pathname, nil] :path deprecated; use `:chdir` instead
      #
      # @option options [Boolean, nil] :recursive deprecated; use
      #   `:recurse_submodules` instead
      #
      # @option options [String, nil] :remote deprecated; use `:origin` instead
      #
      # @return [Git::Repository] a repository bound to the cloned working copy or
      #   bare repository
      #
      # @raise [ArgumentError] if unsupported options are provided
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      # @raise [Git::UnexpectedResultError] if the cloned directory cannot be
      #   determined from git's output
      #
      # @api public
      #
      def clone(repository_url, directory = nil, options = {})
        opts, context_opts = prepare_clone_options(options)
        clone_result = run_clone_command(repository_url, directory, opts, context_opts)
        paths = resolve_paths_from_clone_result(clone_result, opts, context_opts)

        from_paths(clone_repository_options(context_opts), paths)
      end

      # Create an empty Git repository or reinitialize an existing one
      #
      # @example Initialize in the current directory
      #   repository = Git::Repository.init
      #
      # @example Initialize in a specific directory
      #   repository = Git::Repository.init('/path/to/project')
      #
      # @example Initialize a bare repository
      #   repository = Git::Repository.init('/path/to/project.git', bare: true)
      #
      # @param directory [String] the directory to initialize; defaults to `'.'`
      #
      # @param options [Hash] options that control initialization
      #
      #   Some options configure the returned {Git::Repository} instance after
      #   the repository is initialized.
      #
      # @option options [Boolean, nil] :bare create a bare repository at `directory`
      #
      # @option options [String, nil] :initial_branch the name for the initial branch
      #
      # @option options [String, nil] :repository path for the `.git` directory
      #
      #   Writes a gitfile in the working tree. Alias: `:separate_git_dir`.
      #
      # @option options [String, nil] :separate_git_dir alias for `:repository`
      #
      # @option options [String, nil, :use_global_config] :git_ssh path to a custom
      #   SSH executable
      #
      #   Pass `:use_global_config` (the default) to use
      #   `Git.config.git_ssh`.
      #
      # @option options [String, :use_global_config] :binary_path path to the git
      #   binary
      #
      #   Pass `:use_global_config` (the default) to use
      #   `Git.config.binary_path`.
      #
      # @option options [Logger, nil] :log logger used for git operations
      #
      # @option options [String, nil] :index custom index path for the returned
      #   repository
      #
      #   Ignored when `:bare` is `true`.
      #
      # @return [Git::Repository] a repository bound to the newly initialized repository
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      # @api public
      #
      def init(directory = '.', options = {})
        options = options.dup
        if options.key?(:separate_git_dir) && options[:repository].nil?
          options[:repository] = options.delete(:separate_git_dir)
        end

        run_init_command(directory, options)
        open_after_init(directory, options)
      end

      # Open a working copy at an existing path
      #
      # Note: this method opens working copies only. To open a bare repository, use
      # `Git::Repository.bare`.
      #
      # @example Open the working copy in the current directory
      #   repository = Git::Repository.open('.')
      #
      # @param working_dir [String] the path to the root of the working copy
      #
      #   May be any path inside the working tree when `:repository` is not given.
      #
      # @param options [Hash] options that control how the repository is located
      #
      # @option options [String, nil] :repository a non-standard path to the
      #   `.git` directory
      #
      #   When given, `working_dir` is used as-is (the working tree root is not
      #   auto-detected).
      #
      # @option options [String, nil] :index a non-standard path to the index file
      #
      # @option options [Logger, nil] :log logger used for git operations
      #
      # @option options [String, nil, :use_global_config] :git_ssh
      #   path to a custom SSH executable
      #
      #   Pass `:use_global_config` (the default) to use
      #   `Git.config.git_ssh`.
      #
      # @option options [String, :use_global_config] :binary_path
      #   path to the git binary
      #
      #   Pass `:use_global_config` (the default) to use
      #   `Git.config.binary_path`.
      #
      # @return [Git::Repository] a repository bound to the resolved paths
      #
      # @raise [ArgumentError] if `working_dir` is not a directory or is not inside
      #   a git working tree
      #
      # @api public
      #
      def open(working_dir, options = {})
        raise ArgumentError, "'#{working_dir}' is not a directory" unless Dir.exist?(working_dir)

        working_dir = resolve_open_working_dir(working_dir, options) unless options[:repository]

        paths = PathResolver.resolve_paths(
          working_directory: working_dir,
          repository: options[:repository],
          index: options[:index]
        )

        from_paths(options, paths)
      end

      # Open an existing bare repository at `git_dir`
      #
      # @example Open a bare repository
      #   repository = Git::Repository.bare('/path/to/repo.git')
      #
      # @param git_dir [String] the path to the bare repository directory
      #
      # @param options [Hash] options used to configure the repository instance
      #
      # @option options [Logger, nil] :log logger used for git operations
      #
      # @option options [String, nil, :use_global_config] :git_ssh
      #   path to a custom SSH executable
      #
      #   Pass `:use_global_config` (the default) to use
      #   `Git.config.git_ssh`.
      #
      # @option options [String, :use_global_config] :binary_path
      #   path to the git binary
      #
      #   Pass `:use_global_config` (the default) to use
      #   `Git.config.binary_path`.
      #
      # @return [Git::Repository] a repository bound to the bare repository directory
      #
      # @api public
      #
      def bare(git_dir, options = {})
        paths = PathResolver.resolve_paths(repository: git_dir, bare: true)

        from_paths(options, paths)
      end

      private

      # Run the `git clone` command using a global execution context
      #
      # @param repository_url [String] the URL or path of the repository to clone
      #
      # @param directory [String, nil] the local directory name to clone into
      #
      # @param opts [Hash] command-ready clone options
      #
      # @param context_opts [Hash] context options produced while preparing clone
      #   options
      #
      # @return [Git::CommandLineResult] the result of running `git clone`
      #
      # @raise [ArgumentError] if unsupported options are provided
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      # @api private
      #
      def run_clone_command(repository_url, directory, opts, context_opts)
        context = Git::ExecutionContext::Global.new(
          binary_path: context_opts[:binary_path],
          git_ssh: context_opts[:git_ssh],
          logger: context_opts[:logger]
        )

        Git::Commands::Clone.new(context).call(repository_url, directory, **opts)
      end

      # Resolve repository paths from a completed clone result
      #
      # @param clone_result [Git::CommandLineResult] the completed clone result
      #
      # @param opts [Hash] command-ready clone options
      #
      # @param context_opts [Hash] context options produced while preparing clone
      #   options
      #
      # @return [Hash{Symbol => (String, nil)}] resolved path hash
      #
      # @raise [Git::UnexpectedResultError] if the clone directory cannot be parsed
      #
      # @api private
      #
      def resolve_paths_from_clone_result(clone_result, opts, context_opts)
        clone_dir, cloned_bare = parse_clone_stderr(clone_result.stderr)
        chdir = opts[:chdir]
        clone_dir = File.join(chdir, clone_dir) if chdir && !Pathname.new(clone_dir).absolute?

        bare = opts[:bare] || opts[:mirror] || cloned_bare
        resolve_clone_paths(clone_dir, bare, context_opts[:index])
      end

      # Build repository construction options from clone context options
      #
      # @param context_opts [Hash] context options produced while preparing clone
      #   options
      #
      # @return [Hash{Symbol => Object}] repository construction options
      #
      # @api private
      #
      def clone_repository_options(context_opts)
        {
          git_ssh: context_opts[:git_ssh],
          binary_path: context_opts[:binary_path],
          log: context_opts[:logger]
        }
      end

      # Build the `:binary_path` and `:git_ssh` execution-context defaults
      #
      # Reads the values from the caller-supplied options, falling back to the
      # `:use_global_config` sentinel for any the caller did not provide so the
      # value is resolved from `Git::Config.instance` at call time.
      #
      # @param options [Hash] the caller-supplied options hash
      #
      # @return [Hash] context defaults with two keys: `:binary_path`
      #   (`String` or `:use_global_config` — `nil` is not valid and raises
      #   `ArgumentError` in {Git::ExecutionContext#initialize}) and `:git_ssh`
      #   (`String`, `nil`, or `:use_global_config`)
      #
      # @api private
      #
      def context_defaults(options)
        {
          binary_path: options.fetch(:binary_path, :use_global_config),
          git_ssh: options.fetch(:git_ssh, :use_global_config)
        }
      end

      # Resolve the worktree root to use as the working directory for {.open}
      #
      # @param working_dir [String] a path inside the working tree
      #
      # @param options [Hash] the caller-supplied options hash from {.open}
      #
      # @return [String] the absolute path to the root of the working tree
      #
      # @raise [ArgumentError] if `working_dir` is not inside a git working tree
      #
      # @api private
      #
      def resolve_open_working_dir(working_dir, options)
        PathResolver.root_of_worktree(working_dir, **context_defaults(options))
      end

      # Build a repository from caller options and resolved paths
      #
      # @param options [Hash] the caller-supplied options (`:git_ssh`,
      #   `:binary_path`, `:log`)
      #
      # @param paths [Hash{Symbol => (String, nil)}] the resolved paths
      #
      # @return [Git::Repository] the constructed repository
      #
      # @api private
      #
      def from_paths(options, paths)
        new(execution_context: Git::ExecutionContext::Repository.from_hash(
          options.merge(paths), logger: options[:log]
        ))
      end

      # Extract facade-level options from the raw clone options and return
      # command-ready options
      #
      # Returns `[command_opts, context_opts]` where `command_opts` is the
      # caller's options with facade-level keys removed. Remaining keys are
      # forwarded to `Git::Commands::Clone`, which raises `ArgumentError` for
      # unsupported ones. `context_opts` contains values used for the execution
      # context and post-clone path resolution.
      #
      # @param options [Hash] raw caller-supplied options
      #
      # @return [Array<Hash>] a two-element tuple `[command_opts, context_opts]`
      #
      # @api private
      #
      def prepare_clone_options(options)
        opts = options.dup
        deprecate_clone_path_option!(opts)
        deprecate_clone_recursive_option!(opts)
        deprecate_clone_remote_option!(opts)
        context_opts = extract_clone_context_options!(opts)
        normalize_clone_repository_option!(opts)

        [opts, context_opts]
      end

      # Extract clone context options from command-ready options
      #
      # @param opts [Hash] clone options (mutated in place)
      #
      # @return [Hash{Symbol => Object}] context options for clone setup
      #
      # @api private
      #
      def extract_clone_context_options!(opts)
        {
          logger: opts.delete(:log),
          git_ssh: opts.key?(:git_ssh) ? opts.delete(:git_ssh) : :use_global_config,
          binary_path: opts.key?(:binary_path) ? opts.delete(:binary_path) : :use_global_config,
          index: opts.delete(:index)
        }
      end

      # Normalize the clone repository option for `git clone`
      #
      # @param opts [Hash] clone options (mutated in place)
      #
      # @return [void] mutates `opts` in place
      #
      # @api private
      #
      def normalize_clone_repository_option!(opts)
        return unless opts.key?(:repository)

        repository_val = opts.delete(:repository)
        opts[:separate_git_dir] = repository_val if repository_val
      end

      # Resolve paths for the cloned repository
      #
      # @param clone_dir [String] the directory reported by `git clone`
      #
      # @param bare [Boolean] whether the clone is bare
      #
      # @param index [String, nil] optional custom index path
      #
      # @return [Hash{Symbol => (String, nil)}] resolved path hash
      #
      # @api private
      #
      def resolve_clone_paths(clone_dir, bare, index)
        args = bare ? { repository: clone_dir, bare: true } : { working_directory: clone_dir }
        PathResolver.resolve_paths(**args, index: index)
      end

      # Run the `git init` command using a global execution context
      #
      # @param directory [String] the directory to initialize
      #
      # @param options [Hash] the normalized options hash (after alias resolution)
      #
      # @return [Git::CommandLineResult] the result of running `git init`
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      # @api private
      #
      def run_init_command(directory, options)
        init_opts = options.slice(:bare, :initial_branch)
        init_opts[:separate_git_dir] = options[:repository] if options.key?(:repository)

        context = Git::ExecutionContext::Global.new(**context_defaults(options), logger: options[:log])
        Git::Commands::Init.new(context).call(directory, **init_opts)
      end

      # Open the repository produced by `git init`
      #
      # @param directory [String] the initialized directory
      #
      # @param options [Hash] the normalized options hash
      #
      # @return [Git::Repository] the repository opened after initialization
      #
      # @api private
      #
      def open_after_init(directory, options)
        return bare(options[:repository] || directory, base_open_options_after_init(options)) if options[:bare]

        self.open(directory, worktree_open_options_after_init(options))
      end

      # Build common options for opening a repository after `git init`
      #
      # @param options [Hash] the normalized options hash
      #
      # @return [Hash{Symbol => Object}] options accepted by {.open} and {.bare}
      #
      # @api private
      #
      def base_open_options_after_init(options)
        {
          git_ssh: options.fetch(:git_ssh, :use_global_config),
          binary_path: options.fetch(:binary_path, :use_global_config)
        }.tap do |open_opts|
          open_opts[:log] = options[:log] if options[:log]
        end
      end

      # Build worktree options for opening a repository after `git init`
      #
      # @param options [Hash] the normalized options hash
      #
      # @return [Hash{Symbol => Object}] options accepted by {.open}
      #
      # @api private
      #
      def worktree_open_options_after_init(options)
        base_open_options_after_init(options).tap do |open_opts|
          open_opts[:index] = options[:index] if options[:index]
          open_opts[:repository] = options[:repository] if options[:repository]
        end
      end

      # Parse the clone directory and bare status from `git clone` stderr output
      #
      # @param stderr [String] stderr output from `git clone`
      #
      # @return [Array] a two-element tuple `[clone_dir, bare]`
      #
      # @raise [Git::UnexpectedResultError] if the stderr output cannot be parsed
      #
      # @api private
      #
      def parse_clone_stderr(stderr)
        match = stderr.match(/Cloning into (?:(bare repository) )?'(.+)'\.\.\./)
        raise Git::UnexpectedResultError, "Unable to determine clone directory from: #{stderr}" unless match

        [match[2], !match[1].nil?]
      end

      # Handle the deprecated `:path` option for {clone}
      #
      # @param opts [Hash] clone options (mutated in place)
      #
      # @return [void] mutates `opts` in place
      #
      # @api private
      #
      def deprecate_clone_path_option!(opts)
        return unless opts.key?(:path)

        if defined?(Git::Deprecation)
          Git::Deprecation.warn('The :path option for Git::Repository.clone is deprecated, use :chdir instead')
        end
        path = opts.delete(:path)
        opts[:chdir] ||= path
      end

      # Handle the deprecated `:recursive` option for {clone}
      #
      # @param opts [Hash] clone options (mutated in place)
      #
      # @return [void] mutates `opts` in place
      #
      # @api private
      #
      def deprecate_clone_recursive_option!(opts)
        return unless opts.key?(:recursive)

        if defined?(Git::Deprecation)
          Git::Deprecation.warn(
            'The :recursive option for Git::Repository.clone is deprecated, use :recurse_submodules instead'
          )
        end
        opts[:recurse_submodules] = opts.delete(:recursive)
      end

      # Handle the deprecated `:remote` option for {clone}
      #
      # @param opts [Hash] clone options (mutated in place)
      #
      # @return [void] mutates `opts` in place
      #
      # @api private
      #
      def deprecate_clone_remote_option!(opts)
        return unless opts.key?(:remote)

        if defined?(Git::Deprecation)
          Git::Deprecation.warn('The :remote option for Git::Repository.clone is deprecated, use :origin instead')
        end
        opts[:origin] = opts.delete(:remote)
      end
    end
  end
end
