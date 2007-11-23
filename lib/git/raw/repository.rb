require 'git/raw/internal/object'
require 'git/raw/internal/pack'
require 'git/raw/internal/loose'
require 'git/raw/object'

module Git
  module Raw
    
    class Repository
      def initialize(git_dir)
        @git_dir = git_dir
        @loose = Raw::Internal::LooseStorage.new(git_path("objects"))
        @packs = []
        initpacks
      end

      def show
        @packs.each do |p|
          puts p.name
          puts
          p.each_sha1 do |s|
            puts "**#{p[s].type}**"
            if p[s].type.to_s == 'commit'
              puts s.unpack('H*')
              puts p[s].content
            end
          end
          puts
        end
      end
      
      def cat_file(sha)
        get_raw_object_by_sha1(sha).content rescue nil
      end
      
      def log(sha, count = 30)
        output = ''
        i = 0

        while sha && (i < count) do
          o = get_raw_object_by_sha1(sha)
          c = Git::Raw::Object.from_raw(o)
          
          output += "commit #{sha}\n"
          output += o.content + "\n"

          sha = c.parent.first
          i += 1
        end
        
        output
      end
      
      def get_object_by_sha1(sha1)
        r = get_raw_object_by_sha1(sha1)
        return nil if !r
        Object.from_raw(r, self)
      end

      def get_raw_object_by_sha1(sha1)
        sha1 = [sha1].pack("H*")

        # try packs
        @packs.each do |pack|
          o = pack[sha1]
          return o if o
        end

        # try loose storage
        o = @loose[sha1]
        return o if o

        # try packs again, maybe the object got packed in the meantime
        initpacks
        @packs.each do |pack|
          o = pack[sha1]
          return o if o
        end

        nil
      end

      protected
      
        def git_path(path)
          return "#@git_dir/#{path}"
        end

      private 
      
        def initpacks
          @packs.each do |pack|
            pack.close
          end
          @packs = []
          Dir.open(git_path("objects/pack/")) do |dir|
            dir.each do |entry|
              if entry =~ /\.pack$/i
                @packs << Git::Raw::Internal::PackStorage.new(git_path("objects/pack/" \
                                                                  + entry))
              end
            end
          end
        end
      
    end
    
  end
end
