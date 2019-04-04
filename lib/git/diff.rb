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

    def [](path)
      @diff_files ||= each.map { |df| [df.path, df] }.to_h
      @diff_files[path]
    end

    def each
      return to_enum unless block_given?
      DiffFile.parse_each(patch.each_line, base: @base) { |diff_file| yield diff_file }
    end

    class DiffFile
      module Parsing
        private

        def headers
          {
            git_diff: /^diff --git a\/(?<path_before>.*) b\/(?<path_after>.*)/,
            sha_mode: /^index (?<src>[[:xdigit:]]+)\.\.(?<dst>[[:xdigit:]]+)( (?<mode>\d{6}))?/,
            type_mode: /^(?<type>new|deleted) file mode (?<mode>\d{6})/,
            binary?: /^Binary files /,
          }
        end

        def each_slice(lines_enum, at:, drop: 0)
          return enum_for(:each_slice, lines_enum, at: at, drop: drop) unless block_given?

          lines_enum.slice_when { |_, next_line| at.match(next_line) }.each do |slice|
            if drop.positive?
              drop -= 1
              next
            end
            yield slice
          end
        end
      end
      extend Parsing
      include Parsing

      def self.parse_each(diff_lines_enum, base:)
        diff_file_lines = each_slice(diff_lines_enum, at: headers[:git_diff])
        diff_file_lines.each { |lines| yield self.new(base, lines) }
      end

      attr_accessor :patch, :path, :mode, :src, :dst, :type
      @base = nil

      def initialize(base, file_diff_lines)
        @base = base

        hash = { :mode => '', :src => '', :dst => '', :type => 'modified' }
        file_diff_lines.each do |line|
          if m = headers[:git_diff].match(line)
            hash[:patch] = line
            hash[:path] = m[:path_before]
          else
            if m = headers[:sha_mode].match(line)
              hash[:src] = m[:src]
              hash[:dst] = m[:dst]
              hash[:mode] = m[:mode] if m[:mode]
            end
            if m = headers[:type_mode].match(line)
              hash[:type] = m[:type]
              hash[:mode] = m[:mode]
            end
            if m = headers[:binary?].match(line)
              hash[:binary] = true
            end
            hash[:patch] << line
          end
        end

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
  end
end
