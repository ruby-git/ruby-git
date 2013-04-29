module Git
 
 class Path
    
    attr_accessor :path
    
    def initialize(path, check_path=true)
      if check_path && !File.exists?(path)
        raise ArgumentError, 'path does not exist', [File.expand_path(path)]
      end
      
      @path = File.expand_path(path)
    end
    
    def readable?
      File.readable?(@path)
    end

    def writable?
      File.writable?(@path)
    end
    
    def to_s
      @path
    end
    
  end

end
