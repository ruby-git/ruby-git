module Git
  
  # object that holds the last X commits on given branch
  class Diff
    include Enumerable
    
    @base = nil
    @from = nil
    @to = nil
    
    @full_diff = nil
    
    def initialize(base, from = nil, to = nil)
      dirty_log
      @base = base
      @from = from
      @to = to
    end
    
    def 
    # enumerable methods
    
    def each
      cache_diff
      @full_diff.each do |file|
        yield file
      end
    end
    
    private
    
      def cache_diff
        if !@full_diff
          @full_diff = @base.lib.diff_files(@from, @to)
        end
      end
end