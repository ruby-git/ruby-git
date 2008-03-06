module Git
  
  # object that holds all the available stashes
  class Stashes
    include Enumerable
    
    @base = nil
    @stashes = nil
    
    def initialize(base)
      @stashes = []
      
      @base = base
            
      @base.lib.stashes_all.each do |id, message|
        @stashes.unshift(Git::Stash.new(@base, message, true))
      end
    end
    
    def save(message)
      s = Git::Stash.new(@base, message)
      @stashes.unshift(s) if s.saved?
    end
    
    def apply(index=0)
      @base.lib.stash_apply(index.to_i)
    end
    
    def clear
      @base.lib.stash_clear
      @stashes = []
    end

    def size
      @stashes.size
    end
    
    def each
      @stashes.each do |s|
        yield s
      end
    end
    
    def [](index)
      @stashes[index.to_i]
    end
    
  end
end