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

  # @deprecated Mixing in the `Git` module is deprecated and will be removed in v6.0.0.
  #   Use `Git.config_get(name)`, `Git.config_set(name, value)`, or `Git.config_list` instead.
  def config(name = nil, value = nil)
    Git::Deprecation.warn(
      'Git#config is deprecated and will be removed in v6.0.0. ' \
      'Use Git.config_get(name), Git.config_set(name, value), or Git.config_list instead.'
    )
    Git.__send__(:run_config_utility, name, value, global: false)
  end

  # Configures the gem by yielding {Git::Config.instance} to the block
  #
  # @example Set the global git binary path
  #   Git.configure { |c| c.binary_path = '/usr/local/bin/git' }
  #
  # @yield [config] yields the singleton config object
  #
  # @yieldparam config [Git::Config] the singleton config object
  #
  # @yieldreturn [void]
  #
  # @return [void]
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

  # @deprecated Mixing in the `Git` module is deprecated and will be removed in v6.0.0.
  #   Use `Git.config_get(name, global: true)`, `Git.config_set(name, value, global: true)`, or
  #   `Git.config_list(global: true)` instead.
  def global_config(name = nil, value = nil)
    Git::Deprecation.warn(
      'Git#global_config is deprecated and will be removed in v6.0.0. ' \
      'Use Git.config_get(name, global: true), Git.config_set(name, value, global: true), ' \
      'or Git.config_list(global: true) instead.'
    )
    Git.global_config(name, value)
  end

  # Open a bare repository
  #
  # Opens a bare repository located in the `git_dir` directory.
  # Since there is no working copy, you can not checkout or commit
  # but you can do most read operations.
  #
  # @see https://git-scm.com/docs/gitglossary#Documentation/gitglossary.txt-aiddefbarerepositoryabarerepository
  #   What is a bare repository?
  #
  # @example Open a bare repository and retrieve the first commit SHA
  #   repository = Git.bare('ruby-git.git')
  #   puts repository.log[0].sha #=> "64c6fa011d3287bab9158049c85f3e85718854a0"
  #
  # @param git_dir [Pathname] The path to the bare repository directory
  #   containing an initialized Git repository. If a relative path is given, it
  #   is converted to an absolute path using
  #   [File.expand_path](https://www.rubydoc.info/stdlib/core/File.expand_path).
  #
  # @param options [Hash] The options for this command (see list of valid
  #   options below)
  #
  # @option options [String, nil] :git_ssh An optional custom SSH command
  #
  #   - If not specified, uses the global config (Git.configure { |c| c.git_ssh = ... }).
  #   - If nil, disables SSH for this instance.
  #   - If a non-empty string, uses that value for this instance.
  #
  # @option options [Logger] :log A logger to use for Git operations.  Git commands
  #   are logged at the `:info` level.  Additional logging is done at the `:debug`
  #   level.
  #
  # @return [Git::Repository] an object that can execute git commands in the context
  #   of the bare repository.
  #
  def self.bare(git_dir, options = {})
    Git::Repository.bare(git_dir, options)
  end

  # Clone a repository into an empty or newly created directory
  #
  # @see https://git-scm.com/docs/git-clone git clone
  #
  # @see https://git-scm.com/docs/git-clone#_git_urls_a_id_urls_a GIT URLs
  #
  # @param repository_url [URI, Pathname] The (possibly remote) repository url to clone
  #   from. See [GIT URLS](https://git-scm.com/docs/git-clone#_git_urls_a_id_urls_a)
  #   for more information.
  #
  # @param directory [Pathname, nil] The directory to clone into
  #
  #   If `directory` is a relative path it is relative to the `:chdir` option if
  #   given. If `:chdir` is not given, `directory` is relative to the current
  #   working directory.
  #
  #   If `nil`, `directory` will be set to the basename of the last component of
  #   the path from the `repository_url`. For example, for the URL:
  #   `https://github.com/org/repo.git`, `directory` will be set to `repo`.
  #
  #   If the last component of the path is `.git`, the next-to-last component of
  #   the path is used. For example, for the URL `/Users/me/foo/.git`, `directory`
  #   will be set to `foo`.
  #
  # @param [Hash] options The options for this command (see list of valid
  #   options below)
  #
  # @option options [Boolean] :bare Make a bare Git repository. See
  #   [what is a bare repository?](https://git-scm.com/docs/gitglossary#Documentation/gitglossary.txt-aiddefbarerepositoryabarerepository).
  #
  # @option options [String] :branch The name of a branch or tag to checkout
  #   instead of the default branch.
  #
  # @option options [Array, String] :config A list of configuration options to
  #  set on the newly created repository.
  #
  # @option options [Integer] :depth Create a shallow clone with a history
  #   truncated to the specified number of commits.
  #
  # @option options [String] :filter Request that the server send a partial
  #   clone according to the given filter
  #
  # @option options [Boolean, nil] :single_branch Control whether the clone
  #   limits fetch refspecs to a single branch.
  #   - If nil (default), no flag is passed and the Git default is used.
  #   - If true, `--single-branch` is passed to limit the refspec to the
  #     checkout branch.
  #   - If false, `--no-single-branch` is passed to broaden the refspec (useful
  #     for shallow clones that should include all branches).
  #
  # @option options [String, nil] :git_ssh An optional custom SSH command
  #
  #   - If not specified, uses the global config (Git.configure { |c| c.git_ssh = ... }).
  #   - If nil, disables SSH for this instance.
  #   - If a non-empty string, uses that value for this instance.
  #
  # @option options [Logger] :log A logger to use for Git operations.  Git
  #   commands are logged at the `:info` level.  Additional logging is done
  #   at the `:debug` level.
  #
  # @option options [Boolean] :mirror Set up a mirror of the source repository.
  #
  # @option options [String] :origin Use the value instead `origin` to track
  #   the upstream repository.
  #
  # @option options [Pathname] :chdir Run `git clone` from within this directory.
  #
  #   The `directory` parameter (or the repository basename when `directory` is nil)
  #   is resolved relative to `:chdir`, just as if you had `cd`'d into it before
  #   running `git clone`. The returned path is the join of `:chdir` and the
  #   cloned directory path.
  #
  # @option options [Pathname] :path Deprecated — use `:chdir` instead.
  #
  # @option options [Boolean] :recursive After the clone is created, initialize
  #   all submodules within, using their default settings.
  #
  # @example Clone into the default directory `ruby-git`
  #   git = Git.clone('https://github.com/ruby-git/ruby-git.git')
  #
  # @example Clone and then checkout the `development` branch
  #   git = Git.clone('https://github.com/ruby-git/ruby-git.git', branch: 'development')
  #
  # @example Clone into a different directory `my-ruby-git`
  #   git = Git.clone('https://github.com/ruby-git/ruby-git.git', 'my-ruby-git')
  #
  # @example Clone into a specific parent directory
  #   git = Git.clone('https://github.com/ruby-git/ruby-git.git', chdir: '/path/to/projects')
  #   # clones into /path/to/projects/ruby-git
  #
  # @example Create a bare repository in the directory `ruby-git.git`
  #   git = Git.clone('https://github.com/ruby-git/ruby-git.git', bare: true)
  #
  # @example Clone a repository and set a single config option
  #   git = Git.clone(
  #     'https://github.com/ruby-git/ruby-git.git',
  #     config: 'submodule.recurse=true'
  #   )
  #
  # @example Clone a repository and set multiple config options
  #   git = Git.clone(
  #     'https://github.com/ruby-git/ruby-git.git',
  #     config: ['user.name=John Doe', 'user.email=john@doe.com']
  #   )
  #
  # @example Clone using a specific SSH key
  #   git = Git.clone(
  #     'git@github.com:ruby-git/ruby-git.git',
  #     'local-dir',
  #     git_ssh: 'ssh -i /path/to/private_key'
  #   )
  #
  # @return [Git::Repository] an object that can execute git commands in the context
  #   of the cloned local working copy or cloned repository.
  #
  def self.clone(repository_url, directory = nil, options = {})
    Git::Repository.clone(repository_url, directory, options)
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

  # Export the current HEAD (or a branch, if <tt>options[:branch]</tt>
  # is specified) into the +name+ directory, then remove all traces of git from the
  # directory.
  #
  # See +clone+ for options.  Does not obey the <tt>:remote</tt> option,
  # since the .git info will be deleted anyway; always uses the default
  # remote, 'origin.'
  def self.export(repository, name, options = {})
    options.delete(:remote)
    repo = clone(repository, name, { depth: 1 }.merge(options))
    repo.checkout("origin/#{options[:branch]}") if options[:branch]
    FileUtils.rm_r File.join(repo.dir.to_s, '.git')
  end

  # Same as g.config, but forces it to be at the global level
  #
  # g.config('user.name', 'Scott Chacon') # sets value
  # g.config('user.email', 'email@email.com')  # sets value
  # g.config('user.name')  # returns 'Scott Chacon'
  # g.config # returns whole config hash
  def self.global_config(name = nil, value = nil)
    run_config_utility(name, value, global: true)
  end

  # Create an empty Git repository or reinitialize an existing Git repository
  #
  # @param [Pathname] directory If the `:bare` option is NOT given or is not
  #   `true`, the repository will be created in `"#{directory}/.git"`.
  #   Otherwise, the repository is created in `"#{directory}"`.
  #
  #   All directories along the path to `directory` are created if they do not exist.
  #
  #   A relative path is referenced from the current working directory of the process
  #   and converted to an absolute path using
  #   [File.expand_path](https://www.rubydoc.info/stdlib/core/File.expand_path).
  #
  # @param [Hash] options The options for this command (see list of valid
  #   options below)
  #
  # @option options [Boolean] :bare Instead of creating a repository at
  #   `"#{directory}/.git"`, create a bare repository at `"#{directory}"`.
  #   See [what is a bare repository?](https://git-scm.com/docs/gitglossary#Documentation/gitglossary.txt-aiddefbarerepositoryabarerepository).
  #
  # @option options [String] :initial_branch Use the specified name for the
  #   initial branch in the newly created repository.
  #
  # @option options [Pathname] :repository the path to put the newly initialized
  #   Git repository. The default for non-bare repository is `"#{directory}/.git"`.
  #
  #   A relative path is referenced from the current working directory of the process
  #   and converted to an absolute path using
  #   [File.expand_path](https://www.rubydoc.info/stdlib/core/File.expand_path).
  #
  # @option options [Pathname] :separate_git_dir Alias for `:repository`.
  #
  # @option options [String, nil] :git_ssh An optional custom SSH command
  #
  #   - If not specified, uses the global config (Git.configure { |c| c.git_ssh = ... }).
  #   - If nil, disables SSH for this instance.
  #   - If a non-empty string, uses that value for this instance.
  #
  # @option options [String, :use_global_config] :binary_path path to the git
  #   binary; defaults to `Git::Config.instance.binary_path` when not specified.
  #   Raises `ArgumentError` if set to `nil`.
  #
  # @option options [Logger] :log A logger to use for Git operations.  Git
  #   commands are logged at the `:info` level.  Additional logging is done
  #   at the `:debug` level.
  #
  # @return [Git::Repository] an object that can execute git commands in the context
  #   of the newly initialized repository
  #
  # @example Initialize a repository in the current directory
  #   git = Git.init
  #
  # @example Initialize a repository in some other directory
  #   git = Git.init '~/code/ruby-git'
  #
  # @example Initialize a bare repository
  #   git = Git.init '~/code/ruby-git.git', bare: true
  #
  # @example Initialize a repository in a non-default location (outside of the working copy)
  #   git = Git.init '~/code/ruby-git', repository: '~/code/ruby-git.git'
  #
  # @see https://git-scm.com/docs/git-init git init
  #
  def self.init(directory = '.', options = {})
    Git::Repository.init(directory, options)
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

  # returns a Hash containing information about the references
  # of the target repository
  #
  # options
  #   :refs
  #
  # @param location [String, nil] the target repository location or nil for '.'
  #
  # @return [Hash{String => Hash}] the available references of the target repo
  def self.ls_remote(location = nil, options = {})
    options = options.dup
    log = options.delete(:log)
    unknown = options.keys - LS_REMOTE_ALLOWED_OPTS
    raise ArgumentError, "Unknown options: #{unknown.join(', ')}" unless unknown.empty?

    context = Git::ExecutionContext::Global.new(logger: log)
    repository = location || '.'
    output_lines = Git::Commands::LsRemote.new(context).call(repository, **options).stdout.split("\n")
    Git::Parsers::LsRemote.parse_output(output_lines)
  end

  # Open a an existing Git working directory
  #
  # Git.open will most likely be the most common way to create
  # a git reference, referring to an existing working directory.
  #
  # If not provided in the options, the library will assume
  # the repository and index are in the default places (`.git/`, `.git/index`).
  #
  # @example Open the Git working directory in the current directory
  #   git = Git.open
  #
  # @example Open a Git working directory in some other directory
  #   git = Git.open('~/Projects/ruby-git')
  #
  # @example Use a logger to see what is going on
  #   logger = Logger.new(STDOUT)
  #   git = Git.open('~/Projects/ruby-git', log: logger)
  #
  # @example Open a working copy whose repository is in a non-standard directory
  #   git = Git.open('~/Projects/ruby-git', repository: '~/Project/ruby-git.git')
  #
  # @param working_dir [Pathname] the path to the working directory to use
  #   for git commands.
  #
  #   A relative path is referenced from the current working directory of the process
  #   and converted to an absolute path using
  #   [File.expand_path](https://www.rubydoc.info/stdlib/core/File.expand_path).
  #
  # @param options [Hash] The options for this command (see list of valid
  #   options below)
  #
  # @option options [Pathname] :repository used to specify a non-standard path to
  #   the repository directory.  The default is `"#{working_dir}/.git"`.
  #
  # @option options [Pathname] :index used to specify a non-standard path to an
  #   index file.  The default is `"#{working_dir}/.git/index"`
  #
  # @option options [String, nil] :git_ssh An optional custom SSH command
  #
  #   - If not specified, uses the global config (Git.configure { |c| c.git_ssh = ... }).
  #   - If nil, disables SSH for this instance.
  #   - If a non-empty string, uses that value for this instance.
  #
  # @option options [Logger] :log A logger to use for Git operations.  Git
  #   commands are logged at the `:info` level.  Additional logging is done
  #   at the `:debug` level.
  #
  # @return [Git::Repository] an object that can execute git commands in the context
  #   of the opened working copy
  #
  def self.open(working_dir, options = {})
    Git::Repository.open(working_dir, options)
  end

  # Thread-safe cache for git versions, keyed by binary path.
  @git_version_cache_mutex = Mutex.new
  @git_version_cache = {}

  # @api private
  def self.cached_git_version(binary_path, &block)
    @git_version_cache_mutex.synchronize do
      @git_version_cache[binary_path] ||= block.call
    end
  end

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

  # @api private
  def self.run_git_version(path)
    output = Git::Commands::Version.new(Git::ExecutionContext::Global.new(binary_path: path)).call.stdout
    Git::Version.parse(output)
  end
  private_class_method :run_git_version

  # @api private
  def self.run_config_utility(name, value, global:)
    context = Git::ExecutionContext::Global.new
    options = global ? { global: true } : {}

    return Git::Commands::ConfigOptionSyntax::Set.new(context).call(name, value, **options) if !name.nil? && !value.nil?
    return run_config_get(context, name, options) if name

    output = Git::Commands::ConfigOptionSyntax::List.new(context).call(**options).stdout
    parse_config_list(output.split("\n"))
  end
  private_class_method :run_config_utility

  def self.run_config_get(context, name, options)
    result = Git::Commands::ConfigOptionSyntax::Get.new(context).call(name, **options)
    raise Git::FailedError, result if result.status.exitstatus != 0

    result.stdout
  end
  private_class_method :run_config_get

  # @api private
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
  # @api private
  #
  def self.assert_valid_scope!(**opts)
    invalid = REPOSITORY_SPECIFIC_SCOPES.select { |s| opts[s] }
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
