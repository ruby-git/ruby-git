module Git
  
  class Base

    @working_directory = nil
    @repository = nil
    @index = nil

    # opens a Git Repository - no working directory options
    def self.repo(git_dir)
      self.new :repository => git_dir
    end
    
    # opens a new Git Project from a working directory
    # you can specify non-standard git_dir and index file in the options
    def self.open(working_dir, opts={})    
      default = {:working_directory => working_dir,
                 :repository => File.join(working_dir, '.git'), 
                 :index => File.join(working_dir, '.git', 'index')}
      git_options = default.merge(opts)
      
      self.new(git_options)
    end
    
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

    def self.clone
      raise NotImplementedError
    end
        
    def initialize(options = {})
      @working_directory = Git::WorkingDirectory.new(options[:working_directory]) if options[:working_directory]
      @repository = Git::Repository.new(options[:repository]) if options[:repository]
      @index = Git::Index.new(options[:index]) if options[:index]
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
    
    # convenience methods
    
    def revparse(objectish)
      self.lib.revparse(objectish)
    end
    
  end
  
end