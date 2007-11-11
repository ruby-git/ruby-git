module Git
  class Branch < Path
    
    attr_accessor :full, :remote, :name, :current
    
    @base = nil
    @gcommit = nil
    
    def initialize(base, name, current = false)
      @remote = nil
      @full = name
      @base = base
      @current = current
      
      parts = name.split('/')
      if parts[1]
        @remote = Git::Remote.new(@base, parts[0])
        @name = parts[1]
      else
        @name = parts[0]
      end
    end
    
    def gcommit
      @gcommit = @base.object(name) if !@gcommit
      @gcommit
    end
    
  end
end
