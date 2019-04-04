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

        def range_info
          /^@@ -(?<start_before>\d+)(,(?<num_before>\d+))? \+(?<start_after>\d+)(,(?<num_after>\d+))? @@/
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

      def initialize(base, file_diff_lines)
        @base = base
        @lines_raw = file_diff_lines
      end

      def blob(type = :dst)
        sha = type == :src ? src : dst
        @base.object(sha) if sha != '0000000'
      end

      def patch;   @lines_raw.join;           end
      def path;    header_data[:path_before]; end
      def src;     header_data[:src];         end
      def dst;     header_data[:dst];         end
      def type;    header_data[:type];        end
      def mode;    header_data[:mode];        end
      def binary?; !!header_data[:binary?];   end

      def added_lines;   changed_lines('+'); end
      def deleted_lines; changed_lines('-'); end

      private

      def header_data
        @header_data ||= begin
          header_lines = each_slice(@lines_raw, at: range_info).first

          header_matches = headers.map do |name, h_rgx|
            match = header_lines.lazy.map { |line| h_rgx.match(line) }.detect(&:itself)
            [name, match] if match # Ruby 2.4+: Hash#transform_values
          end.compact

          header_matches.map do |name, m|
            if m.names.empty?
              { name => true }
            else
              m.names.map { |n| m[n] && [n.to_sym, m[n]] }.compact.to_h # Ruby 2.4+: MatchData#named_captures
            end
          end.inject(:merge)
        end
      end

      def changed_lines(prefix)
        omit_prefix, range_match = { '+' => ['-', :after], '-' => ['+', :before] }.fetch(prefix)

        change_hunks = each_slice(@lines_raw, at: range_info, drop: 1)
        change_hunks.flat_map do |change_lines|
          hunk_header, *diff_lines = change_lines

          match = range_info.match(hunk_header)
          startline = match["start_#{range_match}"].to_i
          num_lines = match["num_#{range_match}"]&.to_i || 1
          line_range = startline...(startline + num_lines)

          changed_lines = diff_lines.reject { |diff_line| diff_line.start_with?(omit_prefix) }
          numbered_lines = line_range.zip(changed_lines)
          numbered_lines.map do |n, diff_line|
            DiffLine.new(n, diff_line[1..-1]).freeze if diff_line[0] == prefix
          end.compact
        end
      end
    end

    DiffLine = Struct.new(:line_num, :line)
  end
end
