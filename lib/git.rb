# frozen_string_literal: true

require 'active_support'
require 'active_support/deprecation'

require 'git/deprecation'
require 'git/version'

module Git
  # Minimum git version required by this gem
  #
  # Commands and features may require newer versions, but this is the absolute
  # minimum supported version for the gem as a whole.
  #
  # @return [Git::Version]
  #
  # @api public
  #
  MINIMUM_GIT_VERSION = Version.parse('2.28.0')
end

require 'git/author'
require 'git/branch'
require 'git/branch_info'
require 'git/branches'
require 'git/command_line_result'
require 'git/command_line'
require 'process_executer'
require 'git/config'
require 'git/config_entry_info'
require 'git/parsers/config_entry'
require 'git/configuring'
require 'git/diff'
require 'git/diff_file_numstat_info'
require 'git/diff_file_patch_info'
require 'git/diff_file_raw_info'
require 'git/diff_info'
require 'git/parsers/diff'
require 'git/diff_result'
require 'git/dirstat_info'
require 'git/encoding_utils'
require 'git/errors'
require 'git/escaped_path'
require 'git/execution_context'
require 'git/execution_context/global'
require 'git/file_ref'
require 'git/fsck_object'
require 'git/fsck_result'
require 'git/parsers/ls_remote'
require 'git/version_constraint'
require 'git/commands'
require 'git/log'
require 'git/object'
require 'git/remote'
require 'git/repository'
require 'git/status'
require 'git/stash'
require 'git/stash_info'
require 'git/stashes'
require 'git/tag_delete_failure'
require 'git/tag_delete_result'
require 'git/tag_info'
require 'git/url'
require 'git/worktree'
require 'git/worktrees'

