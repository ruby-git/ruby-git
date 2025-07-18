# frozen_string_literal: true

require 'active_support'
require 'active_support/deprecation'

module Git
  Deprecation = ActiveSupport::Deprecation.new('5.0.0', 'Git')
end

require 'git/author'
require 'git/base'
require 'git/branch'
require 'git/branches'
require 'git/command_line_result'
require 'git/command_line'
require 'git/config'
require 'git/diff'
require 'git/encoding_utils'
require 'git/errors'
require 'git/escaped_path'
require 'git/index'
require 'git/lib'
require 'git/log'
require 'git/object'
require 'git/path'
require 'git/remote'
require 'git/repository'
require 'git/status'
require 'git/stash'
require 'git/stashes'
require 'git/url'
require 'git/version'
require 'git/working_directory'
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
  # g.config('user.name', 'Scott Chacon') # sets value
  # g.config('user.email', 'email@email.com')  # sets value
  # g.config('user.name')  # returns 'Scott Chacon'
  # g.config # returns whole config hash
  def config(name = nil, value = nil)
    lib = Git::Lib.new
    if name && value
      # set value
      lib.config_set(name, value)
    elsif name
      # return value
      lib.config_get(name)
    else
      # return hash
      lib.config_list
    end
  end

  def self.configure
    yield Base.config
  end

  def self.config
    Base.config
  end

  def global_config(name = nil, value = nil)
    self.class.global_config(name, value)
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
  # @param [Pathname] git_dir The path to the bare repository directory
  #   containing an initialized Git repository. If a relative path is given, it
  #   is converted to an absolute path using
  #   [File.expand_path](https://www.rubydoc.info/stdlib/core/File.expand_path).
  #
  # @param [Hash] options The options for this command (see list of valid
  #   options below)
  #
  # @option options [Logger] :log A logger to use for Git operations.  Git commands
  #   are logged at the `:info` level.  Additional logging is done at the `:debug`
  #   level.
  #
  # @return [Git::Base] an object that can execute git commands in the context
  #   of the bare repository.
  #
  def self.bare(git_dir, options = {})
    Base.bare(git_dir, options)
  end

  # Clone a repository into an empty or newly created directory
  #
  # @see https://git-scm.com/docs/git-clone git clone
  # @see https://git-scm.com/docs/git-clone#_git_urls_a_id_urls_a GIT URLs
  #
  # @param repository_url [URI, Pathname] The (possibly remote) repository url to clone
  #   from. See [GIT URLS](https://git-scm.com/docs/git-clone#_git_urls_a_id_urls_a)
  #   for more information.
  #
  # @param directory [Pathname, nil] The directory to clone into
  #
  #   If `directory` is a relative directory it is relative to the `path` option if
  #   given. If `path` is not given, `directory` is relative to the current working
  #   directory.
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
  # @option options [Logger] :log A logger to use for Git operations.  Git
  #   commands are logged at the `:info` level.  Additional logging is done
  #   at the `:debug` level.
  #
  # @option options [Boolean] :mirror Set up a mirror of the source repository.
  #
  # @option options [String] :origin Use the value instead `origin` to track
  #   the upstream repository.
  #
  # @option options [Pathname] :path The directory to clone into.  May be used
  #   as an alternative to the `directory` parameter.  If specified, the
  #   `path` option is used instead of the `directory` parameter.
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
  #   # or:
  #   git = Git.clone('https://github.com/ruby-git/ruby-git.git', path: 'my-ruby-git')
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
  # @return [Git::Base] an object that can execute git commands in the context
  #   of the cloned local working copy or cloned repository.
  #
  def self.clone(repository_url, directory = nil, options = {})
    clone_to_options = options.slice(:bare, :mirror)
    directory ||= Git::URL.clone_to(repository_url, **clone_to_options)
    Base.clone(repository_url, directory, options)
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
  #   I, [2022-04-13T16:01:33.221596 #18415]  INFO -- : git '-c' 'core.quotePath=true'
  #     '-c' 'color.ui=false' ls-remote '--symref' '--' '.' 'HEAD'  2>&1
  #
  # @param repository [URI, Pathname, String] The (possibly remote) repository to get the default branch name for
  #
  #   See [GIT URLS](https://git-scm.com/docs/git-clone#_git_urls_a_id_urls_a)
  #   for more information.
  #
  # @param [Hash] options The options for this command (see list of valid
  #   options below)
  #
  # @option options [Logger] :log A logger to use for Git operations.  Git
  #   commands are logged at the `:info` level.  Additional logging is done
  #   at the `:debug` level.
  #
  # @return [String] the name of the default branch
  #
  def self.default_branch(repository, options = {})
    Base.repository_default_branch(repository, options)
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
    lib = Git::Lib.new(nil, nil)
    if name && value
      # set value
      lib.global_config_set(name, value)
    elsif name
      # return value
      lib.global_config_get(name)
    else
      # return hash
      lib.global_config_list
    end
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
  # @option options [Logger] :log A logger to use for Git operations.  Git
  #   commands are logged at the `:info` level.  Additional logging is done
  #   at the `:debug` level.
  #
  # @return [Git::Base] an object that can execute git commands in the context
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
    Base.init(directory, options)
  end

  # returns a Hash containing information about the references
  # of the target repository
  #
  # options
  #   :refs
  #
  # @param [String|NilClass] location the target repository location or nil for '.'
  # @return [{String=>Hash}] the available references of the target repo.
  def self.ls_remote(location = nil, options = {})
    Git::Lib.new.ls_remote(location, options)
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
  # @param [Pathname] working_dir the path to the working directory to use
  #   for git commands.
  #
  #   A relative path is referenced from the current working directory of the process
  #   and converted to an absolute path using
  #   [File.expand_path](https://www.rubydoc.info/stdlib/core/File.expand_path).
  #
  # @param [Hash] options The options for this command (see list of valid
  #   options below)
  #
  # @option options [Pathname] :repository used to specify a non-standard path to
  #   the repository directory.  The default is `"#{working_dir}/.git"`.
  #
  # @option options [Pathname] :index used to specify a non-standard path to an
  #   index file.  The default is `"#{working_dir}/.git/index"`
  #
  # @option options [Logger] :log A logger to use for Git operations.  Git
  #   commands are logged at the `:info` level.  Additional logging is done
  #   at the `:debug` level.
  #
  # @return [Git::Base] an object that can execute git commands in the context
  #   of the opened working copy
  #
  def self.open(working_dir, options = {})
    Base.open(working_dir, options)
  end

  # Return the version of the git binary
  #
  # @example
  #  Git.binary_version # => [2, 46, 0]
  #
  # @return [Array<Integer>] the version of the git binary
  #
  def self.binary_version(binary_path = Git::Base.config.binary_path)
    Base.binary_version(binary_path)
  end
end
