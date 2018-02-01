module Git
  
  class Status
    include Enumerable
    
    def initialize(base)
      @base = base
      construct_status
    end
    
    def changed
      @files.select { |k, f| f.type == 'M' }
    end
    
    def added
      @files.select { |k, f| f.type == 'A' }
    end

    def deleted
      @files.select { |k, f| f.type == 'D' }
    end
    
    def untracked
      @files.select { |k, f| f.untracked }
    end
    
    def pretty
      out = ''
      self.each do |file|
        out << pretty_file(file)
      end
      out << "\n"
      out
    end

    def pretty_file(file)
      <<FILE
#{file.path}
\tsha(r) #{file.sha_repo.to_s} #{file.mode_repo.to_s}
\tsha(i) #{file.sha_index.to_s} #{file.mode_index.to_s}
\ttype   #{file.type.to_s}
\tstage  #{file.stage.to_s}
\tuntrac #{file.untracked.to_s}
FILE
    end
    
    # enumerable method
    
    def [](file)
      @files[file]
    end
    
    def each(&block)
      @files.values.each(&block)
    end
    
    class StatusFile
      attr_accessor :path, :type, :stage, :untracked
      attr_accessor :mode_index, :mode_repo
      attr_accessor :sha_index, :sha_repo

      def initialize(base, hash)
        @base = base
        @path = hash[:path]
        @type = hash[:type]
        @stage = hash[:stage]
        @mode_index = hash[:mode_index]
        @mode_repo = hash[:mode_repo]
        @sha_index = hash[:sha_index]
        @sha_repo = hash[:sha_repo]
        @untracked = hash[:untracked]
      end
      
      def blob(type = :index)
        if type == :repo
          @base.object(@sha_repo)
        else
          @base.object(@sha_index) rescue @base.object(@sha_repo)
        end
      end
      
      
    end
    
    private
    
      def construct_status
        @files = @base.lib.ls_files
        ignore = @base.lib.ignored_files
        
        # find untracked in working dir
        Dir.chdir(@base.dir.path) do
          Dir.glob('**/*', File::FNM_DOTMATCH) do |file|
            next if @files[file] || File.directory?(file) || ignore.include?(file) || file =~ /^.git\/.+/

            @files[file] = {:path => file, :untracked => true}
          end
        end
        
        # find modified in tree
        @base.lib.diff_files.each do |path, data|
          @files[path] ? @files[path].merge!(data) : @files[path] = data
        end
        
        # find added but not committed - new files
        @base.lib.diff_index('HEAD').each do |path, data|
          @files[path] ? @files[path].merge!(data) : @files[path] = data
        end
        
        @files.each do |k, file_hash|
          @files[k] = StatusFile.new(@base, file_hash)
        end
      end
      
  end
  
end
