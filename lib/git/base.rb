module Git
  
  class Base

    @working_directory = nil
    @repository = nil
    @index = nil

    # opens a bare Git Repository - no working directory options
    def self.bare(git_dir)
      self.new :repository => git_dir
    end
    
    # opens a new Git Project from a working directory
    # you can specify non-standard git_dir and index file in the options
    def self.open(working_dir, opts={})    
      default = {:working_directory => working_dir}
      git_options = default.merge(opts)
      
      self.new(git_options)
    end

    # initializes a git repository
    #
    # options:
    #  :repository
    #  :index_file
    #
    def self.init(working_dir, opts = {})
      default = {:working_directory => working_dir,
                 :repository => File.join(working_dir, '.git')}
      git_options = default.merge(opts)
      
      if git_options[:working_directory]
        # if !working_dir, make it
        FileUtils.mkdir_p(git_options[:working_directory]) if !File.directory?(git_options[:working_directory])
      end
      
      # run git_init there
      Git::Lib.new(git_options).init
       
      self.new(git_options)
    end

    # clones a git repository locally
    #
    #  repository - http://repo.or.cz/w/sinatra.git
    #  name - sinatra
    #
    # options:
    #   :repository
    #
    #    :bare
    #   or 
    #    :working_directory
    #    :index_file
    #
    def self.clone(repository, name, opts = {})
      # run git-clone 
      self.new(Git::Lib.new.clone(repository, name, opts))
    end
        
    def initialize(options = {})
      if working_dir = options[:working_directory]
        options[:repository] = File.join(working_dir, '.git') if !options[:repository]
        options[:index] = File.join(working_dir, '.git', 'index') if !options[:index]
      end
      
      @working_directory = Git::WorkingDirectory.new(options[:working_directory]) if options[:working_directory]
      @repository = Git::Repository.new(options[:repository]) if options[:repository]
      @index = Git::Index.new(options[:index], false) if options[:index]
    end
  
  
    def dir
      @working_directory
    end

    def repo
      @repository
    end
    
    def index
      @index
    end
    
    def chdir
      Dir.chdir(dir.path) do
        yield dir.path
      end
    end
    
    def repo_size
      size = 0
      Dir.chdir(repo.path) do
        (size, dot) = `du -d0`.chomp.split
      end
      size.to_i
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
    
    # factory methods
    
    def object(objectish)
      Git::Object.new(self, objectish)
    end
    alias_method :gtree, :object
    alias_method :gcommit, :object
    alias_method :gblob, :object
    
    
    def log(count = 30)
      Git::Log.new(self, count)
    end

    def status
      Git::Status.new(self)
    end
        
    def branches
      Git::Branches.new(self)
    end
    
    def branch(branch_name = 'master')
      Git::Branch.new(self, branch_name)
    end

    def remote(remote_name = 'origin')
      Git::Remote.new(self, remote_name)
    end

    
    def lib
      Git::Lib.new(self)
    end
    
    def grep(string)
      self.object('HEAD').grep(string)
    end
    
    def diff(objectish = 'HEAD', obj2 = nil)
      Git::Diff.new(self, objectish, obj2)
    end
    
    # adds files from the working directory to the git repository
    def add(path = '.')
      self.lib.add(path)
    end

    def remove(path = '.', opts = {})
      self.lib.remove(path, opts)
    end

    def reset(commitish = nil, opts = {})
      self.lib.reset(commitish, opts)
    end

    def reset_hard(commitish = nil, opts = {})
      opts = {:hard => true}.merge(opts)
      self.lib.reset(commitish, opts)
    end

    def commit(message, opts = {})
      self.lib.commit(message, opts)
    end
        
    def commit_all(message, opts = {})
      opts = {:add_all => true}.merge(opts)
      self.lib.commit(message, opts)
    end

    def checkout(branch = 'master', opts = {})
      self.lib.checkout(branch, opts)
    end
    
    def fetch(remote = 'origin')
      self.lib.fetch(remote)
    end

    def push(remote = 'origin', branch = 'master')
      self.lib.push(remote, branch)
    end
    
    def merge(branch, message = 'merge')
      self.lib.merge(branch, message)
    end

    def pull(remote = 'origin', branch = 'master', message = 'origin pull')
      fetch(remote)
      merge(branch, message)
    end
    
    def remotes
      self.lib.remotes.map { |r| Git::Remote.new(self, r) }
    end
    
    def add_remote(name, url, opts = {})
      if url.is_a?(Git::Base)
        url = url.repo.path
      end
      self.lib.remote_add(name, url, opts)
      Git::Remote.new(self, name)
    end

    def tags
      self.lib.tags.map { |r| tag(r) }
    end
    
    def tag(tag_name)
      Git::Object.new(self, tag_name, true)
    end

    def add_tag(tag_name)
      self.lib.tag(tag_name)
      tag(tag_name)
    end
    
    # convenience methods

    def repack
      self.lib.repack
    end
    
    def revparse(objectish)
      self.lib.revparse(objectish)
    end

    def current_branch
      self.lib.branch_current
    end

    
  end
  
end