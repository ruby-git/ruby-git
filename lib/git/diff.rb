module Git
  
  # object that holds the last X commits on given branch
  class Diff
    include Enumerable
    
    @base = nil
    @from = nil
    @to = nil
    @path = nil
    
    @full_diff = nil
    @full_diff_files = nil
    @stats = nil
    
    def initialize(base, from = nil, to = nil)
      @base = base
      @from = from.to_s
      @to = to.to_s
    end
    
    def path(path)
      @path = path
      return self
    end
    
    def size
      cache_stats
      @stats[:total][:files]
    end
    
    def lines
      cache_stats
      @stats[:total][:lines]
    end
    
    def deletions
      cache_stats
      @stats[:total][:deletions]
    end
    
    def insertions
      cache_stats
      @stats[:total][:insertions]
    end
    
    def stats
      cache_stats
      @stats
    end
    
    # if file is provided and is writable, it will write the patch into the file
    def patch(file = nil)
      cache_full
      @full_diff
    end
    alias_method :to_s, :patch
    
    # enumerable methods
    
    def [](key)
      process_full
      @full_diff_files.assoc(key)[1]
    end
    
    def each
      process_full
      @full_diff_files.each do |file|
        yield file[1]
      end
    end
    
    class DiffFile
      attr_accessor :patch, :path, :mode, :src, :dst, :type
      @base = nil
      
      def initialize(base, hash)
        @base = base
        @patch = hash[:patch]
        @path = hash[:path]
        @mode = hash[:mode]
        @src = hash[:src]
        @dst = hash[:dst]
        @type = hash[:type]
      end
      
      def blob(type = :dst)
        if type == :src
          @base.object(@src) if @src != '0000000'
        else
          @base.object(@dst) if @dst != '0000000'
        end
      end
    end
    
    private
    
      def cache_full
        if !@full_diff
          @full_diff = @base.lib.diff_full(@from, @to, {:path_limiter => @path})
        end
      end
      
      def process_full
        if !@full_diff_files
          cache_full
          @full_diff_files = process_full_diff
        end
      end
      
      def cache_stats
        if !@stats
          @stats = @base.lib.diff_stats(@from, @to, {:path_limiter => @path})
        end
      end
      
      # break up @diff_full
      def process_full_diff
        final = {}
        current_file = nil
        @full_diff.split("\n").each do |line|
          if m = /diff --git a\/(.*?) b\/(.*?)/.match(line)
            current_file = m[1]
            final[current_file] = {:patch => line, :path => current_file, 
                                    :mode => '', :src => '', :dst => '', :type => 'modified'}
          else
            if m = /index (.......)\.\.(.......)( ......)*/.match(line)
              final[current_file][:src] = m[1]
              final[current_file][:dst] = m[2]
              final[current_file][:mode] = m[3].strip if m[3]
            end
            if m = /(.*?) file mode (......)/.match(line)
              final[current_file][:type] = m[1]
              final[current_file][:mode] = m[2]
            end
            final[current_file][:patch] << "\n" + line 
          end
        end
        final.map { |e| [e[0], DiffFile.new(@base, e[1])] }
      end
      
  end
end