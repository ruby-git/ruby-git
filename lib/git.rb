# Add the directory containing this file to the start of the load path if it
# isn't there already.
$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'git/author'
require 'git/base'
require 'git/branch'
require 'git/branches'
require 'git/config'
require 'git/diff'
require 'git/encoding_utils'
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
require 'git/version'
require 'git/working_directory'
require 'git/worktree'
require 'git/worktrees'

lib = Git::Lib.new(nil, nil)
unless lib.meets_required_version?
  $stderr.puts "[WARNING] The git gem requires git #{lib.required_command_version.join('.')} or later, but only found #{lib.current_command_version.join('.')}. You should probably upgrade."
end

# The Git module provides the basic functions to open a git
# reference to work with. You can open a working directory,
# open a bare repository, initialize a new repo or clone an
# existing remote repository.
#
# @author Scott Chacon (mailto:schacon@gmail.com)
#
module Git
  #g.config('user.name', 'Scott Chacon') # sets value
  #g.config('user.email', 'email@email.com')  # sets value
  #g.config('user.name')  # returns 'Scott Chacon'
  #g.config # returns whole config hash
  def config(name = nil, value = nil)
    lib = Git::Lib.new
    if(name && value)
      # set value
      lib.config_set(name, value)
    elsif (name)
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
    return Base.config
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
  # @param [URI, Pathname] repository The (possibly remote) repository to clone
  #   from. See [GIT URLS](https://git-scm.com/docs/git-clone#_git_urls_a_id_urls_a)
  #   for more information.
  #
  # @param [Pathname] name The directory to clone into.
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
  # @option options [Integer] :depth Create a shallow clone with a history
  #   truncated to the specified number of commits.
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
  # @return [Git::Base] an object that can execute git commands in the context
  #   of the cloned local working copy or cloned repository.
  #
  def self.clone(repository, name, options = {})
    Base.clone(repository, name, options)
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
    repo = clone(repository, name, {:depth => 1}.merge(options))
    repo.checkout("origin/#{options[:branch]}") if options[:branch]
    Dir.chdir(repo.dir.to_s) { FileUtils.rm_r '.git' }
  end

  # Same as g.config, but forces it to be at the global level
  #
  #g.config('user.name', 'Scott Chacon') # sets value
  #g.config('user.email', 'email@email.com')  # sets value
  #g.config('user.name')  # returns 'Scott Chacon'
  #g.config # returns whole config hash
  def self.global_config(name = nil, value = nil)
    lib = Git::Lib.new(nil, nil)
    if(name && value)
      # set value
      lib.global_config_set(name, value)
    elsif (name)
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
end
