module Git
  class Remote < Path
    
    attr_accessor :name, :url, :fetch
    
    @base = nil
    
    def initialize(base, name)
      @base = base
      config = @base.lib.config_remote(name)
      @name = name
      @url = config['url']
      @fetch = config['fetch']
    end
    
    def to_s
      @name
    end
    
  end
end