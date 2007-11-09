module Git
  class Branch < Path
    
    attr_accessor :full, :remote, :name, :current, :commit
    
    @base = nil
    
    def initialize(base, name, current = false)
      @remote = nil
      @full = name
      @base = base
      @commit = @base.object(name)
      @current = current
      
      parts = name.split('/')
      if parts[1]
        @remote = Git::Remote.new(@base, parts[0])
        @name = parts[1]
      else
        @name = parts[0]
      end
    end
    
  end
end
