module Git
  
  # object that holds all the available branches
  class Branches
    include Enumerable
    
    @base = nil
    @branches = nil
    
    def initialize(base)
      @base = base
      @branches = @base.lib.branches_all
    end
    
  end
end