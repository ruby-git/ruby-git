require 'git/base/factory'

module Git
  # Git::Base is the main public interface for interacting with Git commands.
  #
  # Instead of creating a Git::Base directly, obtain a Git::Base instance by
  # calling one of the follow {Git} class methods: {Git.open}, {Git.init},
  # {Git.clone}, or {Git.bare}.
  #
  class Base
    include Git::Base::Factory

    # (see Git.bare)
    def self.bare(git_dir, options = {})
      self.new({:repository => git_dir}.merge(options))
    end

    # (see Git.clone)
    def self.clone(repository, name, options = {})
      self.new(Git::Lib.new(nil, options[:log]).clone(repository, name, options))
    end

    # Returns (and initialize if needed) a Git::Config instance
    #
    # @return [Git::Config] the current config instance.
    def self.config
      return @@config ||= Config.new
    end

    # (see Git.init)
    def self.init(directory, options = {})
      options[:working_directory] ||= directory
      options[:repository] ||= File.join(options[:working_directory], '.git')

      FileUtils.mkdir_p(options[:working_directory]) if options[:working_directory] && !File.directory?(options[:working_directory])

      init_options = { :bare => options[:bare] }

      options.delete(:working_directory) if options[:bare]

      # Submodules have a .git *file* not a .git folder.
      # This file's contents point to the location of
      # where the git refs are held (In the parent repo)
      if options[:working_directory] && File.file?(File.join(options[:working_directory], '.git'))
        git_file = File.open('.git').read[8..-1].strip
        options[:repository] = git_file
        options[:index] = git_file + '/index'
      end

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

    # (see Git.open)
    def self.open(working_dir, options={})
       # TODO: move this to Git.open?

      options[:working_directory] ||= working_dir
      options[:repository] ||= File.join(options[:working_directory], '.git')

       # Submodules have a .git *file* not a .git folder.
      # This file's contents point to the location of
      # where the git refs are held (In the parent repo)
      if options[:working_directory] && File.file?(File.join(options[:working_directory], '.git'))
        git_file = File.open('.git').read[8..-1].strip
        options[:repository] = git_file
        options[:index] = git_file + '/index'
      end

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
      if options[:log]
        @logger = options[:log]
        @logger.info("Starting Git")
      else
        @logger = nil
      end

      @working_directory = options[:working_directory] ? Git::WorkingDirectory.new(options[:working_directory]) : nil
      @repository = options[:repository] ? Git::Repository.new(options[:repository]) : nil
      @index = options[:index] ? Git::Index.new(options[:index], false) : nil
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
    #g.config('user.name')  # returns 'Scott Chacon'
    #g.config # returns whole config hash
    def config(name = nil, value = nil)
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

    # updates the repository index using the working directory content
    #
    # @example
    #   git.add
    #   git.add('path/to/file')
    #   git.add(['path/to/file1','path/to/file2'])
    #   git.add(:all => true)
    #
    # options:
    #   :all => true
    #
    # @param [String,Array] paths files paths to be added (optional, default='.')
    # @param [Hash] options
    # @option options [boolean] :all
    #   Update the index not only where the working tree has a file matching
    #   <pathspec> but also where the index already has an entry.
    #   See [the --all option to git-add](https://git-scm.com/docs/git-add#Documentation/git-add.txt--A)
    #   for more details.
    #
    def add(paths = '.', **options)
      self.lib.add(paths, options)
    end

    # removes file(s) from the git repository
    def remove(path = '.', opts = {})
      self.lib.remove(path, opts)
    end

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
    def checkout(branch = 'master', opts = {})
      self.lib.checkout(branch, opts)
    end

    # checks out an old version of a file
    def checkout_file(version, file)
      self.lib.checkout_file(version,file)
    end

    # fetches changes from a remote branch - this does not modify the working directory,
    # it just gets the changes from the remote if there are any
    def fetch(remote = 'origin', opts={})
      self.lib.fetch(remote, opts)
    end

    # pushes changes to a remote repository - easiest if this is a cloned repository,
    # otherwise you may have to run something like this first to setup the push parameters:
    #
    #  @git.config('remote.remote-name.push', 'refs/heads/master:refs/heads/master')
    #
    def push(remote = 'origin', branch = 'master', opts = {})
      # Small hack to keep backwards compatibility with the 'push(remote, branch, tags)' method signature.
      opts = {:tags => opts} if [true, false].include?(opts)

      self.lib.push(remote, branch, opts)
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

    # pulls the given branch from the given remote into the current branch
    #
    #  @git.pull                          # pulls from origin/master
    #  @git.pull('upstream')              # pulls from upstream/master
    #  @git.pull('upstream', 'develope')  # pulls from upstream/develop
    #
    def pull(remote='origin', branch='master')
			self.lib.pull(remote, branch)
    end

    # returns an array of Git:Remote objects
    def remotes
      self.lib.remotes.map { |r| Git::Remote.new(self, r) }
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

    # Creates a new git tag (Git::Tag)
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
    #   git.revparse("HEAD^^")
    #   git.revparse('v2.4^{tree}')
    #   git.revparse('v2.4:/doc/index.html')
    #
    def revparse(objectish)
      self.lib.revparse(objectish)
    end

    def ls_tree(objectish)
      self.lib.ls_tree(objectish)
    end

    def cat_file(objectish)
      self.lib.object_contents(objectish)
    end

    # returns the name of the branch the working directory is currently on
    def current_branch
      self.lib.branch_current
    end

  end

end
