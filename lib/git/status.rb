module Git
  
  class Status
    include Enumerable
    
    @base = nil
    @files = nil
    
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
    
    def untracked
      @files.select { |k, f| f.untracked }
    end
    
    def pretty
      out = ''
      self.each do |file|
        out << file.path
        out << "\n\tsha(r) " + file.sha_repo.to_s
        out << "\n\tsha(i) " + file.sha_index.to_s
        out << "\n\ttype   " + file.type.to_s
        out << "\n\tstage  " + file.stage.to_s
        out << "\n\tuntrac " + file.untracked.to_s
        out << "\n"
      end
      out << "\n"
      out
    end
    
    # enumerable method
    
    def [](file)
      @files[file]
    end
    
    def each
      @files.each do |k, file|
        yield file
      end
    end
    
    class StatusFile
      attr_accessor :path, :type, :stage, :untracked
      attr_accessor :mode_index, :mode_repo
      attr_accessor :sha_index, :sha_repo
      
      def initialize(hash)
        @path = hash[:path]
        @type = hash[:type]
        @stage = hash[:stage]
        @mode_index = hash[:mode_index]
        @mode_repo = hash[:mode_repo]
        @sha_index = hash[:sha_index]
        @sha_repo = hash[:sha_repo]
        @untracked = hash[:untracked]
      end
      
      
    end
    
    private
    
      def construct_status
        @files = @base.lib.ls_files
        
        # find untracked in working dir
        Dir.chdir(@base.dir.path) do
          Dir.glob('**/*') do |file|
            if !@files[file]
              @files[file] = {:path => file, :untracked => true} if !File.directory?(file)
            end
          end
        end

        # find modified in tree
        @base.lib.diff_files.each do |path, data|
          @files[path].merge!(data)
        end
        
        # find added but not committed - new files
        @base.lib.diff_index('HEAD').each do |path, data|
          @files[path].merge!(data)
        end
        
        @files.each do |k, file_hash|
          @files[k] = StatusFile.new(file_hash)
        end
      end
      
  end
  
end