module Git
  class Object
    
    class AbstractObject
      attr_accessor :sha, :size, :type
    
      @base = nil
    
      def initialize(base, sha)
        @base = base
        @sha = sha
        @size = @base.lib.object_size(@sha)
        setup
      end
    
      def contents
        @base.lib.object_contents(@sha)
      end
      
      def contents_array
        self.contents.split("\n")
      end
      
      def setup
        raise NotImplementedError
      end
      
    end
  
    
    class Blob < AbstractObject
      def setup
        @type = 'blob'
      end
    end
  
    class Tree < AbstractObject
      def setup
        @type = 'tree'
      end
    end
  
    class Commit < AbstractObject
      def setup
        @type = 'commit'
      end
    end
  
  
    class << self
      # if we're calling this, we don't know what type it is yet
      # so this is our little factory method
      def new(base, objectish)
        sha = base.lib.revparse(objectish)
        type = base.lib.object_type(sha)
      
        klass =
          case type
          when /blob/:   Blob   
          when /commit/: Commit
          when /tree/:   Tree
          end
        klass::new(base, sha)
      end
    end 
    
  end
end