module Git
  class Branch < Path
    
    attr_accessor :full, :remote, :name
    
    @base = nil
    @gcommit = nil
    
    def initialize(base, name)
      @remote = nil
      @full = name
      @base = base
      
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
    
    def checkout
      check_if_create
      @base.lib.checkout(@name)
    end
    
    def create
      check_if_create
    end
    
    def delete
      @base.lib.branch_delete(@name)
    end
    
    def current
      determine_current
    end
    
    def to_s
      @name
    end
    
    private 

      def check_if_create
        @base.lib.branch_new(@name) rescue nil
      end
      
      def determine_current
        @base.lib.branch_current == @name
      end
    
  end
end
