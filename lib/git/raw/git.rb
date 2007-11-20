require 'git/internal/object'
require 'git/internal/pack'
require 'git/internal/loose'
require 'git/object'

module Git
  class Repository
    def initialize(git_dir)
      @git_dir = git_dir
      @loose = Internal::LooseStorage.new(git_path("objects"))
      @packs = []
      initpacks
    end

    def git_path(path)
      return "#@git_dir/#{path}"
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

    def initpacks
      @packs.each do |pack|
        pack.close
      end
      @packs = []
      Dir.open(git_path("objects/pack/")) do |dir|
        dir.each do |entry|
          if entry =~ /\.pack$/i
            @packs << Git::Internal::PackStorage.new(git_path("objects/pack/" \
                                                              + entry))
          end
        end
      end
    end
  end
end
