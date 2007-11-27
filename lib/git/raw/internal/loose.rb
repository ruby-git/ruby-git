#
# converted from the gitrb project
#
# authors: 
#    Matthias Lederhofer <matled@gmx.net>
#    Simon 'corecode' Schubert <corecode@fs.ei.tum.de>
#
# provides native ruby access to git objects and pack files
#

require 'zlib'
require 'digest/sha1'

require 'git/raw/internal/object'

module Git 
  module Raw 
    module Internal
      class LooseObjectError < StandardError
      end

      class LooseStorage
        def initialize(directory)
          @directory = directory
        end

        def [](sha1)
          sha1 = sha1.unpack("H*")[0]

          path = @directory+'/'+sha1[0...2]+'/'+sha1[2..40]
          begin
            get_raw_object(File.read(path))
          rescue Errno::ENOENT
            nil
          end
        end

        def get_raw_object(buf)
          if buf.length < 2
            raise LooseObjectError, "object file too small"
          end

          if legacy_loose_object?(buf)
            content = Zlib::Inflate.inflate(buf)
            header, content = content.split(/\0/, 2)
            if !header || !content
              raise LooseObjectError, "invalid object header"
            end
            type, size = header.split(/ /, 2)
            if !%w(blob tree commit tag).include?(type) || size !~ /^\d+$/
              raise LooseObjectError, "invalid object header"
            end
            type = type.to_sym
            size = size.to_i
          else
            type, size, used = unpack_object_header_gently(buf)
            content = Zlib::Inflate.inflate(buf[used..-1])
          end
          raise LooseObjectError, "size mismatch" if content.length != size
          return RawObject.new(type, content)
        end

        # private
        def unpack_object_header_gently(buf)
          used = 0
          c = buf[used]
          used += 1

          type = (c >> 4) & 7;
          size = c & 15;
          shift = 4;
          while c & 0x80 != 0
            if buf.length <= used
              raise LooseObjectError, "object file too short"
            end
            c = buf[used]
            used += 1

            size += (c & 0x7f) << shift
            shift += 7
          end
          type = OBJ_TYPES[type]
          if ![:blob, :tree, :commit, :tag].include?(type)
            raise LooseObjectError, "invalid loose object type"
          end
          return [type, size, used]
        end
        private :unpack_object_header_gently

        def legacy_loose_object?(buf)
          word = (buf[0] << 8) + buf[1]
          buf[0] == 0x78 && word % 31 == 0
        end
        private :legacy_loose_object?
      end
    end 
  end
end

if $0 == __FILE__
  require 'find'
  ARGV.each do |path|
    storage = Git::Internal::LooseStorage.new(path)
    Find.find(path) do |p|
      next if !/\/([0-9a-f]{2})\/([0-9a-f]{38})$/.match(p)
      obj = storage[[$1+$2].pack("H*")]
      puts "%s %s" % [obj.sha1.unpack("H*")[0], obj.type]
    end
  end
end
