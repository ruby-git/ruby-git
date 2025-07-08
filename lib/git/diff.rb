# frozen_string_literal: true

require_relative 'diff_path_status'
require_relative 'diff_stats'

module Git
  # object that holds the diff between two commits
  class Diff
    include Enumerable

    def initialize(base, from = nil, to = nil)
      @base = base
      @from = from&.to_s
      @to = to&.to_s

      @path = nil
      @full_diff_files = nil
    end
    attr_reader :from, :to

    def path(path)
      @path = path
      self
    end

    def patch
      @base.lib.diff_full(@from, @to, { path_limiter: @path })
    end
    alias to_s patch

    def [](key)
      process_full
      @full_diff_files.assoc(key)[1]
    end

    def each(&)
      process_full
      @full_diff_files.map { |file| file[1] }.each(&)
    end

    def size
      stats_provider.total[:files]
    end

    #
    # DEPRECATED METHODS
    #

    def name_status
      path_status_provider.to_h
    end

    def lines
      stats_provider.lines
    end

    def deletions
      stats_provider.deletions
    end

    def insertions
      stats_provider.insertions
    end

    def stats
      {
        files: stats_provider.files,
        total: stats_provider.total
      }
    end

    # The changes for a single file within a diff
    class DiffFile
      attr_accessor :patch, :path, :mode, :src, :dst, :type

      @base = nil
      NIL_BLOB_REGEXP = /\A0{4,40}\z/

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
        if type == :src && !NIL_BLOB_REGEXP.match(@src)
          @base.object(@src)
        elsif !NIL_BLOB_REGEXP.match(@dst)
          @base.object(@dst)
        end
      end
    end

    private

    def process_full
      return if @full_diff_files

      @full_diff_files = process_full_diff
    end

    def path_status_provider
      @path_status_provider ||= Git::DiffPathStatus.new(@base, @from, @to, @path)
    end

    def stats_provider
      @stats_provider ||= Git::DiffStats.new(@base, @from, @to, @path)
    end

    def process_full_diff
      FullDiffParser.new(@base, patch).parse
    end

    # A private parser class to process the output of `git diff`
    # @api private
    class FullDiffParser
      def initialize(base, patch_text)
        @base = base
        @patch_text = patch_text
        @final_files = {}
        @current_file_data = nil
        @defaults = { mode: '', src: '', dst: '', type: 'modified', binary: false }
      end

      def parse
        @patch_text.split("\n").each { |line| process_line(line) }
        @final_files.map { |filename, data| [filename, DiffFile.new(@base, data)] }
      end

      private

      def process_line(line)
        if (new_file_match = line.match(%r{\Adiff --git ("?)a/(.+?)\1 ("?)b/(.+?)\3\z}))
          start_new_file(new_file_match, line)
        else
          append_to_current_file(line)
        end
      end

      def start_new_file(match, line)
        filename = Git::EscapedPath.new(match[2]).unescape
        @current_file_data = @defaults.merge({ patch: line, path: filename })
        @final_files[filename] = @current_file_data
      end

      def append_to_current_file(line)
        return unless @current_file_data

        parse_index_line(line)
        parse_file_mode_line(line)
        check_for_binary(line)

        @current_file_data[:patch] << "\n#{line}"
      end

      def parse_index_line(line)
        return unless (match = line.match(/^index ([0-9a-f]{4,40})\.\.([0-9a-f]{4,40})( ......)*/))

        @current_file_data[:src] = match[1]
        @current_file_data[:dst] = match[2]
        @current_file_data[:mode] = match[3].strip if match[3]
      end

      def parse_file_mode_line(line)
        return unless (match = line.match(/^([[:alpha:]]*?) file mode (......)/))

        @current_file_data[:type] = match[1]
        @current_file_data[:mode] = match[2]
      end

      def check_for_binary(line)
        @current_file_data[:binary] = true if line.match?(/^Binary files /)
      end
    end
  end
end
