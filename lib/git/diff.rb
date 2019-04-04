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
      end
      extend Parsing

      def self.parse_each(diff_lines_enum, base:)
        defaults = {
          :mode => '',
          :src => '',
          :dst => '',
          :type => 'modified'
        }
        current_file = nil
        final = {}
        diff_lines_enum.each do |line|
          if m = headers[:git_diff].match(line)
            current_file = m[:path_before]
            final[current_file] = defaults.merge({:patch => line, :path => current_file})
          else
            if m = headers[:sha_mode].match(line)
              final[current_file][:src] = m[:src]
              final[current_file][:dst] = m[:dst]
              final[current_file][:mode] = m[:mode] if m[:mode]
            end
            if m = headers[:type_mode].match(line)
              final[current_file][:type] = m[:type]
              final[current_file][:mode] = m[:mode]
            end
            if m = headers[:binary?].match(line)
              final[current_file][:binary] = true
            end
            final[current_file][:patch] << line
          end
        end
        final.each_value { |h| yield DiffFile.new(base, h) }
      end

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
  end
end
