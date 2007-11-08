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
    
    def initialize(options = {})
      @working_directory = Git::Repository.new(options[:working_directory]) if options[:working_directory]
      @repository = Git::Repository.new(options[:repository]) if options[:repository]
      @index = Git::Index.new(options[:index]) if options[:index]
    end
  
    def self.clone
      raise NotImplementedError
    end
  
    def self.init
      raise NotImplementedError
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
    
    
    def log(count = 30)
      Git::Log.new(self, count)
    end
    
    def lib
      Git::Lib.new(self)
    end
    
    private
    
      def is_git_dir(dir)
      end

  end
  
end