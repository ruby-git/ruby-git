module Git

  # object that holds the last X commits on given branch
  class Diff
    include Enumerable

    def initialize(base, from = nil, to = nil)
      @base = base
      @from = from && from.to_s
      @to = to && to.to_s

      @path = nil
    end
    attr_reader :from, :to

    def name_status
      @name_status ||= @base.lib.diff_name_status(@from, @to, path: @path)
    end

    def path(path)
      @path = path
      return self
    end

    def size
      stats[:total][:files]
    end

    def lines
      stats[:total][:lines]
    end

    def deletions
      stats[:total][:deletions]
    end

    def insertions
      stats[:total][:insertions]
    end

    def stats
      @stats ||= @base.lib.diff_stats(@from, @to, path_limiter: @path)
    end

    # if file is provided and is writable, it will write the patch into the file
    def patch
      @patch ||= @base.lib.diff_full(@from, @to, path_limiter: @path)
    end
    alias_method :to_s, :patch

    # enumerable methods

    def [](key)
      full_diff_files[key]
    end

    def each
      full_diff_files.each_value { |diff_file| yield diff_file }
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
        @binary = hash[:binary]
      end

      def binary?
        !!@binary
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

      # break up @diff_full
    def full_diff_files
      @full_diff_files ||= begin
        defaults = {
          :mode => '',
          :src => '',
          :dst => '',
          :type => 'modified'
        }
        final = {}
        current_file = nil
        if patch.encoding.name != "UTF-8"
          full_diff_utf8_encoded = patch.encode("UTF-8", "binary", { :invalid => :replace, :undef => :replace })
        else
          full_diff_utf8_encoded = patch
        end
        full_diff_utf8_encoded.split("\n").each do |line|
          if m = /^diff --git a\/(.*?) b\/(.*?)/.match(line)
            current_file = m[1]
            final[current_file] = defaults.merge({:patch => line, :path => current_file})
          else
            if m = /^index (.......)\.\.(.......)( ......)*/.match(line)
              final[current_file][:src] = m[1]
              final[current_file][:dst] = m[2]
              final[current_file][:mode] = m[3].strip if m[3]
            end
            if m = /^([[:alpha:]]*?) file mode (......)/.match(line)
              final[current_file][:type] = m[1]
              final[current_file][:mode] = m[2]
            end
            if m = /^Binary files /.match(line)
              final[current_file][:binary] = true
            end
            final[current_file][:patch] << "\n" + line
          end
        end
        final.map { |k, h| [k, DiffFile.new(@base, h)] }.to_h
      end
    end
  end
end
