module Git
  class Branch < Path
    
    @base = nil
    
    def initialize(base, name)
      @base = base
    end
    
  end
end
