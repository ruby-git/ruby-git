module Git
  
  # object that holds the last X commits on given branch
  class Log
    include Enumerable
    
    @base = nil
    @commits = nil
    
    def initialize(base, count = 30)
      @base = base
      @commits = @base.lib.log_shas(count)
    end

    def size
      @commits.size
    end
    
    def each
      @commits.each do |c|
        yield c
      end
    end
    
    def first
      @commits.first
    end
    
    def to_s
      self.map { |c| c.sha }.join("\n")
    end
    
  end
  
end