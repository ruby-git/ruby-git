# frozen_string_literal: true

require 'logger'
require 'open3'

module Git
  # The main public interface for interacting with Git commands
  #
  # Instead of creating a Git::Base directly, obtain a Git::Base instance by
  # calling one of the follow {Git} class methods: {Git.open}, {Git.init},
  # {Git.clone}, or {Git.bare}.
  #
  # @api public
  #
  class Base
    # (see Git.bare)
    def self.bare(git_dir, options = {})
      normalize_paths(options, default_repository: git_dir, bare: true)
      self.new(options)
    end

    # (see Git.clone)
    def self.clone(repository_url, directory, options = {})
      new_options = Git::Lib.new(nil, options[:log]).clone(repository_url, directory, options)
      normalize_paths(new_options, bare: options[:bare] || options[:mirror])
      new(new_options)
    end

    # (see Git.default_branch)
    def self.repository_default_branch(repository, options = {})
      Git::Lib.new(nil, options[:log]).repository_default_branch(repository)
    end

    # Returns (and initialize if needed) a Git::Config instance
    #
    # @return [Git::Config] the current config instance.
    def self.config
      @@config ||= Config.new
    end

    def self.binary_version(binary_path)
      result = nil
      status = nil

      begin
        result, status = Open3.capture2e(binary_path, "-c", "core.quotePath=true", "-c", "color.ui=false", "version")
        result = result.chomp
      rescue Errno::ENOENT
        raise RuntimeError, "Failed to get git version: #{binary_path} not found"
      end

      if status.success?
        version = result[/\d+(\.\d+)+/]
        version_parts = version.split('.').collect { |i| i.to_i }
        version_parts.fill(0, version_parts.length...3)
      else
        raise RuntimeError, "Failed to get git version: #{status}\n#{result}"
      end
    end

    # (see Git.init)
    def self.init(directory = '.', options = {})
      normalize_paths(options, default_working_directory: directory, default_repository: directory, bare: options[:bare])

      init_options = {
        :bare => options[:bare],
        :initial_branch => options[:initial_branch]
      }

      directory = options[:bare] ? options[:repository] : options[:working_directory]
      FileUtils.mkdir_p(directory) unless File.exist?(directory)

      # TODO: this dance seems awkward: this creates a Git::Lib so we can call
      #   init so we can create a new Git::Base which in turn (ultimately)
      #   creates another/different Git::Lib.
      #
      # TODO: maybe refactor so this Git::Bare.init does this:
      #   self.new(opts).init(init_opts) and move all/some of this code into
      #   Git::Bare#init. This way the init method can be called on any
      #   repository you have a Git::Base instance for.  This would not
      #   change the existing interface (other than adding to it).
      #
      Git::Lib.new(options).init(init_options)

      self.new(options)
    end

    def self.root_of_worktree(working_dir)
      result = working_dir
      status = nil

      raise ArgumentError, "'#{working_dir}' does not exist" unless Dir.exist?(working_dir)

      begin
        result, status = Open3.capture2e(Git::Base.config.binary_path, "-c", "core.quotePath=true", "-c", "color.ui=false", "rev-parse", "--show-toplevel", chdir: File.expand_path(working_dir))
        result = result.chomp
      rescue Errno::ENOENT
        raise ArgumentError, "Failed to find the root of the worktree: git binary not found"
      end

      raise ArgumentError, "'#{working_dir}' is not in a git working tree" unless status.success?
      result
    end

    # (see Git.open)
    def self.open(working_dir, options = {})
      raise ArgumentError, "'#{working_dir}' is not a directory" unless Dir.exist?(working_dir)

      working_dir = root_of_worktree(working_dir) unless options[:repository]

      normalize_paths(options, default_working_directory: working_dir)

      self.new(options)
    end

    # Create an object that executes Git commands in the context of a working
    # copy or a bare repository.
    #
    # @param [Hash] options The options for this command (see list of valid
    #   options below)
    #
    # @option options [Pathname] :working_dir the path to the root of the working
    #   directory.  Should be `nil` if executing commands on a bare repository.
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
    #   of the opened working copy or bare repository
    #
    def initialize(options = {})
      if working_dir = options[:working_directory]
        options[:repository] ||= File.join(working_dir, '.git')
        options[:index] ||= File.join(options[:repository], 'index')
      end
      @logger = (options[:log] || Logger.new(nil))
      @logger.info("Starting Git")

      @working_directory = options[:working_directory] ? Git::WorkingDirectory.new(options[:working_directory]) : nil
      @repository = options[:repository] ? Git::Repository.new(options[:repository]) : nil
      @index = options[:index] ? Git::Index.new(options[:index], false) : nil
    end

    # Update the index from the current worktree to prepare the for the next commit
    #
    # @example
    #   lib.add('path/to/file')
    #   lib.add(['path/to/file1','path/to/file2'])
    #   lib.add(all: true)
    #
    # @param [String, Array<String>] paths a file or files to be added to the repository (relative to the worktree root)
    # @param [Hash] options
    #
    # @option options [Boolean] :all Add, modify, and remove index entries to match the worktree
    # @option options [Boolean] :force Allow adding otherwise ignored files
    #
    def add(paths = '.', **options)
      self.lib.add(paths, options)
    end

    # adds a new remote to this repository
    # url can be a git url or a Git::Base object if it's a local reference
    #
    #  @git.add_remote('scotts_git', 'git://repo.or.cz/rubygit.git')
    #  @git.fetch('scotts_git')
    #  @git.merge('scotts_git/master')
    #
    # Options:
    #   :fetch => true
    #   :track => <branch_name>
    def add_remote(name, url, opts = {})
      url = url.repo.path if url.is_a?(Git::Base)
      self.lib.remote_add(name, url, opts)
      Git::Remote.new(self, name)
    end

    # Create a new git tag
    #
    # @example
    #   repo.add_tag('tag_name', object_reference)
    #   repo.add_tag('tag_name', object_reference, {:options => 'here'})
    #   repo.add_tag('tag_name', {:options => 'here'})
    #
    # @param [String] name The name of the tag to add
    # @param [Hash] options Opstions to pass to `git tag`.
    #   See [git-tag](https://git-scm.com/docs/git-tag) for more details.
    # @option options [boolean] :annotate Make an unsigned, annotated tag object
    # @option options [boolean] :a An alias for the `:annotate` option
    # @option options [boolean] :d Delete existing tag with the given names.
    # @option options [boolean] :f Replace an existing tag with the given name (instead of failing)
    # @option options [String] :message Use the given tag message
    # @option options [String] :m An alias for the `:message` option
    # @option options [boolean] :s Make a GPG-signed tag.
    #
    def add_tag(name, *options)
      self.lib.tag(name, *options)
      self.tag(name)
    end

    # changes current working directory for a block
    # to the git working directory
    #
    # example
    #  @git.chdir do
    #    # write files
    #    @git.add
    #    @git.commit('message')
    #  end
    def chdir # :yields: the Git::Path
      Dir.chdir(dir.path) do
        yield dir.path
      end
    end

    #g.config('user.name', 'Scott Chacon') # sets value
    #g.config('user.email', 'email@email.com')  # sets value
    #g.config('user.email', 'email@email.com', file: 'path/to/custom/config)  # sets value in file
    #g.config('user.name')  # returns 'Scott Chacon'
    #g.config # returns whole config hash
    def config(name = nil, value = nil, options = {})
      if name && value
        # set value
        lib.config_set(name, value, options)
      elsif name
        # return value
        lib.config_get(name)
      else
        # return hash
        lib.config_list
      end
    end

    # returns a reference to the working directory
    #  @git.dir.path
    #  @git.dir.writeable?
    def dir
      @working_directory
    end

    # returns reference to the git index file
    def index
      @index
    end

    # returns reference to the git repository directory
    #  @git.dir.path
    def repo
      @repository
    end

    # returns the repository size in bytes
    def repo_size
      Dir.glob(File.join(repo.path, '**', '*'), File::FNM_DOTMATCH).reject do |f|
        f.include?('..')
      end.map do |f|
        File.expand_path(f)
      end.uniq.map do |f|
        File.stat(f).size.to_i
      end.reduce(:+)
    end

    def set_index(index_file, check = true)
      @lib = nil
      @index = Git::Index.new(index_file.to_s, check)
    end

    def set_working(work_dir, check = true)
      @lib = nil
      @working_directory = Git::WorkingDirectory.new(work_dir.to_s, check)
    end

    # returns +true+ if the branch exists locally
    def is_local_branch?(branch)
      branch_names = self.branches.local.map {|b| b.name}
      branch_names.include?(branch)
    end

    # returns +true+ if the branch exists remotely
    def is_remote_branch?(branch)
      branch_names = self.branches.remote.map {|b| b.name}
      branch_names.include?(branch)
    end

    # returns +true+ if the branch exists
    def is_branch?(branch)
      branch_names = self.branches.map {|b| b.name}
      branch_names.include?(branch)
    end

    # this is a convenience method for accessing the class that wraps all the
    # actual 'git' forked system calls.  At some point I hope to replace the Git::Lib
    # class with one that uses native methods or libgit C bindings
    def lib
      @lib ||= Git::Lib.new(self, @logger)
    end

    # Run a grep for 'string' on the HEAD of the git repository
    #
    # @example Limit grep's scope by calling grep() from a specific object:
    #   git.object("v2.3").grep('TODO')
    #
    # @example Using grep results:
    #   git.grep("TODO").each do |sha, arr|
    #     puts "in blob #{sha}:"
    #     arr.each do |line_no, match_string|
    #       puts "\t line #{line_no}: '#{match_string}'"
    #     end
    #   end
    #
    # @param string [String] the string to search for
    # @param path_limiter [String, Array] a path or array of paths to limit the search to or nil for no limit
    # @param opts [Hash] options to pass to the underlying `git grep` command
    #
    # @option opts [Boolean] :ignore_case (false) ignore case when matching
    # @option opts [Boolean] :invert_match (false) select non-matching lines
    # @option opts [Boolean] :extended_regexp (false) use extended regular expressions
    # @option opts [String] :object (HEAD) the object to search from
    #
    # @return [Hash<String, Array>] a hash of arrays
    #   ```Ruby
    #   {
    #      'tree-ish1' => [[line_no1, match_string1], ...],
    #      'tree-ish2' => [[line_no1, match_string1], ...],
    #      ...
    #   }
    #   ```
    #
    def grep(string, path_limiter = nil, opts = {})
      self.object('HEAD').grep(string, path_limiter, opts)
    end

    # List the files in the worktree that are ignored by git
    # @return [Array<String>] the list of ignored files relative to teh root of the worktree
    #
    def ignored_files
      self.lib.ignored_files
    end

    # removes file(s) from the git repository
    def rm(path = '.', opts = {})
      self.lib.rm(path, opts)
    end

    alias remove rm

    # resets the working directory to the provided commitish
    def reset(commitish = nil, opts = {})
      self.lib.reset(commitish, opts)
    end

    # resets the working directory to the commitish with '--hard'
    def reset_hard(commitish = nil, opts = {})
      opts = {:hard => true}.merge(opts)
      self.lib.reset(commitish, opts)
    end

    # cleans the working directory
    #
    # options:
    #  :force
    #  :d
    #  :ff
    #
    def clean(opts = {})
      self.lib.clean(opts)
    end

    #  returns the most recent tag that is reachable from a commit
    #
    # options:
    #  :all
    #  :tags
    #  :contains
    #  :debug
    #  :exact_match
    #  :dirty
    #  :abbrev
    #  :candidates
    #  :long
    #  :always
    #  :match
    #
    def describe(committish=nil, opts={})
      self.lib.describe(committish, opts)
    end

    # reverts the working directory to the provided commitish.
    # Accepts a range, such as comittish..HEAD
    #
    # options:
    #   :no_edit
    #
    def revert(commitish = nil, opts = {})
      self.lib.revert(commitish, opts)
    end

    # commits all pending changes in the index file to the git repository
    #
    # options:
    #   :all
    #   :allow_empty
    #   :amend
    #   :author
    #
    def commit(message, opts = {})
      self.lib.commit(message, opts)
    end

    # commits all pending changes in the index file to the git repository,
    # but automatically adds all modified files without having to explicitly
    # calling @git.add() on them.
    def commit_all(message, opts = {})
      opts = {:add_all => true}.merge(opts)
      self.lib.commit(message, opts)
    end

    # checks out a branch as the new git working directory
    def checkout(*args, **options)
      self.lib.checkout(*args, **options)
    end

    # checks out an old version of a file
    def checkout_file(version, file)
      self.lib.checkout_file(version,file)
    end

    # fetches changes from a remote branch - this does not modify the working directory,
    # it just gets the changes from the remote if there are any
    def fetch(remote = 'origin', opts = {})
      if remote.is_a?(Hash)
        opts = remote
        remote = nil
      end
      self.lib.fetch(remote, opts)
    end

    # Push changes to a remote repository
    #
    # @overload push(remote = nil, branch = nil, options = {})
    #   @param remote [String] the remote repository to push to
    #   @param branch [String] the branch to push
    #   @param options [Hash] options to pass to the push command
    #
    #   @option opts [Boolean] :mirror (false) Push all refs under refs/heads/, refs/tags/ and refs/remotes/
    #   @option opts [Boolean] :delete (false) Delete refs that don't exist on the remote
    #   @option opts [Boolean] :force (false) Force updates
    #   @option opts [Boolean] :tags (false) Push all refs under refs/tags/
    #   @option opts [Array, String] :push_options (nil) Push options to transmit
    #
    #   @return [Void]
    #
    #   @raise [Git::FailedError] if the push fails
    #   @raise [ArgumentError] if a branch is given without a remote
    #
    def push(*args, **options)
      self.lib.push(*args, **options)
    end

    # merges one or more branches into the current working branch
    #
    # you can specify more than one branch to merge by passing an array of branches
    def merge(branch, message = 'merge', opts = {})
      self.lib.merge(branch, message, opts)
    end

    # iterates over the files which are unmerged
    def each_conflict(&block) # :yields: file, your_version, their_version
      self.lib.conflicts(&block)
    end

    # Pulls the given branch from the given remote into the current branch
    #
    # @param remote [String] the remote repository to pull from
    # @param branch [String] the branch to pull from
    # @param opts [Hash] options to pass to the pull command
    #
    # @option opts [Boolean] :allow_unrelated_histories (false) Merges histories of two projects that started their
    #   lives independently
    # @example pulls from origin/master
    #   @git.pull
    # @example pulls from upstream/master
    #   @git.pull('upstream')
    # @example pulls from upstream/develop
    #   @git.pull('upstream', 'develop')
    #
    # @return [Void]
    #
    # @raise [Git::FailedError] if the pull fails
    # @raise [ArgumentError] if a branch is given without a remote
    def pull(remote = nil, branch = nil, opts = {})
      self.lib.pull(remote, branch, opts)
    end

    # returns an array of Git:Remote objects
    def remotes
      self.lib.remotes.map { |r| Git::Remote.new(self, r) }
    end

    # sets the url for a remote
    # url can be a git url or a Git::Base object if it's a local reference
    #
    #  @git.set_remote_url('scotts_git', 'git://repo.or.cz/rubygit.git')
    #
    def set_remote_url(name, url)
      url = url.repo.path if url.is_a?(Git::Base)
      self.lib.remote_set_url(name, url)
      Git::Remote.new(self, name)
    end

    # removes a remote from this repository
    #
    # @git.remove_remote('scott_git')
    def remove_remote(name)
      self.lib.remote_remove(name)
    end

    # returns an array of all Git::Tag objects for this repository
    def tags
      self.lib.tags.map { |r| tag(r) }
    end

    # Create a new git tag
    #
    # @example
    #   repo.add_tag('tag_name', object_reference)
    #   repo.add_tag('tag_name', object_reference, {:options => 'here'})
    #   repo.add_tag('tag_name', {:options => 'here'})
    #
    # @param [String] name The name of the tag to add
    # @param [Hash] options Opstions to pass to `git tag`.
    #   See [git-tag](https://git-scm.com/docs/git-tag) for more details.
    # @option options [boolean] :annotate Make an unsigned, annotated tag object
    # @option options [boolean] :a An alias for the `:annotate` option
    # @option options [boolean] :d Delete existing tag with the given names.
    # @option options [boolean] :f Replace an existing tag with the given name (instead of failing)
    # @option options [String] :message Use the given tag message
    # @option options [String] :m An alias for the `:message` option
    # @option options [boolean] :s Make a GPG-signed tag.
    #
    def add_tag(name, *options)
      self.lib.tag(name, *options)
      self.tag(name)
    end

    # deletes a tag
    def delete_tag(name)
      self.lib.tag(name, {:d => true})
    end

    # creates an archive file of the given tree-ish
    def archive(treeish, file = nil, opts = {})
      self.object(treeish).archive(file, opts)
    end

    # repacks the repository
    def repack
      self.lib.repack
    end

    def gc
      self.lib.gc
    end

    def apply(file)
      if File.exist?(file)
        self.lib.apply(file)
      end
    end

    def apply_mail(file)
      self.lib.apply_mail(file) if File.exist?(file)
    end

    # Shows objects
    #
    # @param [String|NilClass] objectish the target object reference (nil == HEAD)
    # @param [String|NilClass] path the path of the file to be shown
    # @return [String] the object information
    def show(objectish=nil, path=nil)
      self.lib.show(objectish, path)
    end

    ## LOWER LEVEL INDEX OPERATIONS ##

    def with_index(new_index) # :yields: new_index
      old_index = @index
      set_index(new_index, false)
      return_value = yield @index
      set_index(old_index)
      return_value
    end

    def with_temp_index &blk
      # Workaround for JRUBY, since they handle the TempFile path different.
      # MUST be improved to be safer and OS independent.
      if RUBY_PLATFORM == 'java'
        temp_path = "/tmp/temp-index-#{(0...15).map{ ('a'..'z').to_a[rand(26)] }.join}"
      else
        tempfile = Tempfile.new('temp-index')
        temp_path = tempfile.path
        tempfile.close
        tempfile.unlink
      end

      with_index(temp_path, &blk)
    end

    def checkout_index(opts = {})
      self.lib.checkout_index(opts)
    end

    def read_tree(treeish, opts = {})
      self.lib.read_tree(treeish, opts)
    end

    def write_tree
      self.lib.write_tree
    end

    def write_and_commit_tree(opts = {})
      tree = write_tree
      commit_tree(tree, opts)
    end

    def update_ref(branch, commit)
      branch(branch).update_ref(commit)
    end


    def ls_files(location=nil)
      self.lib.ls_files(location)
    end

    def with_working(work_dir) # :yields: the Git::WorkingDirectory
      return_value = false
      old_working = @working_directory
      set_working(work_dir)
      Dir.chdir work_dir do
        return_value = yield @working_directory
      end
      set_working(old_working)
      return_value
    end

    def with_temp_working &blk
      tempfile = Tempfile.new("temp-workdir")
      temp_dir = tempfile.path
      tempfile.close
      tempfile.unlink
      Dir.mkdir(temp_dir, 0700)
      with_working(temp_dir, &blk)
    end

    # runs git rev-parse to convert the objectish to a full sha
    #
    # @example
    #   git.rev_parse("HEAD^^")
    #   git.rev_parse('v2.4^{tree}')
    #   git.rev_parse('v2.4:/doc/index.html')
    #
    def rev_parse(objectish)
      self.lib.rev_parse(objectish)
    end

    # For backwards compatibility
    alias revparse rev_parse

    def ls_tree(objectish, opts = {})
      self.lib.ls_tree(objectish, opts)
    end

    def cat_file(objectish)
      self.lib.cat_file(objectish)
    end

    # The name of the branch HEAD refers to or 'HEAD' if detached
    #
    # Returns one of the following:
    #   * The branch name that HEAD refers to (even if it is an unborn branch)
    #   * 'HEAD' if in a detached HEAD state
    #
    # @return [String] the name of the branch HEAD refers to or 'HEAD' if detached
    #
    def current_branch
      self.lib.branch_current
    end

    # @return [Git::Branch] an object for branch_name
    def branch(branch_name = self.current_branch)
      Git::Branch.new(self, branch_name)
    end

    # @return [Git::Branches] a collection of all the branches in the repository.
    #   Each branch is represented as a {Git::Branch}.
    def branches
      Git::Branches.new(self)
    end

    # returns a Git::Worktree object for dir, commitish
    def worktree(dir, commitish = nil)
      Git::Worktree.new(self, dir, commitish)
    end

    # returns a Git::worktrees object of all the Git::Worktrees
    # objects for this repo
    def worktrees
      Git::Worktrees.new(self)
    end

    # @return [Git::Object::Commit] a commit object
    def commit_tree(tree = nil, opts = {})
      Git::Object::Commit.new(self, self.lib.commit_tree(tree, opts))
    end

    # @return [Git::Diff] a Git::Diff object
    def diff(objectish = 'HEAD', obj2 = nil)
      Git::Diff.new(self, objectish, obj2)
    end

    # @return [Git::Object] a Git object
    def gblob(objectish)
      Git::Object.new(self, objectish, 'blob')
    end

    # @return [Git::Object] a Git object
    def gcommit(objectish)
      Git::Object.new(self, objectish, 'commit')
    end

    # @return [Git::Object] a Git object
    def gtree(objectish)
      Git::Object.new(self, objectish, 'tree')
    end

    # @return [Git::Log] a log with the specified number of commits
    def log(count = 30)
      Git::Log.new(self, count)
    end

    # returns a Git::Object of the appropriate type
    # you can also call @git.gtree('tree'), but that's
    # just for readability.  If you call @git.gtree('HEAD') it will
    # still return a Git::Object::Commit object.
    #
    # object calls a method that will run a rev-parse
    # on the objectish and determine the type of the object and return
    # an appropriate object for that type
    #
    # @return [Git::Object] an instance of the appropriate type of Git::Object
    def object(objectish)
      Git::Object.new(self, objectish)
    end

    # @return [Git::Remote] a remote of the specified name
    def remote(remote_name = 'origin')
      Git::Remote.new(self, remote_name)
    end

    # @return [Git::Status] a status object
    def status
      Git::Status.new(self)
    end

    # @return [Git::Object::Tag] a tag object
    def tag(tag_name)
      Git::Object.new(self, tag_name, 'tag', true)
    end

    # Find as good common ancestors as possible for a merge
    # example: g.merge_base('master', 'some_branch', 'some_sha', octopus: true)
    #
    # @return [Array<Git::Object::Commit>] a collection of common ancestors
    def merge_base(*args)
      shas = self.lib.merge_base(*args)
      shas.map { |sha| gcommit(sha) }
    end

    private

    # Normalize options before they are sent to Git::Base.new
    #
    # Updates the options parameter by setting appropriate values for the following keys:
    #   * options[:working_directory]
    #   * options[:repository]
    #   * options[:index]
    #
    # All three values will be set to absolute paths. An exception is that
    # :working_directory will be set to nil if bare is true.
    #
    private_class_method def self.normalize_paths(
      options, default_working_directory: nil, default_repository: nil, bare: false
    )
      normalize_working_directory(options, default: default_working_directory, bare: bare)
      normalize_repository(options, default: default_repository, bare: bare)
      normalize_index(options)
    end

    # Normalize options[:working_directory]
    #
    # If working with a bare repository, set to `nil`.
    # Otherwise, set to the first non-nil value of:
    #   1. `options[:working_directory]`,
    #   2. the `default` parameter, or
    #   3. the current working directory
    #
    # Finally, if options[:working_directory] is a relative path, convert it to an absoluite
    # path relative to the current directory.
    #
    private_class_method def self.normalize_working_directory(options, default:, bare: false)
      working_directory =
        if bare
          nil
        else
          File.expand_path(options[:working_directory] || default || Dir.pwd)
        end

      options[:working_directory] = working_directory
    end

    # Normalize options[:repository]
    #
    # If working with a bare repository, set to the first non-nil value out of:
    #   1. `options[:repository]`
    #   2. the `default` parameter
    #   3. the current working directory
    #
    # Otherwise, set to the first non-nil value of:
    #   1. `options[:repository]`
    #   2. `.git`
    #
    # Next, if options[:repository] refers to a *file* and not a *directory*, set
    # options[:repository] to the contents of that file.  This is the case when
    # working with a submodule or a secondary working tree (created with git worktree
    # add). In these cases the repository is actually contained/nested within the
    # parent's repository directory.
    #
    # Finally, if options[:repository] is a relative path, convert it to an absolute
    # path relative to:
    #   1. the current directory if working with a bare repository or
    #   2. the working directory if NOT working with a bare repository
    #
    private_class_method def self.normalize_repository(options, default:, bare: false)
      repository =
        if bare
          File.expand_path(options[:repository] || default || Dir.pwd)
        else
          File.expand_path(options[:repository] || '.git', options[:working_directory])
        end

      if File.file?(repository)
        repository = File.expand_path(File.open(repository).read[8..-1].strip, options[:working_directory])
      end

      options[:repository] = repository
    end

    # Normalize options[:index]
    #
    # If options[:index] is a relative directory, convert it to an absolute
    # directory relative to the repository directory
    #
    private_class_method def self.normalize_index(options)
      index = File.expand_path(options[:index] || 'index', options[:repository])
      options[:index] = index
    end
  end
end