# The Git module provides the basic functions to open a git
# reference to work with. You can open a working directory,
# open a bare repository, initialize a new repo or clone an
# existing remote repository.
#
# @author Scott Chacon (mailto:schacon@gmail.com)
#
module Git
  extend Git::Configuring
  extend Git::Repository::Factories

  # Gets or sets local git configuration options
  #
  # @overload config(name, value)
  #   Set the value for the git named configuration option
  #
  #   @param name [String] the name of the git configuration option
  #
  #   @param value [String, Boolean] the value to set for the git configuration option
  #
  #   @return [Git::CommandLine::Result] the result of the git configuration command
  #
  # @overload config(name)
  #   Get the value for the git named configuration option
  #
  #   @param name [String] the name of the git configuration option
  #
  #   @return [String] the value of the git configuration option
  #
  # @overload config()
  #   List all git configuration options
  #
  #   @return [Hash{String => String}] a hash of all git configuration options
  #
  # @deprecated Mixing in the `Git` module is deprecated and will be removed in v6.0.0.
  #   Use `Git.config_get(name)`, `Git.config_set(name, value)`, or `Git.config_list` instead.
  #
  def config(name = nil, value = nil)
    Git::Deprecation.warn(
      'Git#config is deprecated and will be removed in v6.0.0. ' \
      'Use Git.config_get(name), Git.config_set(name, value), or Git.config_list instead.'
    )
    Git.__send__(:legacy_config_set_get_list, name, value, global: false)
  end

  # Configures the gem by yielding {Git::Config.instance} to the block
  #
  # @example Set the global git binary path
  #   Git.configure { |c| c.binary_path = '/usr/local/bin/git' }
  #
  # @return [void]
  #
  # @yield [config] yields the singleton config object
  #
  # @yieldparam config [Git::Config] the singleton config object
  #
  # @yieldreturn [void]
  #
  def self.configure
    yield Git::Config.instance
    nil
  end

  # Returns the process-wide {Git::Config} singleton
  #
  # @example Read the configured binary path
  #   Git.config.binary_path  #=> "git"
  #
  # @return [Git::Config] the singleton config object
  #
  def self.config
    Git::Config.instance
  end

  # Gets or sets global git configuration options
  #
  # @overload global_config(name, value)
  #   Set the value for the git named configuration option
  #
  #   @param name [String] the name of the git configuration option
  #
  #   @param value [String, Boolean] the value to set for the git configuration option
  #
  #   @return [Git::CommandLine::Result] the result of the git configuration command
  #
  # @overload global_config(name)
  #   Get the value for the git named configuration option
  #
  #   @param name [String] the name of the git configuration option
  #
  #   @return [String] the value of the git configuration option
  #
  # @overload global_config()
  #   List all git configuration options
  #
  #   @return [Hash{String => String}] a hash of all git configuration options
  #
  # @deprecated Mixing in the `Git` module is deprecated and will be removed in v6.0.0.
  #   Use `Git.config_get(name, global: true)`, `Git.config_set(name, value, global: true)`, or
  #   `Git.config_list(global: true)` instead.
  def global_config(name = nil, value = nil)
    Git::Deprecation.warn(
      'Git#global_config is deprecated and will be removed in v6.0.0. ' \
      'Use Git.config_get(name, global: true), Git.config_set(name, value, global: true), ' \
      'or Git.config_list(global: true) instead.'
    )
    Git.__send__(:legacy_config_set_get_list, name, value, global: true)
  end

  # Returns the name of the default branch of the given repository
  #
  # @example with a URI string
  #   Git.default_branch('https://github.com/ruby-git/ruby-git') # => 'master'
  #   Git.default_branch('https://github.com/rspec/rspec-core') # => 'main'
  #
  # @example with a URI object
  #   repository_uri = URI('https://github.com/ruby-git/ruby-git')
  #   Git.default_branch(repository_uri) # => 'master'
  #
  # @example with a local repository
  #   Git.default_branch('.') # => 'master'
  #
  # @example with a local repository Pathname
  #   repository_path = Pathname('.')
  #   Git.default_branch(repository_path) # => 'master'
  #
  # @example with the logging option
  #   logger = Logger.new(STDOUT, level: Logger::INFO)
  #   Git.default_branch('.', log: logger) # => 'master'
  #   # Logs the executed git command to STDOUT, for example:
  #   #   I, [2022-04-13T16:01:33.221596 #18415]  INFO -- : git '-c' 'core.quotePath=true'
  #   #     '-c' 'color.ui=false' ls-remote '--symref' '--' '.' 'HEAD'  2>&1
  #
  # @param repository [URI, Pathname, String] The (possibly remote) repository to get the default branch name for
  #
  #   See [GIT URLS](https://git-scm.com/docs/git-clone#_git_urls_a_id_urls_a)
  #   for more information.
  #
  # @param options [Hash] The options for this command (see list of valid
  #   options below)
  #
  # @option options [Logger] :log A logger to use for Git operations.  Git
  #   commands are logged at the `:info` level.  Additional logging is done
  #   at the `:debug` level.
  #
  # @return [String] the name of the default branch
  #
  def self.default_branch(repository, options = {})
    context = Git::ExecutionContext::Global.new(logger: options[:log])
    output = Git::Commands::LsRemote.new(context).call(repository, 'HEAD', symref: true).stdout
    Git::Parsers::LsRemote.parse_default_branch(output)
  end

  # Clone a repository into `directory` then remove its `.git` directory
  #
  # Exports the current HEAD (or the specific branch given in <tt>options[:branch]</tt>)
  # into the given `directory`. It then removes all traces of git from the directory.
  #
  # Takes the same options as {Git.clone} except that `:remote` is silently ignored
  # and `:depth` defaults to 1.
  #
  # @param repository_url [String, URI, Pathname] the repository to export from
  #
  # @param directory [String, Pathname, nil] the directory to export into; defaults to the
  #   repository basename
  #
  # @param options [Hash] options forwarded to {Git.clone} (`:remote` is ignored;
  #   `:depth` defaults to 1)
  #
  # @option options [String] :branch the branch or tag to export instead of HEAD
  #
  # @return [void]
  #
  def self.export(repository_url, directory = nil, options = {})
    options.delete(:remote)
    repo = clone(repository_url, directory, { depth: 1 }.merge(options))
    repo.checkout("origin/#{options[:branch]}") if options[:branch]
    FileUtils.rm_r File.join(repo.dir.to_s, '.git')
  end

  # Get or set a git global configuration value
  #
  # @example Set a value
  #   Git.global_config('user.name', 'Scott Chacon')
  #
  # @example Get a value
  #   Git.global_config('user.name')  # => 'Scott Chacon'
  #
  # @example List all global config entries
  #   Git.global_config  # => { 'user.name' => 'Scott Chacon', ... }
  #
  # @param name [String, nil] the config key to get or set; omit to list all
  #
  # @param value [Object, nil] the value to set; omit to get or list
  #
  # @return [String, Hash, Git::CommandLine::Result] the config value, all entries,
  #   or the result of the set command
  #
  # @deprecated Use {Git.config_get}, {Git.config_set}, or {Git.config_list} instead.
  #
  #   - `Git.global_config('user.name')` → `Git.config_get('user.name', global: true)`
  #   - `Git.global_config('user.name', 'Bob')` → `Git.config_set('user.name', 'Bob', global: true)`
  #   - `Git.global_config` → `Git.config_list(global: true)`
  #
  def self.global_config(name = nil, value = nil)
    Git::Deprecation.warn(
      'Git.global_config is deprecated and will be removed in v6.0.0. ' \
      'Use Git.config_get(name, global: true), Git.config_set(name, value, global: true), ' \
      'or Git.config_list(global: true) instead.'
    )
    legacy_config_set_get_list(name, value, global: true)
  end

  # Option keys accepted by {.ls_remote}
  #
  # Parser-incompatible options such as `:get_url` and `:symref` are intentionally
  # excluded because {Git::Parsers::LsRemote.parse_output} cannot handle the
  # non-standard output formats those flags produce.
  #
  # @return [Array<Symbol>]
  #
  # @api private
  #
  LS_REMOTE_ALLOWED_OPTS = %i[
    branches b heads h tags t refs upload_pack quiet q exit_code sort server_option o timeout
  ].freeze
  private_constant :LS_REMOTE_ALLOWED_OPTS

  # Displays references available in a remote repository along with the associated commit IDs
  #
  # @example From a remote repository given its URL
  #   references = Git.ls_remote('https://github.com/user/repo.git')
  #
  # @example From the default remote of the current repository
  #   references = Git.ls_remote
  #
  # @example From a specific remote of the current repository
  #   references = Git.ls_remote('origin')
  #
  # @param repository [String, nil] the target repository location or the name of a remote
  #
  #   Defaults to `'.'` (the current directory). Passing `nil` explicitly is
  #   deprecated and will be removed in v6.0.0; pass `'.'` or omit the argument.
  #
  # @param options [Hash] the options to pass to the git command
  #
  # @option options [Boolean, nil] :branches (nil) limit output to refs under `refs/heads/`
  #
  #   Alias: `:b`
  #
  # @option options [Boolean, nil] :heads (nil) limit output to refs under `refs/heads/`
  #
  #   Deprecated: use `:branches` instead. Kept for backward compatibility with
  #   older git versions where `--heads` is the only supported flag.
  #
  #   Alias: `:h`
  #
  # @option options [Boolean, nil] :tags (nil) limit output to refs under `refs/tags/`
  #
  #   Alias: `:t`
  #
  # @option options [Boolean, nil] :refs (nil) exclude peeled tags and pseudorefs
  #   like `HEAD` from the output
  #
  # @option options [String] :upload_pack (nil) full path to `git-upload-pack` on the
  #   remote host
  #
  #   Useful when accessing repositories via SSH where the daemon does not use the
  #   PATH configured by the user.
  #
  # @option options [Boolean, nil] :quiet (nil) do not print the remote URL to stderr
  #
  #   Alias: `:q`
  #
  # @option options [Boolean, nil] :exit_code (nil) exit with status `2` when no
  #   matching refs are found in the remote repository
  #
  #   Without this option, the command exits `0` whenever it successfully
  #   communicates with the remote, even if no refs match.
  #
  # @option options [String] :sort (nil) sort output by the given key
  #
  #   Prefix `-` for descending order. Supports `"version:refname"` or `"v:refname"`.
  #   See `git for-each-ref` for sort key documentation.
  #
  # @option options [String, Array<String>] :server_option (nil) transmit a string to
  #   the server when communicating using protocol version 2
  #
  #   The string must not contain NUL or LF characters. Repeatable by passing an
  #   Array. Alias: `:o`
  #
  # @option options [Numeric] :timeout (nil) execution timeout in seconds
  #
  # @option options [Logger] :log (nil) a logger to use for Git operations
  #
  #   Git commands are logged at the `:info` level. Additional logging is done at
  #   the `:debug` level.
  #
  # @return [Hash{String => Hash}] the available references of the target repo
  #
  def self.ls_remote(repository = '.', options = {})
    repository = normalize_ls_remote_repository(repository)
    options = options.dup
    log = options.delete(:log)
    unknown = options.keys - LS_REMOTE_ALLOWED_OPTS
    raise ArgumentError, "Unknown options: #{unknown.join(', ')}" unless unknown.empty?

    context = Git::ExecutionContext::Global.new(logger: log)
    output_lines = Git::Commands::LsRemote.new(context).call(repository, **options).stdout.split("\n")
    Git::Parsers::LsRemote.parse_output(output_lines)
  end

  # Normalize the repository argument for {.ls_remote}
  #
  # Returns the repository unchanged unless it is nil, in which case a
  # deprecation warning is emitted and `'.'` is returned.
  #
  # @param repository [String, nil] the repository argument passed by the caller
  #
  # @return [String] the normalized repository value (`'.'` when nil was given)
  #
  # @api private
  #
  def self.normalize_ls_remote_repository(repository)
    return repository unless repository.nil?

    Git::Deprecation.warn(
      'Passing nil as the repository to Git.ls_remote is deprecated and will ' \
      "be removed in v6.0.0. Pass '.' explicitly or omit the argument instead."
    )

    '.'
  end
  private_class_method :normalize_ls_remote_repository

  # Thread-safe cache for git versions, keyed by binary path.
  @git_version_cache_mutex = Mutex.new
  @git_version_cache = {}

  # Return the cached git version for the given binary path
  #
  # If it isn't already known, compute it using the given block.
  #
  # @param binary_path [String] the path to the git binary
  #
  # @return [Git::Version] the git version
  #
  # @yield [] compute the git version if it is not cached
  #
  # @yieldreturn [Git::Version] the computed git version
  #
  # @api private
  def self.cached_git_version(binary_path, &block)
    @git_version_cache_mutex.synchronize do
      @git_version_cache[binary_path] ||= block.call
    end
  end

  # Clear the cached git version for all binary paths
  #
  # @return [void]
  #
  # @api private
  def self.clear_git_version_cache
    @git_version_cache_mutex.synchronize do
      @git_version_cache.clear
    end
  end

  # Return the version of a git binary as a {Git::Version}
  #
  # @example Default binary
  #   Git.git_version #=> #<Git::Version 2.42.0>
  #
  # @example Explicit binary path
  #   Git.git_version('/opt/homebrew/bin/git') #=> #<Git::Version 2.42.0>
  #
  # @param binary_path [String, nil] path to the git binary; defaults to
  #   `Git::Config.instance.binary_path`
  #
  # @return [Git::Version] the parsed git version
  #
  # @raise [Git::UnexpectedResultError] if the version output cannot be parsed
  #
  # @raise [Git::FailedError] if the git binary exits with a non-zero status
  #
  # @raise [Git::Error] if the binary is not found or fails to launch
  #
  def self.git_version(binary_path = nil)
    path = binary_path || Git::Config.instance.binary_path
    cached_git_version(path) { run_git_version(path) }
  end

  # Return the version of the git binary
  #
  # @param path [String] the path to the git binary
  #
  # @return [Git::Version] the parsed git version
  #
  # @raise [Git::UnexpectedResultError] if the version output cannot be parsed
  #
  # @raise [Git::FailedError] if the git binary exits with a non-zero status
  #
  # @raise [Git::Error] if the binary is not found or fails to launch
  #
  # @api private
  #
  def self.run_git_version(path)
    output = Git::Commands::Version.new(Git::ExecutionContext::Global.new(binary_path: path)).call.stdout
    Git::Version.parse(output)
  end
  private_class_method :run_git_version

  # Get or set a git config value
  #
  # @overload legacy_config_set_get_list(name, value, global:)
  #
  #   Set the value of a git configuration option
  #
  #   @param name [String] the name of the git configuration value to set
  #
  #   @param value [String, Boolean] the value to set
  #
  #   @param global [Boolean] true to use the global git configuration, false for the
  #     local repo config
  #
  #   @return [Git::CommandLine::Result] the result of the git config command
  #
  # @overload legacy_config_set_get_list(name, global:)
  #
  #   Get the value of a git configuration option
  #
  #   @param name [String] the name of the git configuration value to get
  #
  #   @param global [Boolean] true to use the global git configuration, false for the
  #     local repo config
  #
  #   @return [String] the value of the git configuration option
  #
  # @overload legacy_config_set_get_list(global:)
  #
  #   Get all git configuration options
  #
  #   @param global [Boolean] true to use the global git configuration, false for the
  #     local repo config
  #
  #   @return [Hash{String => String}] all git configuration options
  #
  # @raise [Git::FailedError] if the git config command fails
  #
  # @api private
  #
  def self.legacy_config_set_get_list(name, value, global:)
    if !name.nil? && !value.nil?
      legacy_config_set(name, value, global:)
    elsif !name.nil?
      legacy_config_get(name, global:)
    else
      legacy_config_list(global:)
    end
  end
  private_class_method :legacy_config_set_get_list

  # Set the value of a git configuration option
  #
  # @param name [String] the name of the git configuration value to set
  #
  # @param value [String, Boolean] the value to set
  #
  # @param global [Boolean] whether to use the global git configuration
  #
  # @api private
  #
  def self.legacy_config_set(name, value, global:)
    options = global ? { global: true } : {}
    Git::Commands::ConfigOptionSyntax::Set.new(execution_context).call(name, value, **options)
  end
  private_class_method :legacy_config_set

  # Get the value of a git configuration option
  #
  # @param name [String] the name of the git configuration option
  #
  # @param global [Boolean] whether to use the global git configuration
  #
  # @return [String] the value of the git configuration option
  #
  # @api private
  #
  def self.legacy_config_get(name, global:)
    options = global ? { global: true } : {}
    result = Git::Commands::ConfigOptionSyntax::Get.new(execution_context).call(name, **options)
    raise Git::FailedError, result if result.status.exitstatus != 0

    result.stdout
  end
  private_class_method :legacy_config_get

  # Get a list of all git configuration options
  #
  # @param global [Boolean] true to use the global git configuration, false for the
  #     local repo config
  #
  # @return [Hash{String => String}] all git configuration options
  #
  # @api private
  #
  def self.legacy_config_list(global:)
    options = global ? { global: true } : {}
    output = Git::Commands::ConfigOptionSyntax::List.new(execution_context).call(**options).stdout
    parse_config_list(output.split("\n"))
  end
  private_class_method :legacy_config_list

  # Parse the output of `git config --list` into a hash
  #
  # @param lines [Array<String>] the lines of output from `git config --list`
  #
  # @return [Hash{String => String}] the parsed git configuration options
  #
  # @api private
  #
  def self.parse_config_list(lines)
    lines.each_with_object({}) do |line, hsh|
      key, value = line.split('=', 2)
      hsh[key] = value || ''
    end
  end
  private_class_method :parse_config_list

  # @api private
  def self.execution_context
    Git::ExecutionContext::Global.new
  end
  private_class_method :execution_context

  # Scopes that require an active repository and cannot be used at the Git module level
  #
  # @api private
  #
  REPOSITORY_SPECIFIC_SCOPES = %i[local worktree blob].freeze
  private_constant :REPOSITORY_SPECIFIC_SCOPES

  # Raises +ArgumentError+ when a repository-specific scope is requested.
  #
  # The +:local+, +:worktree+, and +:blob+ scopes require an active git
  # repository and are therefore not valid at the Git module level.
  #
  # @param options_to_check [Hash{Symbol => Object}] the scope options to check
  #
  #   If any of the options listed in +REPOSITORY_SPECIFIC_SCOPES+ are present and
  #   truthy, an +ArgumentError+ will be raised.
  #
  # @option options_to_check [Object] :local truthy value requests local scope
  #
  # @option options_to_check [Object] :worktree truthy value requests worktree scope
  #
  # @option options_to_check [Object] :blob truthy value requests blob scope
  #
  # @raise [ArgumentError] if a repository-specific scope is requested
  #
  # @api private
  #
  def self.assert_valid_scope!(**options_to_check)
    invalid = REPOSITORY_SPECIFIC_SCOPES.select { |s| options_to_check[s] }
    return if invalid.empty?

    raise ArgumentError, "#{invalid.join(', ')} scope requires a repository"
  end
  private_class_method :assert_valid_scope!

  # Return the version of the git binary
  #
  # @example Basic usage
  #   Git.binary_version  # => [2, 46, 0]
  #
  # @param binary_path [String, nil] path to the git binary; defaults to
  #   `Git::Config.instance.binary_path`
  #
  # @return [Array<Integer>] the version of the git binary
  #
  # @deprecated Use {Git.git_version} instead, which returns a
  #   {Git::Version} (not an Array)
  #
  #   For the legacy array shape, call: `Git.git_version.to_a`.
  #   The optional binary_path argument is preserved:
  #   `Git.git_version(binary_path)`.
  #
  def self.binary_version(binary_path = nil)
    binary_path ||= Git::Config.instance.binary_path
    Git::Deprecation.warn(
      'Git.binary_version is deprecated and will be removed in 6.0. ' \
      'Use Git.git_version instead, which returns a Git::Version ' \
      '(not an Array). For the legacy array shape, call: Git.git_version.to_a. ' \
      'The optional binary_path argument is preserved: Git.git_version(binary_path).'
    )
    git_version(binary_path).to_a
  end
end
