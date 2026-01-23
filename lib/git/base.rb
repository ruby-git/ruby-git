# frozen_string_literal: true

require 'logger'
require 'open3'
require 'pathname'

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
      paths = resolve_paths(repository: git_dir, bare: true)
      new(options.merge(paths))
    end

    # (see Git.clone)
    def self.clone(repository_url, directory, options = {})
      lib_options = {}
      lib_options[:git_ssh] = options[:git_ssh] if options.key?(:git_ssh)
      clone_result = Git::Lib.new(lib_options, options[:log]).clone(repository_url, directory, options)
      bare = options[:bare] || options[:mirror]
      paths = resolve_paths(
        working_directory: clone_result[:working_directory],
        repository: clone_result[:repository],
        bare: bare
      )
      new(options.merge(paths))
    end

    # (see Git.default_branch)
    def self.repository_default_branch(repository, options = {})
      Git::Lib.new(nil, options[:log]).repository_default_branch(repository)
    end

    # Returns (and initialize if needed) a Git::Config instance
    #
    # @return [Git::Config] the current config instance.
    def self.config
      @config ||= Config.new
    end

    def self.binary_version(binary_path)
      result, status = execute_git_version(binary_path)

      raise "Failed to get git version: #{status}\n#{result}" unless status.success?

      parse_version_string(result)
    end

    private_class_method def self.execute_git_version(binary_path)
      Open3.capture2e(
        binary_path,
        '-c', 'core.quotePath=true',
        '-c', 'color.ui=false',
        'version'
      )
    rescue Errno::ENOENT
      raise "Failed to get git version: #{binary_path} not found"
    end

    private_class_method def self.parse_version_string(raw_string)
      version_match = raw_string.match(/\d+(\.\d+)+/)
      return [0, 0, 0] unless version_match

      version_parts = version_match[0].split('.').map(&:to_i)
      version_parts.fill(0, version_parts.length...3)
    end

    def self.root_of_worktree(working_dir)
      raise ArgumentError, "'#{working_dir}' does not exist" unless Dir.exist?(working_dir)

      result, status = execute_rev_parse_toplevel(working_dir)
      process_rev_parse_result(result, status, working_dir)
    end

    private_class_method def self.execute_rev_parse_toplevel(working_dir)
      Open3.capture2e(
        Git::Base.config.binary_path,
        '-c', 'core.quotePath=true',
        '-c', 'color.ui=false',
        'rev-parse', '--show-toplevel',
        chdir: File.expand_path(working_dir)
      )
    rescue Errno::ENOENT
      raise ArgumentError, 'Failed to find the root of the worktree: git binary not found'
    end

    private_class_method def self.process_rev_parse_result(result, status, working_dir)
      raise ArgumentError, "'#{working_dir}' is not in a git working tree" unless status.success?

      result.chomp
    end

    # (see Git.open)
    def self.open(working_dir, options = {})
      raise ArgumentError, "'#{working_dir}' is not a directory" unless Dir.exist?(working_dir)

      working_dir = root_of_worktree(working_dir) unless options[:repository]

      paths = resolve_paths(
        working_directory: working_dir,
        repository: options[:repository],
        index: options[:index]
      )

      new(options.merge(paths))
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
    # @option options [String, nil] :git_ssh Path to a custom SSH executable or script.
    #   Controls how SSH is configured for this {Git::Base} instance:
    #   - If this option is not provided, the global Git::Base.config.git_ssh setting is used.
    #   - If this option is explicitly set to nil, SSH is disabled for this instance.
    #   - If this option is a non-empty String, that value is used as the SSH command for
    #     this instance, overriding the global Git::Base.config.git_ssh setting.
    #
    # @return [Git::Base] an object that can execute git commands in the context
    #   of the opened working copy or bare repository
    #
    def initialize(options = {})
      setup_logger(options[:log])
      @git_ssh = options.key?(:git_ssh) ? options[:git_ssh] : :use_global_config
      initialize_components(options)
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
      lib.add(paths, options)
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
      url = url.repo.to_s if url.is_a?(Git::Base)
      lib.remote_add(name, url, opts)
      Git::Remote.new(self, name)
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
    def chdir # :yields: the working directory Pathname
      Dir.chdir(dir.to_s) do
        yield dir
      end
    end

    # g.config('user.name', 'Scott Chacon') # sets value
    # g.config('user.email', 'email@email.com')  # sets value
    # g.config('user.email', 'email@email.com', file: 'path/to/custom/config)  # sets value in file
    # g.config('user.name')  # returns 'Scott Chacon'
    # g.config # returns whole config hash
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

    # Returns a reference to the working directory
    #
    # @example
    #   @git.dir.to_s
    #   @git.dir.writable?
    #
    # @return [Pathname] the working directory path
    #
    def dir
      @working_directory
    end

    # Returns a reference to the git index file
    #
    # @return [Pathname] the index file path
    #
    attr_reader :index

    # Returns a reference to the git repository directory
    #
    # @example
    #   @git.repo.to_s
    #
    # @return [Pathname] the repository directory path
    #
    def repo
      @repository
    end

    # returns the repository size in bytes
    def repo_size
      all_files = Dir.glob(File.join(repo.path, '**', '*'), File::FNM_DOTMATCH)

      all_files.reject { |file| file.include?('..') }
               .map { |file| File.expand_path(file) }
               .uniq
               .sum { |file| File.stat(file).size.to_i }
    end

    private

    def deprecate_check_argument(check, must_exist)
      unless check.nil?
        Git::Deprecation.warn(
          'The "check" argument is deprecated and will be removed in a future version. ' \
          'Use "must_exist:" instead.'
        )
      end
      # default is true
      must_exist.nil? && check.nil? ? true : must_exist | check
    end

    def validate_path(path, must_exist)
      Pathname.new(File.expand_path(path.to_s)).tap do |expanded_path|
        raise ArgumentError, "path does not exist: #{expanded_path}" if must_exist && !expanded_path.exist?
      end
    end

    public

    def set_index(index_file, check = nil, must_exist: nil)
      must_exist = deprecate_check_argument(check, must_exist)
      @lib = nil
      @index = validate_path(index_file, must_exist)
    end

    def set_working(work_dir, check = nil, must_exist: nil)
      must_exist = deprecate_check_argument(check, must_exist)
      @lib = nil
      @working_directory = validate_path(work_dir, must_exist)
    end

    # returns +true+ if the branch exists locally
    def local_branch?(branch)
      branch_names = branches.local.map(&:name)
      branch_names.include?(branch)
    end

    def is_local_branch?(branch) # rubocop:disable Naming/PredicatePrefix
      Git::Deprecation.warn(
        'Git::Base#is_local_branch? is deprecated and will be removed in a future version. ' \
        'Use Git::Base#local_branch? instead.'
      )
      local_branch?(branch)
    end

    # returns +true+ if the branch exists remotely
    def remote_branch?(branch)
      branch_names = branches.remote.map(&:name)
      branch_names.include?(branch)
    end

    def is_remote_branch?(branch) # rubocop:disable Naming/PredicatePrefix
      Git::Deprecation.warn(
        'Git::Base#is_remote_branch? is deprecated and will be removed in a future version. ' \
        'Use Git::Base#remote_branch? instead.'
      )
      remote_branch?(branch)
    end

    # returns +true+ if the branch exists
    def branch?(branch)
      branch_names = branches.map(&:name)
      branch_names.include?(branch)
    end

    def is_branch?(branch) # rubocop:disable Naming/PredicatePrefix
      Git::Deprecation.warn(
        'Git::Base#is_branch? is deprecated and will be removed in a future version. ' \
        'Use Git::Base#branch? instead.'
      )
      branch?(branch)
    end

    # this is a convenience method for accessing the class that wraps all the
    # actual 'git' forked system calls.  At some point I hope to replace the Git::Lib
    # class with one that uses native methods or libgit C bindings
    def lib
      @lib ||= Git::Lib.new(self, @logger)
    end

    # Returns the per-instance git_ssh configuration value.
    #
    # This may be:
    # * a [String] path when an explicit git_ssh command has been configured
    # * the Symbol `:use_global_config` when this instance is using the global config
    # * `nil` when SSH has been explicitly disabled for this instance
    #
    # @return [String, Symbol, nil] the git_ssh configuration value for this instance
    # @api private
    attr_reader :git_ssh

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
    # @param path_limiter [String, Pathname, Array<String, Pathname>] a path or array
    #   of paths to limit the search to or nil for no limit
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
      object('HEAD').grep(string, path_limiter, opts)
    end

    # List the files in the worktree that are ignored by git
    # @return [Array<String>] the list of ignored files relative to teh root of the worktree
    #
    def ignored_files
      lib.ignored_files
    end

    # removes file(s) from the git repository
    def rm(path = '.', opts = {})
      lib.rm(path, opts)
    end

    alias remove rm

    # resets the working directory to the provided commitish
    def reset(commitish = nil, opts = {})
      lib.reset(commitish, opts)
    end

    # resets the working directory to the commitish with '--hard'
    #
    # @deprecated Use {#reset} with `hard: true` instead.
    #
    def reset_hard(commitish = nil, opts = {})
      Git::Deprecation.warn(
        'Git::Base#reset_hard is deprecated and will be removed in a future version. ' \
        'Use Git::Base#reset(commitish, hard: true) instead.'
      )
      opts = { hard: true }.merge(opts)
      lib.reset(commitish, opts)
    end

    # cleans the working directory
    #
    # options:
    #  :force
    #  :d
    #  :ff
    #
    def clean(opts = {})
      lib.clean(opts)
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
    def describe(committish = nil, opts = {})
      lib.describe(committish, opts)
    end

    # reverts the working directory to the provided commitish.
    # Accepts a range, such as comittish..HEAD
    #
    # options:
    #   :no_edit
    #
    def revert(commitish = nil, opts = {})
      lib.revert(commitish, opts)
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
      lib.commit(message, opts)
    end

    # commits all pending changes in the index file to the git repository,
    # but automatically adds all modified files without having to explicitly
    # calling @git.add() on them.
    def commit_all(message, opts = {})
      opts = { add_all: true }.merge(opts)
      lib.commit(message, opts)
    end

    # checks out a branch as the new git working directory
    def checkout(*, **)
      lib.checkout(*, **)
    end

    # checks out an old version of a file
    def checkout_file(version, file)
      lib.checkout_file(version, file)
    end

    # fetches changes from a remote branch - this does not modify the working directory,
    # it just gets the changes from the remote if there are any
    def fetch(remote = 'origin', opts = {})
      if remote.is_a?(Hash)
        opts = remote
        remote = nil
      end
      lib.fetch(remote, opts)
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
    def push(*, **)
      lib.push(*, **)
    end

    # merges one or more branches into the current working branch
    #
    # you can specify more than one branch to merge by passing an array of branches
    def merge(branch, message = 'merge', opts = {})
      lib.merge(branch, message, opts)
    end

    # iterates over the files which are unmerged
    def each_conflict(&) # :yields: file, your_version, their_version
      lib.conflicts(&)
    end

    # Pulls the given branch from the given remote into the current branch
    #
    # @param remote [String] the remote repository to pull from
    # @param branch [String] the branch to pull from
    # @param opts [Hash] options to pass to the pull command
    #
    # @option opts [Boolean] :allow_unrelated_histories (false) Merges histories of
    #   two projects that started their lives independently
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
      lib.pull(remote, branch, opts)
    end

    # returns an array of Git:Remote objects
    def remotes
      lib.remotes.map { |r| Git::Remote.new(self, r) }
    end

    # sets the url for a remote
    # url can be a git url or a Git::Base object if it's a local reference
    #
    #  @git.set_remote_url('scotts_git', 'git://repo.or.cz/rubygit.git')
    #
    def set_remote_url(name, url)
      url = url.repo.to_s if url.is_a?(Git::Base)
      lib.remote_set_url(name, url)
      Git::Remote.new(self, name)
    end

    # Configures which branches are fetched for a remote
    #
    # Uses `git remote set-branches` to set or append fetch refspecs. When the `add:`
    # option is not given, the `--add` option is not passed to the git command
    #
    # @example Replace fetched branches with a single glob pattern
    #   git = Git.open('/path/to/repo')
    #   # Only fetch branches matching "feature/*" from origin
    #   git.remote_set_branches('origin', 'feature/*')
    #
    # @example Append a glob pattern to existing fetched branches
    #   git = Git.open('/path/to/repo')
    #   # Keep existing fetch refspecs and add all release branches
    #   git.remote_set_branches('origin', 'release/*', add: true)
    #
    # @example Configure multiple explicit branches
    #   git = Git.open('/path/to/repo')
    #   git.remote_set_branches('origin', 'main', 'development', 'hotfix')
    #
    # @param name [String] the remote name (for example, "origin")
    # @param branches [Array<String>] branch names or globs (for example, '*')
    # @param add [Boolean] when true, append to existing refspecs instead of replacing them
    #
    # @return [nil]
    #
    # @raise [ArgumentError] if no branches are provided @raise [Git::FailedError] if
    # the underlying git command fails
    #
    def remote_set_branches(name, *branches, add: false)
      branch_list = branches.flatten
      raise ArgumentError, 'branches are required' if branch_list.empty?

      lib.remote_set_branches(name, branch_list, add: add)

      nil
    end

    # removes a remote from this repository
    #
    # @git.remove_remote('scott_git')
    def remove_remote(name)
      lib.remote_remove(name)
    end

    # returns an array of all Git::Tag objects for this repository
    def tags
      lib.tags.map { |r| tag(r) }
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
      lib.tag(name, *options)
      tag(name)
    end

    # deletes a tag
    def delete_tag(name)
      lib.tag(name, { d: true })
    end

    # creates an archive file of the given tree-ish
    def archive(treeish, file = nil, opts = {})
      object(treeish).archive(file, opts)
    end

    # repacks the repository
    def repack
      lib.repack
    end

    def gc
      lib.gc
    end

    # Verifies the connectivity and validity of objects in the database
    #
    # Runs `git fsck` to check repository integrity and identify dangling,
    # missing, or unreachable objects.
    #
    # @overload fsck(objects = [], options = {})
    #   @param objects [Array<String>] specific objects to treat as heads for unreachability trace.
    #     If no objects are given, git fsck defaults to using the index file, all SHA-1
    #     references in the refs namespace, and all reflogs.
    #   @param [Hash] options options to pass to the underlying `git fsck` command
    #
    #   @option options [Boolean] :unreachable print unreachable objects
    #   @option options [Boolean] :strict enable strict checking
    #   @option options [Boolean] :connectivity_only check only connectivity (faster)
    #   @option options [Boolean] :root report root nodes
    #   @option options [Boolean] :tags report tags
    #   @option options [Boolean] :cache consider objects in the index
    #   @option options [Boolean] :no_reflogs do not consider reflogs
    #   @option options [Boolean] :lost_found write dangling objects to .git/lost-found
    #     (note: this modifies the repository by creating files)
    #   @option options [Boolean, nil] :dangling print dangling objects (true/false/nil for default)
    #   @option options [Boolean, nil] :full check objects in alternate pools (true/false/nil for default)
    #   @option options [Boolean, nil] :name_objects name objects by refs (true/false/nil for default)
    #   @option options [Boolean, nil] :references check refs database consistency (true/false/nil for default)
    #
    #   @return [Git::FsckResult] categorized objects flagged by fsck
    #
    #   @example Check repository integrity
    #     result = git.fsck
    #     result.dangling.each { |obj| puts "#{obj.type}: #{obj.sha}" }
    #
    #   @example Check with strict mode and suppress dangling output
    #     result = git.fsck(strict: true, dangling: false)
    #
    #   @example Check if repository has any issues
    #     result = git.fsck
    #     puts "Repository is clean" if result.empty?
    #
    #   @example List root commits
    #     result = git.fsck(root: true)
    #     result.root.each { |obj| puts obj.sha }
    #
    #   @example Check specific objects
    #     result = git.fsck('abc1234', 'def5678')
    #
    # rubocop:disable Style/ArgumentsForwarding
    def fsck(*objects, **opts)
      lib.fsck(*objects, **opts)
    end
    # rubocop:enable Style/ArgumentsForwarding

    def apply(file)
      return unless File.exist?(file)

      lib.apply(file)
    end

    def apply_mail(file)
      lib.apply_mail(file) if File.exist?(file)
    end

    # Shows objects
    #
    # @param [String|NilClass] objectish the target object reference (nil == HEAD)
    # @param [String|NilClass] path the path of the file to be shown
    # @return [String] the object information
    def show(objectish = nil, path = nil)
      lib.show(objectish, path)
    end

    ## LOWER LEVEL INDEX OPERATIONS ##

    def with_index(new_index) # :yields: new_index
      old_index = @index
      set_index(new_index, false)
      return_value = yield @index
      set_index(old_index)
      return_value
    end

    def with_temp_index(&)
      # Workaround for JRUBY, since they handle the TempFile path different.
      # MUST be improved to be safer and OS independent.
      if RUBY_PLATFORM == 'java'
        temp_path = "/tmp/temp-index-#{(0...15).map { ('a'..'z').to_a[rand(26)] }.join}"
      else
        tempfile = Tempfile.new('temp-index')
        temp_path = tempfile.path
        tempfile.close
        tempfile.unlink
      end

      with_index(temp_path, &)
    end

    def checkout_index(opts = {})
      lib.checkout_index(opts)
    end

    def read_tree(treeish, opts = {})
      lib.read_tree(treeish, opts)
    end

    def write_tree
      lib.write_tree
    end

    def write_and_commit_tree(opts = {})
      tree = write_tree
      commit_tree(tree, opts)
    end

    def update_ref(branch, commit)
      branch(branch).update_ref(commit)
    end

    def ls_files(location = nil)
      lib.ls_files(location)
    end

    def with_working(work_dir) # :yields: the working directory Pathname
      return_value = false
      old_working = @working_directory
      set_working(work_dir)
      Dir.chdir work_dir do
        return_value = yield @working_directory
      end
      set_working(old_working)
      return_value
    end

    def with_temp_working(&)
      tempfile = Tempfile.new('temp-workdir')
      temp_dir = tempfile.path
      tempfile.close
      tempfile.unlink
      Dir.mkdir(temp_dir, 0o700)
      with_working(temp_dir, &)
    end

    # runs git rev-parse to convert the objectish to a full sha
    #
    # @example
    #   git.rev_parse("HEAD^^")
    #   git.rev_parse('v2.4^{tree}')
    #   git.rev_parse('v2.4:/doc/index.html')
    #
    def rev_parse(objectish)
      lib.rev_parse(objectish)
    end

    # For backwards compatibility
    alias revparse rev_parse

    def ls_tree(objectish, opts = {})
      lib.ls_tree(objectish, opts)
    end

    def cat_file(objectish)
      lib.cat_file(objectish)
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
      lib.branch_current
    end

    # @return [Git::Branch] an object for branch_name
    def branch(branch_name = current_branch)
      branch_info = Git::BranchInfo.new(
        refname: branch_name,
        current: false,
        worktree: false,
        symref: nil
      )
      Git::Branch.new(self, branch_info)
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
      Git::Object::Commit.new(self, lib.commit_tree(tree, opts))
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
      Git::Object::Tag.new(self, tag_name)
    end

    # Find as good common ancestors as possible for a merge
    # example: g.merge_base('master', 'some_branch', 'some_sha', octopus: true)
    #
    # @return [Array<Git::Object::Commit>] a collection of common ancestors
    def merge_base(*)
      shas = lib.merge_base(*)
      shas.map { |sha| gcommit(sha) }
    end

    # Returns a Git::Diff::Stats object for accessing diff statistics.
    #
    # @param objectish [String] The first commit or object to compare. Defaults to 'HEAD'.
    # @param obj2 [String, nil] The second commit or object to compare.
    # @param opts [Hash] Options to filter the diff.
    # @option opts [String, Pathname, Array<String, Pathname>] :path_limiter Limit stats to specified path(s).
    # @return [Git::DiffStats]
    def diff_stats(objectish = 'HEAD', obj2 = nil, opts = {})
      Git::DiffStats.new(self, objectish, obj2, opts[:path_limiter])
    end

    # Returns a Git::Diff::PathStatus object for accessing the name-status report.
    #
    # @param objectish [String] The first commit or object to compare. Defaults to 'HEAD'.
    # @param obj2 [String, nil] The second commit or object to compare.
    # @param opts [Hash] Options to filter the diff.
    # @option opts [String, Pathname, Array<String, Pathname>] :path_limiter Limit status to specified path(s).
    # @option opts [String, Pathname, Array<String, Pathname>] :path (deprecated) Legacy alias for :path_limiter.
    # @return [Git::DiffPathStatus]
    def diff_path_status(objectish = 'HEAD', obj2 = nil, opts = {})
      path_limiter = if opts.key?(:path_limiter)
                       opts[:path_limiter]
                     elsif opts.key?(:path)
                       Git::Deprecation.warn(
                         'Git::Base#diff_path_status :path option is deprecated. Use :path_limiter instead.'
                       )
                       opts[:path]
                     end

      Git::DiffPathStatus.new(self, objectish, obj2, path_limiter)
    end

    # Provided for backwards compatibility
    alias diff_name_status diff_path_status

    private

    # Initializes the logger from the provided options
    # @param log_option [Logger, nil] The logger instance from options.
    def setup_logger(log_option)
      @logger = log_option || Logger.new(nil)
      @logger.info('Starting Git')
    end

    # Initializes the core git objects based on the provided options
    # @param options [Hash] The processed options hash.
    def initialize_components(options)
      @working_directory = Pathname.new(options[:working_directory]) if options[:working_directory]
      @repository = Pathname.new(options[:repository]) if options[:repository]
      @index = Pathname.new(options[:index]) if options[:index]
    end

    # Resolve and normalize paths for a Git repository
    #
    # Returns a new hash containing the resolved absolute paths for:
    #   * :working_directory - the working tree root (nil for bare repos)
    #   * :repository - the .git directory
    #   * :index - the index file
    #
    # This method does not mutate any inputs.
    #
    # @param working_directory [String, nil] the working directory path
    # @param repository [String, nil] the repository (.git) directory path
    # @param index [String, nil] the index file path
    # @param bare [Boolean] whether this is a bare repository
    #
    # @return [Hash] a hash with :working_directory, :repository, and :index keys
    #
    private_class_method def self.resolve_paths(working_directory: nil, repository: nil, index: nil, bare: false)
      working_dir = resolve_working_directory(working_directory, bare: bare)
      # For bare repos, use working_directory as the default repository location
      repo_path = resolve_repository(repository, working_dir, bare: bare, bare_default: working_directory)
      index_path = resolve_index(index, repo_path)

      {
        working_directory: working_dir,
        repository: repo_path,
        index: index_path
      }
    end

    # Resolve the working directory path
    #
    # @param path [String, nil] the working directory path or nil
    # @param bare [Boolean] whether this is a bare repository
    # @return [String, nil] the absolute path or nil for bare repos
    #
    private_class_method def self.resolve_working_directory(path, bare:)
      return nil if bare

      File.expand_path(path || Dir.pwd)
    end

    # Resolve the repository (.git) directory path
    #
    # Handles the gitdir pointer file case for submodules and worktrees.
    #
    # @param path [String, nil] the repository path or nil
    # @param working_dir [String, nil] the working directory for relative path resolution
    # @param bare [Boolean] whether this is a bare repository
    # @param bare_default [String, nil] for bare repos, use this as default if path is nil
    # @return [String] the absolute path to the repository
    #
    private_class_method def self.resolve_repository(path, working_dir, bare:, bare_default: nil)
      initial_path = if bare
                       File.expand_path(path || bare_default || Dir.pwd)
                     else
                       File.expand_path(path || '.git', working_dir)
                     end

      resolve_gitdir_pointer(initial_path, working_dir)
    end

    # Resolve gitdir pointer files used by submodules and worktrees
    #
    # If the path points to a file containing "gitdir: <path>", returns the
    # resolved path. Otherwise returns the original path.
    #
    # @param path [String] the path to check
    # @param working_dir [String, nil] base directory for relative path resolution
    # @return [String] the resolved absolute path
    #
    private_class_method def self.resolve_gitdir_pointer(path, working_dir)
      return path unless File.file?(path)

      gitdir_content = File.read(path).strip
      return path unless gitdir_content.start_with?('gitdir: ')

      gitdir_path = gitdir_content.sub(/\Agitdir: /, '')
      File.expand_path(gitdir_path, working_dir)
    end

    # Resolve the index file path
    #
    # @param path [String, nil] the index path or nil
    # @param repository [String] the repository directory for relative path resolution
    # @return [String] the absolute path to the index file
    #
    private_class_method def self.resolve_index(path, repository)
      File.expand_path(path || 'index', repository)
    end
  end
end
