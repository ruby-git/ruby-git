module Git
  
  class GitTagNameDoesNotExist< StandardError 
  end
  
  # represents a git object
  class Object
    
    class AbstractObject
      attr_accessor :objectish, :size, :type, :mode
    
      @base = nil
      @contents = nil
      @size = nil
      @sha = nil
      
      def initialize(base, objectish)
        @base = base
        @objectish = objectish.to_s
        setup
      end

      def sha
        @sha || @sha = @base.lib.revparse(@objectish)
      end
      
      def size
        @size || @size = @base.lib.object_size(@objectish)
      end
      
      # caches the contents of this call in memory
      def contents
        @contents || @contents = @base.lib.object_contents(@objectish)
      end
      
      def contents_array
        self.contents.split("\n")
      end
      
      def setup
        raise NotImplementedError
      end
      
      def to_s
        @objectish
      end
      
      def grep(string, path_limiter = nil, opts = {})
        default = {:object => sha, :path_limiter => path_limiter}
        grep_options = default.merge(opts)
        @base.lib.grep(string, grep_options)
      end
      
      def diff(objectish)
        Git::Diff.new(@base, @objectish, objectish)
      end
      
      def log(count = 30)
        Git::Log.new(@base, count).object(@objectish)
      end
      
      # creates an archive of this object (tree)
      def archive(file = nil, opts = {})
        @base.lib.archive(@objectish, file, opts)
      end
      
      def tree?
        @type == 'tree'
      end
      
      def blob?
        @type == 'blob'
      end
      
      def commit?
        @type == 'commit'
      end
       
     def tag?
       @type == 'tag'
     end
     
    end
  
    
    class Blob < AbstractObject
      
      def initialize(base, sha, mode = nil)
        super(base, sha)
        @mode = mode
      end
      
      private
      
        def setup
          @type = 'blob'
        end
    end
  
    class Tree < AbstractObject
      
      @trees = nil
      @blobs = nil
      
      def initialize(base, sha, mode = nil)
        super(base, sha)
        @mode = mode
      end
            
      def children
        blobs.merge(subtrees)
      end
      
      def blobs
        check_tree
        @blobs
      end
      alias_method :files, :blobs
      
      def trees
        check_tree
        @trees
      end
      alias_method :subtrees, :trees
      alias_method :subdirectories, :trees
       
      private
      
        def setup
          @type = 'tree'
        end 

        # actually run the git command
        def check_tree
          if !@trees
            @trees = {}
            @blobs = {}
            data = @base.lib.ls_tree(@objectish)
            data['tree'].each { |k, d| @trees[k] = Tree.new(@base, d[:sha], d[:mode]) }
            data['blob'].each { |k, d| @blobs[k] = Blob.new(@base, d[:sha], d[:mode]) }
          end
        end
      
    end
  
    class Commit < AbstractObject
      
      @tree = nil
      @parents = nil
      @author = nil
      @committer = nil
      @message = nil
      
      def initialize(base, sha, init = nil)
        super(base, sha)
        if init
          set_commit(init)
        end
      end
      
      def message
        check_commit
        @message
      end
      
      def name
        @base.lib.namerev(sha)
      end
      
      def gtree
        check_commit
        Tree.new(@base, @tree)
      end
      
      def parent
        parents.first
      end
      
      # array of all parent commits
      def parents
        check_commit
        @parents        
      end
      
      # git author
      def author     
        check_commit
        @author
      end
      
      def author_date
        author.date
      end
      
      # git author
      def committer
        check_commit
        @committer
      end
      
      def committer_date 
        committer.date
      end
      alias_method :date, :committer_date

      def diff_parent
        diff(parent)
      end
      
      def set_commit(data)
        if data['sha']
          @sha = data['sha']
        end
        @committer = Git::Author.new(data['committer'])
        @author = Git::Author.new(data['author'])
        @tree = Tree.new(@base, data['tree'])
        @parents = data['parent'].map{ |sha| Commit.new(@base, sha) }
        @message = data['message'].chomp
      end
            
      private
      
        def setup
          @type = 'commit'
        end
  
        # see if this object has been initialized and do so if not
        def check_commit
          if !@tree
            data = @base.lib.commit_data(@objectish)
            set_commit(data)
          end
        end
      
    end
  
    class Tag < AbstractObject
      attr_accessor :name
      
      def initialize(base, sha, name)
        super(base, sha)
        @name = name
      end
      
      private
        
        def setup
          @type = 'tag'
        end
        
    end
    
    class << self
      # if we're calling this, we don't know what type it is yet
      # so this is our little factory method
      def new(base, objectish, type = nil, is_tag = false)
        if is_tag
          sha = base.lib.tag_sha(objectish)
          if sha == ''
            raise Git::GitTagNameDoesNotExist.new(objectish)
          end
          return Tag.new(base, sha, objectish)
        else
          if !type
            type = base.lib.object_type(objectish) 
          end
        end
        
        klass =
          case type
          when /blob/:   Blob   
          when /commit/: Commit
          when /tree/:   Tree
          end
        klass::new(base, objectish)
      end
    end 
    
  end
end