module Git
  
  # object that holds all the available branches
  class Branches
    include Enumerable
    
    @base = nil
    @branches = nil
    
    def initialize(base)
      @branches = {}
      
      @base = base
            
      @base.lib.branches_all.each do |b|
        @branches[b[0]] = Git::Branch.new(@base, b[0])
      end
    end

    def local
      self.select { |b| !b.remote }
    end
    
    def remote
      self.select { |b| b.remote }
    end
    
    # array like methods

    def size
      @branches.size
    end    
    
    def each
      @branches.each do |k, b|
        yield b
      end
    end
    
    def [](symbol)
      @branches[symbol.to_s]
    end
    
  end
end