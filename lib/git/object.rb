module Git
  class Object
    attr_accessor :sha, :type
    
    def initialize(sha)
      @sha = sha
    end
    
    def cat_file
    end
    
    def raw
    end
    
  end
end