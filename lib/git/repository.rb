# frozen_string_literal: true

require 'find'
require 'pathname'

require 'git/execution_context/repository'
require 'git/repository/branching'
require 'git/repository/committing'
require 'git/repository/configuring'
require 'git/repository/diffing'
require 'git/repository/inspecting'
require 'git/repository/logging'
require 'git/repository/merging'
require 'git/repository/object_operations'
require 'git/repository/path_resolver'
require 'git/repository/remote_operations'
require 'git/repository/staging'
require 'git/repository/stashing'
require 'git/repository/status_operations'
require 'git/repository/worktree_operations'

module Git
  # The main public interface for interacting with a Git repository
  #
  # `Git::Repository` is the **orchestration layer** for all git operations. It acts
  # as the glue between the user-facing API and the underlying components, but
  # contains minimal domain logic itself. For each operation it:
  #
  # 1. **Pre-processes arguments** — transforms user-provided values into forms
  #    suitable for the command layer (e.g. path expansion, option normalization,
  #    Ruby-idiomatic defaults, deprecation handling, input validation).
  # 2. **Calls commands** — invokes one or more `Git::Commands::*` classes via the
  #    injected `Git::ExecutionContext::Repository`.
  # 3. **Builds rich return values** — passes raw command output through
  #    `Git::Parsers::*` classes and result-class factory methods to assemble the
  #    meaningful Ruby objects the caller expects.
  #
  # Some operations are genuinely one-line delegators when no pre/post-processing is
  # needed (e.g. `add`, `reset`), but many are short orchestration sequences that
  # coordinate argument preparation, one or more command calls, and result assembly.
  #
  # Facade methods are organized into focused modules under `lib/git/repository/`
  # (e.g. {Git::Repository::Staging}) and included into this class.
  #
  # @api public
  #
  class Repository
    include Git::Repository::Branching
    include Git::Repository::Committing
    include Git::Repository::Configuring
    include Git::Repository::Diffing
    include Git::Repository::Inspecting
    include Git::Repository::Logging
    include Git::Repository::Merging
    include Git::Repository::ObjectOperations
    include Git::Repository::RemoteOperations
    include Git::Repository::Staging
    include Git::Repository::Stashing
    include Git::Repository::StatusOperations
    include Git::Repository::WorktreeOperations

    # Open a working copy at an existing path
    #
    # The new repository factories are additive scaffolding introduced by the
    # architectural redesign. The top-level {Git.open} entry point still returns a
    # {Git::Base} object; this method exists so future work can route construction
    # through {Git::Repository} without changing the public entry points.
    #
    # Note: this method opens working copies only. To open a bare repository, use
    # {Git::Repository.bare}.
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
    # @option options [String] :repository a non-standard path to the `.git`
    #   directory
    #
    #   When given, `working_dir` is used as-is (the working tree root is not
    #   auto-detected).
    #
    # @option options [String] :index a non-standard path to the index file
    #
    # @option options [Logger] :log a logger forwarded to the command layer
    #
    # @option options [String, nil, :use_global_config] :git_ssh path to a custom SSH executable;
    #   pass `:use_global_config` (the default) to use `Git::Base.config.git_ssh`
    #
    # @option options [String, :use_global_config] :binary_path path to the git binary;
    #   pass `:use_global_config` (the default) to use `Git::Base.config.binary_path`
    #
    # @return [Git::Repository] a repository bound to the resolved paths
    #
    # @raise [ArgumentError] if `working_dir` is not a directory or is not inside
    #   a git working tree
    #
    def self.open(working_dir, options = {})
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
    # The new repository factories are additive scaffolding introduced by the
    # architectural redesign. The top-level {Git.bare} entry point still returns a
    # {Git::Base} object; this method exists so future work can route construction
    # through {Git::Repository} without changing the public entry points.
    #
    # @example Open a bare repository
    #   repository = Git::Repository.bare('/path/to/repo.git')
    #
    # @param git_dir [String] the path to the bare repository directory
    #
    # @param options [Hash] options forwarded to the constructed repository
    #
    # @option options [Logger] :log a logger forwarded to the command layer
    #
    # @option options [String, nil, :use_global_config] :git_ssh path to a custom SSH executable;
    #   pass `:use_global_config` (the default) to use `Git::Base.config.git_ssh`
    #
    # @option options [String, :use_global_config] :binary_path path to the git binary;
    #   pass `:use_global_config` (the default) to use `Git::Base.config.binary_path`
    #
    # @return [Git::Repository] a repository bound to the bare repository directory
    #
    def self.bare(git_dir, options = {})
      paths = PathResolver.resolve_paths(repository: git_dir, bare: true)

      from_paths(options, paths)
    end

    # Resolve the worktree root to use as the working directory for `.open`
    #
    # Delegates to {PathResolver.root_of_worktree}, forwarding `:binary_path`
    # and `:git_ssh` from `options`.
    #
    # @param working_dir [String] a path inside the working tree
    #
    # @param options [Hash] the caller-supplied options hash from `.open`
    #
    # @return [String] the absolute path to the root of the working tree
    #
    # @raise [ArgumentError] if `working_dir` is not inside a git working tree
    #
    # @api private
    #
    def self.resolve_open_working_dir(working_dir, options)
      PathResolver.root_of_worktree(
        working_dir,
        binary_path: options.fetch(:binary_path, :use_global_config),
        git_ssh: options.fetch(:git_ssh, :use_global_config)
      )
    end
    private_class_method :resolve_open_working_dir

    # Build a repository from caller options and resolved paths
    #
    # @param options [Hash] the caller-supplied options (`:git_ssh`,
    #   `:binary_path`, `:log`)
    #
    # @param paths [Hash{Symbol => (String, nil)}] the resolved
    #   `:working_directory`, `:repository`, and `:index` paths
    #
    # @return [Git::Repository] the constructed repository
    #
    # @api private
    #
    def self.from_paths(options, paths)
      execution_context = Git::ExecutionContext::Repository.from_hash(
        options.merge(paths), logger: options[:log]
      )
      new(execution_context: execution_context)
    end
    private_class_method :from_paths

    # @return [Git::ExecutionContext::Repository] the execution context used to run
    #   git commands for this repository
    # @api private
    attr_reader :execution_context

    # @param execution_context [Git::ExecutionContext::Repository] the context used
    #   to run git commands for this repository; must not be nil
    #
    # @raise [ArgumentError] if `execution_context` is nil
    #
    def initialize(execution_context:)
      raise ArgumentError, 'execution_context must not be nil' if execution_context.nil?

      @execution_context = execution_context
    end

    # Returns the root of the working tree, or `nil` for a bare repository
    #
    # @example Get the working directory path
    #   repository.dir #=> #<Pathname:/path/to/repo>
    #
    # @return [Pathname, nil] the working directory path, or `nil` when bare
    #
    def dir
      working_dir = execution_context.git_work_dir
      working_dir && Pathname.new(working_dir)
    end

    # Returns the repository (`.git`) directory
    #
    # @example Get the repository directory path
    #   repository.repo #=> #<Pathname:/path/to/repo/.git>
    #
    # @return [Pathname, nil] the repository directory path
    #
    def repo
      repository = execution_context.git_dir
      repository && Pathname.new(repository)
    end

    # Returns the git index file
    #
    # @example Get the index file path
    #   repository.index #=> #<Pathname:/path/to/repo/.git/index>
    #
    # @return [Pathname, nil] the index file path
    #
    def index
      index_file = execution_context.git_index_file
      index_file && Pathname.new(index_file)
    end

    # Returns the size of the repository directory in bytes
    #
    # Sums the sizes of every regular file under the repository (`.git`)
    # directory in a single traversal. Symbolic links are not followed, so files
    # that physically live outside the repository (reached through a symlinked
    # directory) are never counted. Files that disappear mid-traversal are
    # silently skipped.
    #
    # @example Get the repository size in bytes
    #   repository.repo_size #=> 12345
    #
    # @return [Integer] the total size in bytes of the repository directory
    #
    def repo_size
      repository = repo
      return 0 unless repository&.directory?

      total = 0
      Find.find(repository.to_s) do |path|
        stat = File.lstat(path)
        total += stat.size if stat.file?
      rescue Errno::ENOENT
        next
      end
      total
    end
  end
end
