# frozen_string_literal: true

require 'git/commands/clone'
require 'git/commands/init'
require 'git/execution_context/global'
require 'git/execution_context/repository'
require 'git/path_resolver'
require 'git/repository'
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
    # Option keys {Git.open} accepts
    #
    # @return [Array<Symbol>]
    #
    # @api private
    #
    OPEN_ALLOWED_OPTS = %i[repository index log git_ssh binary_path].freeze
    private_constant :OPEN_ALLOWED_OPTS

    # Option keys {Git.bare} accepts
    #
    # @return [Array<Symbol>]
    #
    # @api private
    #
    BARE_ALLOWED_OPTS = %i[index log git_ssh binary_path].freeze
    private_constant :BARE_ALLOWED_OPTS

    # Option keys {Git.init} accepts
    #
    # @return [Array<Symbol>]
    #
    # @api private
    #
    INIT_ALLOWED_OPTS = %i[bare initial_branch repository separate_git_dir index log git_ssh binary_path].freeze
    private_constant :INIT_ALLOWED_OPTS

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
    #   Expanded before git runs, so `~` is the home directory and a relative
    #   path is relative to `:chdir` when given and to the process working
    #   directory otherwise. git creates the expanded directory, and the
    #   returned repository is bound to it.
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
    # @option options [String, nil] :repository alternate git directory path
    #
    #   Writes a gitfile in the working tree. Alias: `:separate_git_dir`.
    #   Expanded before git runs, like `directory`: `~` is the home directory
    #   and a relative path is relative to `:chdir` when given and to the
    #   process working directory otherwise.
    #
    # @option options [String, nil] :separate_git_dir alias for `:repository`
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
    #   Expanded before git runs, like `directory`: a relative path is expanded
    #   against `:chdir` when given, and against the process working directory
    #   otherwise.
    #
    # @option options [String, Pathname, nil] :chdir run `git clone` from within
    #   this directory
    #
    #   Expanded before git runs, so `~` is the home directory and a relative
    #   path is relative to the process working directory. `directory`,
    #   `:repository`, and `:index` are expanded against the expanded value.
    #
    # @return [Git::Repository] a repository bound to the cloned working copy or
    #   bare repository
    #
    # @raise [ArgumentError] if unsupported options are provided, or if
    #   `directory`, `:repository`, `:index`, or `:chdir` begins with `~user`
    #   for a user that does not exist
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
      directory = expand_directory(directory, bare: context_opts[:bare], base: opts[:chdir]) if directory
      clone_result = run_clone_command(repository_url, directory, opts, context_opts)
      paths = resolve_paths_from_clone_result(clone_result, directory, opts, context_opts)

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
    #   Expanded before git runs, so `~` is the home directory and a relative
    #   path is relative to the process working directory. git creates the
    #   expanded directory, and the returned repository is bound to it.
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
    #   Expanded before git runs, like `directory`: `~` is the home directory
    #   and a relative path is relative to the process working directory.
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
    #   Expanded before git runs, like `directory`: `~` is the home directory
    #   and a relative path is relative to the process working directory.
    #
    # @return [Git::Repository] a repository bound to the newly initialized repository
    #
    # @raise [ArgumentError] if `options` contains an unknown key
    #
    # @raise [ArgumentError] if `directory`, `:repository`, or `:index` begins
    #   with `~user` for a user that does not exist
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
      reject_unknown_option_keys!(options.keys, INIT_ALLOWED_OPTS)
      options = normalize_init_options(options)
      directory = expand_directory(directory, bare: options[:bare])

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
    #   Expanded before use: `~` is the home directory and a relative path is
    #   relative to the process working directory.
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
    # @raise [ArgumentError] if `options` contains an unknown key
    #
    # @raise [ArgumentError] if `working_dir` is not a directory or is not inside
    #   a git working tree, or if it begins with `~user` for a user that does not
    #   exist
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
      reject_unknown_option_keys!(options.keys, OPEN_ALLOWED_OPTS)
      expanded_dir = PathResolver.expand_path(working_dir, PathResolver::WORKING_DIRECTORY_MESSAGE)
      raise ArgumentError, "'#{working_dir}' is not a directory" unless Dir.exist?(expanded_dir)

      working_dir = options[:repository] ? expanded_dir : resolve_open_working_dir(expanded_dir, options)

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
    # @raise [ArgumentError] if `options` contains an unknown key
    #
    # @raise [Git::Error] if `git_dir` is a gitdir pointer file that cannot be read
    #
    # @api public
    #
    def bare(git_dir, options = {})
      reject_unknown_option_keys!(options.keys, BARE_ALLOWED_OPTS)
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
    # When the caller gave a directory, it was expanded before git ran and is
    # used as is. Only when git derived the name from the URL is the directory
    # read from git's output, where it is a relative name under `:chdir`.
    #
    # @param clone_result [Git::CommandLine::Result] the completed clone result
    #
    # @param directory [String, nil] the expanded directory given to {.clone},
    #   or `nil` when git derived the name from the URL
    #
    # @param opts [Hash] command-ready clone options
    #
    # @param context_opts [Hash] context options produced while preparing clone
    #   options
    #
    # @option opts [String, Pathname, nil] :chdir run `git clone` from within
    #   this directory
    #
    # @option context_opts [Boolean] :bare whether `:bare` or `:mirror` was
    #   requested
    #
    # @option context_opts [String, nil] :index the already expanded custom
    #   index path for the returned repository
    #
    # @return [Hash{Symbol => (String, nil)}] resolved path hash
    #
    # @raise [Git::UnexpectedResultError] if no directory was given and the clone
    #   directory cannot be parsed from git's output
    #
    # @api private
    #
    def resolve_paths_from_clone_result(clone_result, directory, opts, context_opts)
      clone_dir = directory || prefix_with_chdir(parse_clone_directory(clone_result.stderr), opts[:chdir])

      bare = context_opts[:bare] || bare_clone?(clone_result.stderr)
      resolve_repository_paths(clone_dir, bare: bare, index: context_opts[:index])
    end

    # Expand the directory given to {.init} or {.clone} before git sees it
    #
    # git does not expand `~` in a path on its command line, so the expansion
    # happens here. The directory git creates is then the one the returned
    # repository is bound to.
    #
    # @param directory [String, Pathname] the directory to initialize or clone
    #   into
    #
    # @param bare [Boolean, nil] whether the directory is the bare repository
    #   itself rather than a working directory; selects the error message
    #
    # @param base [String, Pathname, nil] the directory a relative path is
    #   expanded against, or `nil` for the process working directory
    #
    # @return [String] the absolute path
    #
    # @raise [ArgumentError] if the path begins with `~user` for a user that
    #   does not exist
    #
    # @raise [Git::Error] if the path cannot be expanded, which happens when the
    #   process working directory has been removed
    #
    # @api private
    #
    def expand_directory(directory, bare:, base: nil)
      message = bare ? PathResolver::REPOSITORY_MESSAGE : PathResolver::WORKING_DIRECTORY_MESSAGE
      PathResolver.expand_path(directory, message, base: base)
    end

    # Join the clone directory git reported onto the `:chdir` it ran in
    #
    # Used only when no directory was given to {.clone}: git derives a relative
    # name from the URL and creates it under `chdir`. An absolute path, should
    # git ever report one, passes through unchanged.
    #
    # @param path [String] the clone directory reported by `git clone`
    #
    # @param chdir [String, Pathname, nil] the directory git ran in, or `nil`
    #
    # @return [String] `path` prefixed with `chdir` when `chdir` is given and
    #   `path` is relative; otherwise `path` unchanged
    #
    # @api private
    #
    def prefix_with_chdir(path, chdir)
      return path if chdir.nil? || Pathname.new(path).absolute?

      File.join(chdir, path)
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

    # Raise if `keys` contains a key outside `allowed`
    #
    # @param keys [Array<Symbol>] the keys of the caller-supplied options
    #
    # @param allowed [Array<Symbol>] the keys the factory accepts
    #
    # @return [void]
    #
    # @raise [ArgumentError] if `keys` contains an unknown key
    #
    # @api private
    #
    def reject_unknown_option_keys!(keys, allowed)
      unknown = keys - allowed
      raise ArgumentError, "Unknown options: #{unknown.join(', ')}" unless unknown.empty?
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
      expand_path_option!(opts, :chdir, PathResolver::CHDIR_MESSAGE)
      normalize_clone_repository_option!(opts)
      expand_path_option!(context_opts, :index, PathResolver::INDEX_MESSAGE, base: opts[:chdir])

      [opts, context_opts]
    end

    # Expand a path option in place when it is present
    #
    # git does no tilde expansion and ruby-git starts it without a shell, so
    # every path option is expanded here before git sees it. A path that cannot
    # be expanded is rejected before git runs.
    #
    # @param hash [Hash] the options hash (mutated in place)
    #
    # @param key [Symbol] the option to expand; left alone when `nil` or absent
    #
    # @param message [String] the {Git::Error} message when expansion fails
    #
    # @param base [String, Pathname, nil] the directory a relative path is
    #   expanded against, or `nil` for the process working directory
    #
    # @return [void] mutates `hash` in place
    #
    # @raise [ArgumentError] if the path begins with `~user` for a user that
    #   does not exist
    #
    # @raise [Git::Error] if the path cannot be expanded, which happens when the
    #   process working directory has been removed
    #
    # @api private
    #
    def expand_path_option!(hash, key, message, base: nil)
      return unless hash[key]

      hash[key] = PathResolver.expand_path(hash[key], message, base: base)
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
    # @option opts [Boolean, nil] :bare clone as a bare repository; left in
    #   `opts` for git
    #
    # @option opts [Boolean, nil] :mirror set up a mirror of the source; left in
    #   `opts` for git
    #
    # @return [Hash{Symbol => Object}] context options for clone setup, with
    #   `:bare` true when either `:bare` or `:mirror` was requested
    #
    # @api private
    #
    def extract_clone_context_options!(opts)
      {
        logger: opts.delete(:log),
        git_ssh: opts.key?(:git_ssh) ? opts.delete(:git_ssh) : :use_global_config,
        binary_path: opts.key?(:binary_path) ? opts.delete(:binary_path) : :use_global_config,
        index: opts.delete(:index),
        bare: opts[:bare] || opts[:mirror] || false
      }
    end

    # Normalize the clone repository option for `git clone`
    #
    # Resolves the `:separate_git_dir` alias to `:repository`, then renames
    # `:repository` to `:separate_git_dir` and expands it before git runs,
    # against `:chdir` when given, like the clone directory. git does no tilde
    # expansion, so a `~`-prefixed path handed to git would create a directory
    # literally named `~`.
    #
    # @param opts [Hash] clone options (mutated in place)
    #
    # @option opts [String, nil] :repository alternate git directory path
    #
    # @option opts [String, nil] :separate_git_dir alias for `:repository`
    #
    # @option opts [String, Pathname, nil] :chdir the directory git runs in
    #
    # @return [void] mutates `opts` in place
    #
    # @raise [ArgumentError] if `:repository` begins with `~user` for a user
    #   that does not exist
    #
    # @raise [Git::Error] if the path cannot be expanded, which happens when the
    #   process working directory has been removed
    #
    # @api private
    #
    def normalize_clone_repository_option!(opts)
      resolve_repository_alias!(opts)
      repository_val = opts.delete(:repository)
      return unless repository_val

      opts[:separate_git_dir] =
        PathResolver.expand_path(repository_val, PathResolver::REPOSITORY_MESSAGE, base: opts[:chdir])
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

    # Normalize the options given to {.init}
    #
    # Resolves the `:separate_git_dir` alias to `:repository` and expands
    # `:repository` and `:index` before git runs, so the git directory git
    # creates is the one the returned repository is bound to and a path that
    # cannot be expanded is rejected before a repository is left on disk.
    #
    # @param options [Hash] the caller-supplied options hash
    #
    # @option options [String, nil] :repository path for the `.git` directory
    #
    # @option options [String, nil] :separate_git_dir alias for `:repository`
    #
    # @option options [String, nil] :index custom index path for the returned
    #   repository
    #
    # @return [Hash] a new options hash with `:repository` set and expanded when
    #   either spelling was given, and `:index` expanded when given
    #
    # @raise [ArgumentError] if `:repository` or `:index` begins with `~user`
    #   for a user that does not exist
    #
    # @raise [Git::Error] if a path cannot be expanded, which happens when the
    #   process working directory has been removed
    #
    # @api private
    #
    def normalize_init_options(options)
      options = options.dup
      resolve_repository_alias!(options)
      expand_path_option!(options, :repository, PathResolver::REPOSITORY_MESSAGE)
      expand_path_option!(options, :index, PathResolver::INDEX_MESSAGE)
      options
    end

    # Resolve the `:separate_git_dir` alias onto `:repository`
    #
    # `:separate_git_dir` is removed. Its value becomes `:repository` unless
    # `:repository` was given a non-nil value, which wins.
    #
    # @param options [Hash] factory options (mutated in place)
    #
    # @option options [String, nil] :repository path for the git directory
    #
    # @option options [String, nil] :separate_git_dir alias for `:repository`
    #
    # @return [void] mutates `options` in place
    #
    # @api private
    #
    def resolve_repository_alias!(options)
      return unless options.key?(:separate_git_dir)

      separate_git_dir = options.delete(:separate_git_dir)
      options[:repository] = separate_git_dir if options[:repository].nil?
    end

    # Run the `git init` command using a global execution context
    #
    # @param directory [String] the absolute path of the directory to initialize
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

    # Parse the directory git derived from the URL out of `git clone` stderr
    #
    # Only called when no directory was given to {.clone}. The name git derives
    # is a single path component, so it never spans a line.
    #
    # @param stderr [String] stderr output from `git clone`
    #
    # @return [String] the clone directory git reported
    #
    # @raise [Git::UnexpectedResultError] if the stderr output cannot be parsed
    #
    # @api private
    #
    def parse_clone_directory(stderr)
      match = stderr.match(/^Cloning into (?:bare repository )?'(.+)'\.\.\.$/)
      raise Git::UnexpectedResultError, "Unable to determine clone directory from: #{stderr}" unless match

      match[1]
    end

    # Whether `git clone` reported that it created a bare repository
    #
    # Matches only the fixed prefix of git's progress line, so a destination
    # that spans several lines does not affect the result.
    #
    # @param stderr [String] stderr output from `git clone`
    #
    # @return [Boolean] true when git reported a bare repository
    #
    # @api private
    #
    def bare_clone?(stderr)
      stderr.match?(/^Cloning into bare repository '/)
    end
  end
end
