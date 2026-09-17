# frozen_string_literal: true

require 'git/commands/clone'
require 'git/commands/init'
require 'git/execution_context/global'
require 'git/execution_context/repository'
require 'git/path_resolver'
require 'git/repository'
require 'git/system_call_guard'
require 'pathname'

module Git
  # Implementation of the {Git} module factory entry points
  #
  # Provides `.open`, `.init`, `.clone`, and `.bare` — the four methods that
  # construct a {Git::Repository}. Extended onto the {Git} module so that
  # `Git.open(...)`, `Git.init(...)`, etc. resolve here.
  #
  # @api private
  #
  module Factories # rubocop:disable Metrics/ModuleLength
    # Clone a repository into a new directory
    #
    # @example Clone into the default directory
    #   repository = Git.clone('https://github.com/ruby-git/ruby-git.git')
    #
    # @example Clone into a specific directory
    #   repo_url = 'https://github.com/ruby-git/ruby-git.git'
    #   repository = Git.clone(repo_url, 'local')
    #
    # @example Clone a bare repository
    #   repo_url = 'https://github.com/ruby-git/ruby-git.git'
    #   repository = Git.clone(repo_url, nil, bare: true)
    #
    # @param repository_url [String, URI, Pathname] the URL or path of the repository to clone
    #
    # @param directory [String, Pathname, nil] the local directory name to clone into;
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
    #   A relative path is expanded against `:chdir` when given, like
    #   `directory`, and against the process working directory otherwise.
    #
    # @option options [String, Pathname, nil] :chdir run `git clone` from within
    #   this directory
    #
    # @return [Git::Repository] a repository bound to the cloned working copy or
    #   bare repository
    #
    # @raise [ArgumentError] if unsupported options are provided
    #
    # @raise [Git::FailedError] if git exits with a non-zero exit status
    #
    # @raise [Git::Error] if a filesystem call made while resolving the paths
    #   fails
    #
    # @raise [Git::UnexpectedResultError] if the cloned directory cannot be
    #   determined from git's output
    #
    # @note If git fails before the transfer completes, git removes `directory`
    #   and the separate git directory it created, or empties `directory` when
    #   it existed before the call. A `:repository` path that already exists is
    #   refused before the transfer starts. If the transfer completes but the
    #   checkout fails, or the `:timeout` or the global timeout kills git, what
    #   git wrote is left in place. If {Git::UnexpectedResultError} is raised,
    #   the completed clone is left in place.
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
    #   repository = Git.init
    #
    # @example Initialize in a specific directory
    #   repository = Git.init('/path/to/project')
    #
    # @example Initialize a bare repository
    #   repository = Git.init('/path/to/project.git', bare: true)
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
    #   Writes a gitfile in the working tree. Alias: `:separate_git_dir`. A
    #   relative path is expanded against the process working directory, as
    #   `git init --separate-git-dir` does.
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
    #   A relative path is expanded against the process working directory.
    #
    # @return [Git::Repository] a repository bound to the newly initialized repository
    #
    # @raise [Git::FailedError] if git exits with a non-zero exit status
    #
    # @raise [Git::Error] if a filesystem call made while resolving the paths
    #   fails
    #
    # @note If git exits non-zero after it starts writing, whatever it wrote is
    #   left in place: `directory` when git created it, and a git directory
    #   (`.git`, or the `:repository` path and the gitfile pointing at it) that
    #   git may not recognize as a repository. If git succeeds but the
    #   repository cannot be opened, the initialized repository is left in place.
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
    # @example Open the working copy in the current directory
    #   repository = Git.open('.')
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
    #   auto-detected). A relative path is expanded against the process working
    #   directory, not against `working_dir`.
    #
    # @option options [String, nil] :index a non-standard path to the index file
    #
    #   A relative path is expanded against the process working directory.
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
    # @raise [Git::Error] if the `.git` path is a gitdir pointer file that cannot
    #   be read, if the git binary cannot be found or fails to launch, or if a
    #   filesystem call made while resolving the paths fails
    #
    # @note This method opens working copies only. To open a bare repository, use
    #   `Git.bare`.
    #
    # @api public
    #
    def open(working_dir, options = {})
      raise ArgumentError, "'#{working_dir}' is not a directory" unless Dir.exist?(working_dir)

      working_dir = resolve_open_working_dir(working_dir, options) unless options[:repository]

      paths = resolve_repository_paths(
        working_dir, bare: false, repository: options[:repository], index: options[:index]
      )

      from_paths(options, paths)
    end

    # Open an existing bare repository at `git_dir`
    #
    # @example Open a bare repository
    #   repository = Git.bare('/path/to/repo.git')
    #
    # @example Bind a bare repository to a scratch index
    #   repository = Git.bare('/srv/repo.git', index: '/tmp/scratch.index')
    #   repository.read_tree('HEAD')
    #   tree_sha = repository.write_tree
    #
    # @param git_dir [String] the path to the bare repository directory
    #
    # @param options [Hash] options used to configure the repository instance
    #
    # @option options [String, nil] :index a non-standard path to the index file
    #
    #   A relative path is expanded against the process working directory.
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
    # @raise [Git::Error] if `git_dir` is a gitdir pointer file that cannot be read
    #
    # @api public
    #
    def bare(git_dir, options = {})
      paths = resolve_repository_paths(git_dir, bare: true, index: options[:index])

      from_paths(options, paths)
    end

    private

    # Run the `git clone` command using a global execution context
    #
    # @param repository_url [String, URI, Pathname] the URL or path of the repository to clone
    #
    # @param directory [String, Pathname, nil] the local directory name to clone into
    #
    # @param opts [Hash] command-ready clone options
    #
    # @param context_opts [Hash] context options produced while preparing clone
    #   options
    #
    # @option opts [Boolean, nil] :bare clone as a bare repository
    #
    # @option context_opts [String, :use_global_config] :binary_path path to
    #   the git binary
    #
    # @option context_opts [String, nil, :use_global_config] :git_ssh path to
    #   a custom SSH executable
    #
    # @option context_opts [Logger, nil] :logger logger used for clone
    #   operations
    #
    # @return [Git::CommandLine::Result] the result of running `git clone`
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
    # @param clone_result [Git::CommandLine::Result] the completed clone result
    #
    # @param opts [Hash] command-ready clone options
    #
    # @param context_opts [Hash] context options produced while preparing clone
    #   options
    #
    # @option opts [String, Pathname, nil] :chdir run `git clone` from within
    #   this directory
    #
    # @option opts [Boolean, nil] :bare clone as a bare repository
    #
    # @option opts [Boolean, nil] :mirror set up a mirror of the source
    #
    # @option context_opts [String, nil] :index custom index path for the
    #   returned repository
    #
    # @return [Hash{Symbol => (String, nil)}] resolved path hash
    #
    # @raise [Git::UnexpectedResultError] if the clone directory cannot be parsed
    #
    # @raise [Git::Error] if the index path cannot be expanded against `:chdir`
    #
    # @api private
    #
    def resolve_paths_from_clone_result(clone_result, opts, context_opts)
      clone_dir, cloned_bare = parse_clone_stderr(clone_result.stderr)
      chdir = opts[:chdir]
      clone_dir = prefix_with_chdir(clone_dir, chdir)
      index = expand_against_chdir(context_opts[:index], chdir)

      bare = opts[:bare] || opts[:mirror] || cloned_bare
      resolve_repository_paths(clone_dir, bare: bare, index: index)
    end

    # Join the relative clone directory git reported onto the `:chdir` it ran in
    #
    # The directory is joined, not expanded, because git created it as given:
    # git does not expand `~` in a path on its command line.
    #
    # @param path [String] the clone directory reported by `git clone`
    #
    # @param chdir [String, Pathname, nil] the directory git ran in, or `nil`
    #
    # @return [String] `path` prefixed with `chdir` when `chdir` is given and
    #   `path` is relative; otherwise `path` unchanged
    #
    def prefix_with_chdir(path, chdir)
      return path if chdir.nil? || Pathname.new(path).absolute?

      File.join(chdir, path)
    end

    # Expand the `:index` option of {.clone} against the `:chdir` git ran in
    #
    # Unlike the clone directory, the index is never given to git, so it follows
    # Ruby's `File.expand_path` rules: an absolute path is unchanged, `~` is the
    # home directory, and a relative path is joined onto `chdir`.
    #
    # @param path [String, nil] the index path, or `nil` when not given
    #
    # @param chdir [String, Pathname, nil] the directory git ran in, or `nil` to
    #   leave the expansion to {Git::PathResolver}
    #
    # @return [String, nil] the expanded path, or `path` unchanged when either
    #   argument is `nil`
    #
    # @raise [Git::Error] if the path cannot be expanded, which happens when
    #   `chdir` is relative and the process working directory has been removed
    #
    def expand_against_chdir(path, chdir)
      return path if path.nil? || chdir.nil?

      Git::SystemCallGuard.call('Failed to resolve the index file') { File.expand_path(path, chdir) }
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
    # @option options [String, :use_global_config] :binary_path path to the
    #   git binary
    #
    # @option options [String, nil, :use_global_config] :git_ssh path to a
    #   custom SSH executable
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
    # @option options [String, :use_global_config] :binary_path path to the
    #   git binary
    #
    # @option options [String, nil, :use_global_config] :git_ssh path to a
    #   custom SSH executable
    #
    # @return [String] the absolute path to the root of the working tree
    #
    # @raise [ArgumentError] if `working_dir` is not inside a git working tree
    #
    # @raise [Git::Error] if the git binary cannot be found or fails to launch, or
    #   if `working_dir` cannot be expanded to an absolute path
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
    # @option options [String, nil, :use_global_config] :git_ssh path to a
    #   custom SSH executable
    #
    # @option options [String, :use_global_config] :binary_path path to the
    #   git binary
    #
    # @option options [Logger, nil] :log logger used for git operations
    #
    # @return [Git::Repository] the constructed repository
    #
    # @api private
    #
    def from_paths(options, paths)
      Git::Repository.new(execution_context: Git::ExecutionContext::Repository.from_hash(
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
    # @option options [Boolean, nil] :bare clone as a bare repository
    #
    # @return [Array<Hash>] a two-element tuple `[command_opts, context_opts]`
    #
    # @api private
    #
    def prepare_clone_options(options)
      opts = options.dup
      context_opts = extract_clone_context_options!(opts)
      normalize_clone_repository_option!(opts)

      [opts, context_opts]
    end

    # Extract clone context options from command-ready options
    #
    # @param opts [Hash] clone options (mutated in place)
    #
    # @option opts [Logger, nil] :log logger used for clone operations
    #
    # @option opts [String, nil, :use_global_config] :git_ssh path to a
    #   custom SSH executable
    #
    # @option opts [String, :use_global_config] :binary_path path to the git
    #   binary
    #
    # @option opts [String, nil] :index custom index path for the returned
    #   repository
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
    # @option opts [String, nil] :repository alternate git directory path
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

    # Resolve the repository, working directory, and index paths for a repository
    #
    # @param dir [String] the bare git directory, or the working directory of a
    #   non-bare repository
    #
    # @param bare [Boolean] whether the repository is bare
    #
    # @param index [String, nil] optional custom index path
    #
    # @param repository [String, nil] optional custom `.git` directory path;
    #   ignored when `bare` is `true`
    #
    # @return [Hash{Symbol => (String, nil)}] resolved path hash
    #
    # @api private
    #
    def resolve_repository_paths(dir, bare:, index:, repository: nil)
      args = bare ? { repository: dir, bare: true } : { working_directory: dir, repository: repository }
      PathResolver.resolve_paths(**args, index: index)
    end

    # Run the `git init` command using a global execution context
    #
    # @param directory [String] the directory to initialize
    #
    # @param options [Hash] the normalized options hash (after alias resolution)
    #
    # @option options [Boolean, nil] :bare create a bare repository at
    #   `directory`
    #
    # @option options [String, nil] :initial_branch the name for the initial
    #   branch
    #
    # @option options [String, nil] :repository path for the `.git` directory
    #
    # @option options [String, :use_global_config] :binary_path path to the
    #   git binary
    #
    # @option options [String, nil, :use_global_config] :git_ssh path to a
    #   custom SSH executable
    #
    # @option options [Logger, nil] :log logger used for git operations
    #
    # @return [Git::CommandLine::Result] the result of running `git init`
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
    # @option options [Boolean, nil] :bare create a bare repository at
    #   `directory`
    #
    # @option options [String, nil] :repository path for the `.git` directory
    #
    # @option options [String, nil] :index custom index path for the returned
    #   repository
    #
    # @option options [String, :use_global_config] :binary_path path to the
    #   git binary
    #
    # @option options [String, nil, :use_global_config] :git_ssh path to a
    #   custom SSH executable
    #
    # @option options [Logger, nil] :log logger used for git operations
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
    # @option options [String, nil, :use_global_config] :git_ssh path to a
    #   custom SSH executable
    #
    # @option options [String, :use_global_config] :binary_path path to the
    #   git binary
    #
    # @option options [Logger, nil] :log logger used for git operations
    #
    # @option options [String, nil] :index custom index path for the returned
    #   repository
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
        open_opts[:index] = options[:index] if options[:index]
      end
    end

    # Build worktree options for opening a repository after `git init`
    #
    # @param options [Hash] the normalized options hash
    #
    # @option options [String, nil, :use_global_config] :git_ssh path to a
    #   custom SSH executable
    #
    # @option options [String, :use_global_config] :binary_path path to the
    #   git binary
    #
    # @option options [Logger, nil] :log logger used for git operations
    #
    # @option options [String, nil] :index custom index path for the returned
    #   repository
    #
    # @option options [String, nil] :repository path for the `.git` directory
    #
    # @return [Hash{Symbol => Object}] options accepted by {.open}
    #
    # @api private
    #
    def worktree_open_options_after_init(options)
      base_open_options_after_init(options).tap do |open_opts|
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
  end
end
