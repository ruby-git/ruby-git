module Git

 class Path

    attr_accessor :path

    def initialize(path, check_path=true)
      expanded_path = File.expand_path(path)
      if check_path && !File.exists?(expanded_path)
        raise ArgumentError, 'path does not exist', [expanded_path]
      end

      @path = expanded_path
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
