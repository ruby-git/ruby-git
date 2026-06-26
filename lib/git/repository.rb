# frozen_string_literal: true

require 'find'
require 'pathname'

require 'git/configuring'
require 'git/deprecation'
require 'git/execution_context/repository'
require 'git/repository/branching'
require 'git/repository/context_helpers'
require 'git/repository/committing'
require 'git/repository/diffing'
require 'git/repository/factories'
require 'git/repository/inspecting'
require 'git/repository/logging'
require 'git/repository/maintenance'
require 'git/repository/merging'
require 'git/repository/object_operations'
require 'git/repository/remote_operations'
require 'git/repository/shared_private'
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
  class Repository # rubocop:disable Metrics/ClassLength
    extend Git::Repository::Factories

    include Git::Configuring
    include Git::Repository::Branching
    include Git::Repository::ContextHelpers
    include Git::Repository::Committing
    include Git::Repository::Diffing
    include Git::Repository::Inspecting
    include Git::Repository::Logging
    include Git::Repository::Maintenance
    include Git::Repository::Merging
    include Git::Repository::ObjectOperations
    include Git::Repository::RemoteOperations
    include Git::Repository::Staging
    include Git::Repository::Stashing
    include Git::Repository::StatusOperations
    include Git::Repository::WorktreeOperations

    CONFIG_SET_ALLOWED_OPTS = %i[file].freeze
    private_constant :CONFIG_SET_ALLOWED_OPTS

    CONFIG_READ_ALLOWED_OPTS = %i[file].freeze
    private_constant :CONFIG_READ_ALLOWED_OPTS

    CONFIG_DEPRECATION_WARNING =
      'Git::Repository#config is deprecated and will be removed in v6.0.0. ' \
      'Use config_get(name), config_set(name, value), or config_list instead.'
    private_constant :CONFIG_DEPRECATION_WARNING

    GLOBAL_CONFIG_DEPRECATION_WARNING =
      'Git::Repository#global_config is deprecated and will be removed in v6.0.0. ' \
      'Use config_get(name, global: true), config_set(name, value, global: true), ' \
      'or config_list(global: true) instead.'
    private_constant :GLOBAL_CONFIG_DEPRECATION_WARNING

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

    # Returns `self` after emitting a deprecation warning.
    #
    # Legacy callers that used `git.lib.some_method` can migrate to calling the
    # facade method directly on the repository object. This shim will be removed
    # in v6.0.0.
    #
    # @return [self]
    #
    # @api private
    #
    def lib
      Git::Deprecation.warn(
        'Git::Repository#lib is deprecated and will be removed in v6.0.0. ' \
        'Use the repository object directly.'
      )
      self
    end

    # @return [String, nil] the git directory path
    #
    # @api private
    def git_dir = execution_context.git_dir

    # @return [String, nil] the working directory path
    #
    # @api private
    def git_work_dir = execution_context.git_work_dir

    # @return [String, nil] the index file path
    #
    # @api private
    def git_index_file = execution_context.git_index_file

    # @return [Git::Version] the installed git version
    #
    # @api private
    def git_version(timeout: nil) = execution_context.git_version(timeout: timeout)

    # @return [String, nil] the SSH wrapper path
    #
    # @api private
    def git_ssh = execution_context.git_ssh

    # @return [String, :use_global_config] the path to the git binary
    #
    # @api private
    def binary_path = execution_context.binary_path

    # Read or write a git configuration entry
    #
    # Dispatches to one of three modes depending on the arguments supplied:
    #
    # * **List** — `config()` returns all visible config entries as a `Hash`.
    # * **Get** — `config(name)` returns the value for a single key as a `String`.
    # * **Set** — `config(name, value)` writes a value and returns the raw
    #   command result.
    #
    # @overload config(options = {})
    #
    #   @example List all config entries
    #     repo.config #=> { "user.name" => "Alice", "core.bare" => "false" }
    #
    #   @example List all entries from a custom config file
    #     repo.config(file: '/path/to/.gitconfig')
    #     #=> { "user.name" => "Alice", "core.bare" => "false" }
    #
    #   @param options [Hash] options for the list operation
    #
    #   @option options [String, nil] :file (nil) path to a custom config file
    #     to read from instead of the default resolution chain
    #
    #   @return [Hash{String => String}] all visible config entries, keyed by
    #     their full dotted key names (e.g. `"user.name"`)
    #
    #   @raise [ArgumentError] if unsupported options are provided
    #
    # @overload config(name, options = {})
    #
    #   @example Read the committer name from config
    #     repo.config('user.name') #=> "Alice"
    #
    #   @example Read a value from a custom config file
    #     repo.config('user.name', file: '/path/to/.gitconfig') #=> "Alice"
    #
    #   @param name [String] the dotted config key to look up (e.g.
    #     `"user.name"`)
    #
    #   @param options [Hash] options for the get operation
    #
    #   @option options [String, nil] :file (nil) path to a custom config file
    #     to read from instead of the default resolution chain
    #
    #   @return [String] the value of the config entry
    #
    #   @raise [ArgumentError] if unsupported options are provided
    #
    # @overload config(name, value, options = {})
    #
    #   @example Set the committer name in local config
    #     repo.config('user.name', 'Alice')
    #
    #   @example Write a value to a custom config file
    #     repo.config('user.name', 'Alice', file: '/path/to/custom/config')
    #
    #   @param name [String] the dotted config key to write (e.g.
    #     `"user.name"`)
    #
    #   @param value [#to_s] the value to assign; must not be `nil` (a `nil`
    #     value is treated as "no value" and routes to the get overload).
    #     Must not be a `Hash` (a Hash is treated as the `options` argument;
    #     call `value.to_s` explicitly before passing if a stringified Hash
    #     is genuinely needed). Any other non-nil object is converted to a
    #     String via `#to_s` before being passed to git
    #
    #   @param options [Hash] options for the set operation
    #
    #   @option options [String, nil] :file (nil) path to a custom config file
    #     to write to instead of the repository's default `.git/config`
    #
    #   @return [Git::CommandLineResult] the raw result of
    #     `git config <name> <value>`
    #
    #   @raise [ArgumentError] if unsupported options are provided
    #
    # @raise [Git::FailedError] if git exits with a non-zero exit status
    #
    def config(name = nil, value = nil, options = {})
      Git::Deprecation.warn(CONFIG_DEPRECATION_WARNING)
      name, value, options = deprecated_normalize_config_args(name, value, options)

      if !name.nil? && !value.nil?
        deprecated_config_set(name, value, **options)
      elsif name
        deprecated_config_get(name, **options)
      else
        deprecated_config_list(**options)
      end
    end

    # Read or write a global git configuration entry
    #
    # Dispatches to one of three modes depending on the arguments supplied,
    # targeting the git global config scope (`git config --global`):
    #
    # * **List** — `global_config()` returns all global config entries as a `Hash`.
    # * **Get** — `global_config(name)` returns the value for a single key as a `String`.
    # * **Set** — `global_config(name, value)` writes a value and returns the raw
    #   command result.
    #
    # @overload global_config
    #
    #   @example List all global config entries
    #     repo.global_config #=> { "user.name" => "Alice", "core.autocrlf" => "false" }
    #
    #   @return [Hash{String => String}] all global config entries, keyed by their
    #     full dotted key names (e.g. `"user.name"`)
    #
    #   @raise [Git::FailedError] if git exits with a non-zero exit status
    #
    # @overload global_config(name)
    #
    #   @example Read the global committer name
    #     repo.global_config('user.name') #=> "Alice"
    #
    #   @param name [String] the dotted config key to look up (e.g. `"user.name"`)
    #
    #   @return [String] the value of the global config entry
    #
    #   @raise [Git::FailedError] if git exits with a non-zero exit status
    #
    # @overload global_config(name, value)
    #
    #   @example Set the global committer name
    #     repo.global_config('user.name', 'Alice')
    #
    #   @param name [String] the dotted config key to write (e.g. `"user.name"`)
    #
    #   @param value [#to_s] the value to assign; any object is accepted and
    #     converted to a String via `#to_s` before being passed to git
    #
    #   @return [Git::CommandLineResult] the raw result of
    #     `git config --global <name> <value>`
    #
    #   @raise [Git::FailedError] if git exits with a non-zero exit status
    #
    def global_config(name = nil, value = nil)
      Git::Deprecation.warn(GLOBAL_CONFIG_DEPRECATION_WARNING)
      if !name.nil? && !value.nil?
        deprecated_global_config_set(name, value)
      elsif !name.nil?
        deprecated_global_config_get(name)
      else
        deprecated_global_config_list
      end
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

    private

    def deprecated_normalize_config_args(name, value, options)
      if name.is_a?(Hash)
        raise ArgumentError, 'unexpected positional arguments after options hash' if !value.nil? || !options.empty?

        [nil, nil, name]
      elsif value.is_a?(Hash)
        raise ArgumentError, 'unexpected third argument when second argument is options hash' unless options.empty?

        [name, nil, value]
      else
        [name, value, options]
      end
    end

    def deprecated_config_set(name, value, **)
      SharedPrivate.assert_valid_opts!(CONFIG_SET_ALLOWED_OPTS, **)
      Git::Commands::ConfigOptionSyntax::Set.new(@execution_context).call(name, value, **)
    end

    def deprecated_config_get(name, **options)
      SharedPrivate.assert_valid_opts!(CONFIG_READ_ALLOWED_OPTS, **options)
      opts = options[:file] ? { file: options[:file] } : {}
      result = Git::Commands::ConfigOptionSyntax::Get.new(@execution_context).call(name, **opts)
      raise Git::FailedError, result if result.status.exitstatus != 0

      result.stdout
    end

    def deprecated_config_list(**options)
      SharedPrivate.assert_valid_opts!(CONFIG_READ_ALLOWED_OPTS, **options)
      opts = options[:file] ? { file: options[:file] } : {}
      lines = Git::Commands::ConfigOptionSyntax::List.new(@execution_context).call(**opts).stdout.split("\n")
      lines.each_with_object({}) do |line, hsh|
        key, value = line.split('=', 2)
        hsh[key] = value || ''
      end
    end

    def deprecated_global_config_get(name)
      result = Git::Commands::ConfigOptionSyntax::Get.new(@execution_context).call(name, global: true)
      raise Git::FailedError, result if result.status.exitstatus != 0

      result.stdout
    end

    def deprecated_global_config_list
      lines = Git::Commands::ConfigOptionSyntax::List.new(@execution_context).call(global: true).stdout.split("\n")
      lines.each_with_object({}) do |line, hsh|
        key, value = line.split('=', 2)
        hsh[key] = value || ''
      end
    end

    def deprecated_global_config_set(name, value)
      Git::Commands::ConfigOptionSyntax::Set.new(@execution_context).call(name, value, global: true)
    end

    # All git config scopes are valid in a repository context
    #
    # @return [void]
    #
    def assert_valid_scope!(**)
      nil
    end
  end
end
