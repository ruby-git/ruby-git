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
    alias_method :tree, :object
    alias_method :commit, :object
    alias_method :blob, :object
    
    
    def log(count = 30)
      Git::Log.new(self, count)
    end

    def status
      Git::Status.new(self)
    end
        
    def branches
      Git::Branches.new(self)
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
    
    # convenience methods
    
    def revparse(objectish)
      self.lib.revparse(objectish)
    end
    
  end
  
end