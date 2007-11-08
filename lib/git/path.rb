module Git
  class Path
    
    attr_accessor :path
    
    def initialize(path)
      if File.exists?(path)
        @path = path
      else
        raise ArgumentError, "path does not exist", path 
      end
    end
    
    def readable?
      File.readable?(@path)
    end

    def writable?
      File.writable?(@path)
    end
    
  end
end