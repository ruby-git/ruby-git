module Git
  
  # object that holds the last X commits on given branch
  class Log
    include Enumerable
    
    @base = nil
    @commits = nil
    
    @file = nil
    @count = nil
    @since = nil
    @between = nil
    
    @dirty_flag = nil
    
    def initialize(base, count = 30)
      dirty_log
      @base = base
      @count = count
    end

    def file(file)
      dirty_log
      @file = file
      return self
    end
    
    def since(date)
      dirty_log
      @since = date
      return self
    end
    
    def between(sha1, sha2 = nil)
      dirty_log
      @between = [@base.lib.revparse(sha1), @base.lib.revparse(sha2)]
      return self
    end
    
    def to_s
      self.map { |c| c.sha }.join("\n")
    end
    

    # forces git log to run
    
    def size
      check_log
      @commits.size rescue nil
    end
    
    def each
      check_log
      @commits.each do |c|
        yield c
      end
    end
    
    def first
      check_log
      @commits.first rescue nil
    end
    
    private 
    
      def dirty_log
        @dirty_flag = true
      end
      
      def check_log
        if @dirty_flag
          run_log
          @dirty_flag = false
        end
      end
      
      # actually run the 'git log' command
      def run_log      
        @commits = @base.lib.log_commits(:count => @count, :file => @file, :since => @since, :between => @between)
      end
      
  end
  
end