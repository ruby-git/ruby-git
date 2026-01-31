# frozen_string_literal: true

require 'git/diff_result'
require 'git/diff_file_numstat_info'
require 'git/diff_file_raw_info'
require 'git/diff_file_patch_info'
require 'git/dirstat_info'

module Git
  # Parser for git diff output in various formats
  #
  # Handles parsing of --numstat, --shortstat, --dirstat, --raw, and --patch output.
  # This parser is used by stash show, diff, show, and log commands.
  #
  # @note Combined/merge diffs (e.g., from `git diff --cc` or `git show <merge>`) are not
  #   supported. These have a different format with multiple +/- columns per parent.
  #
  # @api private
  #
  module DiffParser
    # Status letter to symbol mapping for --raw output
    STATUS_MAP = {
      'A' => :added,
      'M' => :modified,
      'D' => :deleted,
      'R' => :renamed,
      'C' => :copied,
      'T' => :type_changed
    }.freeze

    # Null SHA for non-existent files
    NULL_SHA = '0' * 7

    # Null mode for non-existent files
    NULL_MODE = '000000'

    # Rename format patterns from git numstat -M output:
    #   old_name.rb => new_name.rb
    #   \\{old_dir => new_dir}/file.rb
    #   dir/\\{old_name.rb => new_name.rb}
    RENAME_PATTERN = /\A(.+) => (.+)\z/
    BRACE_RENAME_PATTERN = /\A(.*)\{(.+) => (.+)\}(.*)\z/

    module_function

    # Build a DiffResult from parsed components
    #
    # @param files [Array] array of file info objects
    # @param shortstat [Hash] parsed shortstat data
    # @param dirstat [Git::DirstatInfo, nil] parsed dirstat data
    # @return [Git::DiffResult]
    #
    def build_result(files:, shortstat:, dirstat:)
      Git::DiffResult.new(
        files_changed: shortstat[:files_changed],
        total_insertions: shortstat[:insertions],
        total_deletions: shortstat[:deletions],
        files: files,
        dirstat: dirstat
      )
    end

    # Build an empty DiffResult
    #
    # @return [Git::DiffResult]
    #
    def empty_result
      Git::DiffResult.new(
        files_changed: 0, total_insertions: 0, total_deletions: 0,
        files: [], dirstat: nil
      )
    end

    # Parse shortstat line into components
    #
    # @example
    #   parse_shortstat(" 3 files changed, 10 insertions(+), 5 deletions(-)")
    #   # => { files_changed: 3, insertions: 10, deletions: 5 }
    #
    # @param line [String, nil] the shortstat line
    # @return [Hash] { files_changed:, insertions:, deletions: }
    #
    def parse_shortstat(line)
      return { files_changed: 0, insertions: 0, deletions: 0 } if line.nil?

      {
        files_changed: line.match(/(\d+)\s+files?\s+changed/)&.[](1).to_i,
        insertions: line.match(/(\d+)\s+insertions?\(\+\)/)&.[](1).to_i,
        deletions: line.match(/(\d+)\s+deletions?\(-\)/)&.[](1).to_i
      }
    end

    # Parse dirstat lines into DirstatInfo
    #
    # @example
    #   parse_dirstat(["  50.0% lib/", "  50.0% spec/"])
    #   # => #<Git::DirstatInfo entries: [...]>
    #
    # @param lines [Array<String>] dirstat output lines
    # @return [Git::DirstatInfo]
    #
    def parse_dirstat(lines)
      entries = lines.filter_map do |line|
        next unless (match = line.match(/^\s*([\d.]+)%\s+(.+)$/))

        Git::DirstatEntry.new(percentage: match[1].to_f, directory: match[2])
      end
      Git::DirstatInfo.new(entries: entries)
    end

    # Parse a stat value (handles '-' for binary files)
    #
    # @param value [String] the stat value string
    # @return [Integer] the numeric value (0 for binary files)
    #
    def parse_stat_value(value)
      value == '-' ? 0 : value.to_i
    end

    # Unescape quoted path from git output
    #
    # @param path [String] potentially quoted path
    # @return [String] unescaped path
    #
    def unescape_path(path)
      return path unless path&.start_with?('"') && path.end_with?('"')

      Git::EscapedPath.new(path[1..-2]).unescape
    end

    # Parser for --numstat output
    module Numstat
      module_function

      # Parse numstat output into DiffResult
      #
      # @param output [String] raw numstat + shortstat output
      # @param include_dirstat [Boolean] whether dirstat output is expected
      # @return [Git::DiffResult]
      #
      def parse(output, include_dirstat: false)
        lines = output.split("\n").reject(&:empty?)
        numstat_lines, shortstat_line, dirstat_lines = split_sections(lines, include_dirstat)

        DiffParser.build_result(
          files: parse_file_stats(numstat_lines),
          shortstat: DiffParser.parse_shortstat(shortstat_line),
          dirstat: include_dirstat ? DiffParser.parse_dirstat(dirstat_lines) : nil
        )
      end

      # Parse numstat lines into DiffFileNumstatInfo array
      #
      # @param lines [Array<String>] numstat lines
      # @return [Array<Git::DiffFileNumstatInfo>]
      #
      def parse_file_stats(lines)
        lines.map do |line|
          insertions_s, deletions_s, filename = line.split("\t", 3)
          path, src_path = parse_rename_path(filename)
          Git::DiffFileNumstatInfo.new(
            path: DiffParser.unescape_path(path),
            src_path: src_path ? DiffParser.unescape_path(src_path) : nil,
            insertions: DiffParser.parse_stat_value(insertions_s),
            deletions: DiffParser.parse_stat_value(deletions_s)
          )
        end
      end

      # Parse numstat lines into a path -> stats hash (for combining with other formats)
      #
      # @param lines [Array<String>] numstat lines
      # @param include_binary [Boolean] whether to include binary flag
      # @return [Hash<String, Hash>] path to stats mapping (keyed by destination path)
      #
      def parse_as_map(lines, include_binary: false)
        lines.to_h do |line|
          insertions_s, deletions_s, filename = line.split("\t", 3)
          # Normalize rename paths so the key matches the dst_path used by raw/patch parsers
          dst_path, _src_path = parse_rename_path(filename)
          [DiffParser.unescape_path(dst_path), build_stats(insertions_s, deletions_s, include_binary)]
        end
      end

      def build_stats(insertions_s, deletions_s, include_binary)
        stats = { insertions: DiffParser.parse_stat_value(insertions_s),
                  deletions: DiffParser.parse_stat_value(deletions_s) }
        stats[:binary] = (insertions_s == '-' && deletions_s == '-') if include_binary
        stats
      end

      # Split output into numstat, shortstat, and dirstat sections
      #
      # @param lines [Array<String>] all output lines
      # @param include_dirstat [Boolean] whether to expect dirstat section
      # @return [Array] [numstat_lines, shortstat_line, dirstat_lines]
      #
      def split_sections(lines, include_dirstat)
        shortstat_index = lines.index { |l| l.match?(/^\s*\d+\s+files?\s+changed/) }
        return [lines, nil, []] unless shortstat_index

        [lines[0...shortstat_index], lines[shortstat_index],
         include_dirstat ? lines[(shortstat_index + 1)..] : []]
      end

      # Parse potential rename path into [dst_path, src_path]
      #
      # @param filename [String] the path string from numstat output
      # @return [Array<String, String|nil>] [destination_path, source_path_or_nil]
      #
      def parse_rename_path(filename)
        if (match = filename.match(BRACE_RENAME_PATTERN))
          prefix, old_part, new_part, suffix = match.captures
          ["#{prefix}#{new_part}#{suffix}", "#{prefix}#{old_part}#{suffix}"]
        elsif (match = filename.match(RENAME_PATTERN))
          [match[2], match[1]]
        else
          [filename, nil]
        end
      end
    end

    # Parser for --raw output (combined with numstat)
    module Raw
      module_function

      # Parse combined raw + numstat + shortstat output into DiffResult
      #
      # @param output [String] combined output
      # @param include_dirstat [Boolean] whether dirstat output is expected
      # @return [Git::DiffResult]
      #
      def parse(output, include_dirstat: false)
        raw_lines, numstat_lines, shortstat_line, dirstat_lines = split_sections(output, include_dirstat)
        numstat_map = Numstat.parse_as_map(numstat_lines, include_binary: true)

        DiffParser.build_result(
          files: raw_lines.map { |line| parse_raw_line(line, numstat_map) },
          shortstat: DiffParser.parse_shortstat(shortstat_line),
          dirstat: include_dirstat ? DiffParser.parse_dirstat(dirstat_lines) : nil
        )
      end

      # Split output into raw, numstat, shortstat, and dirstat sections
      #
      # @param output [String] combined output
      # @param include_dirstat [Boolean] whether to expect dirstat section
      # @return [Array<Array<String>, Array<String>, String|nil, Array<String>>]
      #
      def split_sections(output, include_dirstat)
        lines = output.split("\n").reject(&:empty?)
        raw_lines = lines.select { |l| l.start_with?(':') }
        non_raw_lines = lines.reject { |l| l.start_with?(':') }
        shortstat_index = non_raw_lines.index { |l| l.match?(/^\s*\d+\s+files?\s+changed/) }

        return [raw_lines, non_raw_lines, nil, []] unless shortstat_index

        [raw_lines, non_raw_lines[0...shortstat_index], non_raw_lines[shortstat_index],
         include_dirstat ? non_raw_lines[(shortstat_index + 1)..] : []]
      end

      # Parse a single --raw output line
      #
      # @param line [String] a single raw output line
      # @param numstat_map [Hash<String, Hash>] path to stats mapping
      # @return [Git::DiffFileRawInfo]
      #
      def parse_raw_line(line, numstat_map)
        parsed = parse_raw_line_parts(line)
        stats = numstat_map.fetch(parsed[:dst_path] || parsed[:src_path],
                                  { insertions: 0, deletions: 0, binary: false })
        build_raw_info(parsed, stats)
      end

      def parse_raw_line_parts(line)
        parts = line[1..].split(/\s+/, 5)
        status_char, *paths = parts[4].split("\t")
        status, similarity = parse_status(status_char)
        src_path, dst_path = extract_paths(paths)
        { modes: parts[0..1], shas: parts[2..3], status: status,
          similarity: similarity, src_path: src_path, dst_path: dst_path }
      end

      def build_raw_info(parsed, stats)
        Git::DiffFileRawInfo.new(
          src: build_file_ref(parsed[:modes][0], parsed[:shas][0], parsed[:src_path]),
          dst: build_file_ref(parsed[:modes][1], parsed[:shas][1], parsed[:dst_path]),
          status: parsed[:status], similarity: parsed[:similarity], **stats
        )
      end

      # Parse status character and optional similarity percentage
      #
      # @param status_char [String] e.g., 'M', 'A', 'R075'
      # @return [Array<Symbol, Integer|nil>] [status, similarity]
      #
      def parse_status(status_char)
        letter = status_char[0]
        similarity = status_char.length > 1 ? status_char[1..].to_i : nil
        [STATUS_MAP.fetch(letter, :unknown), similarity]
      end

      # Extract source and destination paths from raw output paths
      #
      # @param paths [Array<String>] paths array
      # @return [Array<String|nil, String|nil>] [src_path, dst_path]
      #
      def extract_paths(paths)
        if paths.length == 2
          [DiffParser.unescape_path(paths[0]), DiffParser.unescape_path(paths[1])]
        else
          path = DiffParser.unescape_path(paths[0])
          [path, path]
        end
      end

      # Build a FileRef, returning nil if the file doesn't exist on this side
      #
      # @param mode [String] file mode
      # @param sha [String] file SHA
      # @param path [String, nil] file path
      # @return [Git::FileRef, nil]
      #
      def build_file_ref(mode, sha, path)
        return nil if mode == NULL_MODE || path.nil?

        Git::FileRef.new(mode: mode, sha: sha, path: path)
      end
    end

    # Parser for --patch output (combined with numstat)
    module Patch
      DIFF_HEADER_PATTERN = %r{\Adiff --git ("?)a/(.+?)\1 ("?)b/(.+?)\3\z}
      INDEX_PATTERN = /^index ([0-9a-f]{4,40})\.\.([0-9a-f]{4,40})( ......)?/
      FILE_MODE_PATTERN = /^(new|deleted) file mode (......)/
      OLD_MODE_PATTERN = /^old mode (......)/
      NEW_MODE_PATTERN = /^new mode (......)/
      BINARY_PATTERN = /^Binary files /
      GIT_BINARY_PATCH_PATTERN = /^GIT binary patch$/
      RENAME_FROM_PATTERN = /^rename from (.+)$/
      RENAME_TO_PATTERN = /^rename to (.+)$/
      COPY_FROM_PATTERN = /^copy from (.+)$/
      COPY_TO_PATTERN = /^copy to (.+)$/
      SIMILARITY_PATTERN = /^similarity index (\d+)%$/

      PATCH_STATUS_MAP = {
        'new' => :added,
        'deleted' => :deleted,
        'modified' => :modified,
        'renamed' => :renamed,
        'copied' => :copied,
        'type_changed' => :type_changed
      }.freeze

      module_function

      # Parse combined patch + numstat + shortstat output into DiffResult
      #
      # @param output [String] combined output
      # @param include_dirstat [Boolean] whether dirstat output is expected
      # @return [Git::DiffResult]
      #
      def parse(output, include_dirstat: false)
        return DiffParser.empty_result if output.empty?

        numstat_lines, shortstat_line, dirstat_lines, patch_text = split_sections(output, include_dirstat)
        numstat_map = Numstat.parse_as_map(numstat_lines)

        DiffParser.build_result(
          files: PatchFileParser.new(patch_text, numstat_map).parse,
          shortstat: DiffParser.parse_shortstat(shortstat_line),
          dirstat: include_dirstat ? DiffParser.parse_dirstat(dirstat_lines) : nil
        )
      end

      # Split output into numstat, shortstat, dirstat, and patch sections
      #
      # @param output [String] combined output
      # @param include_dirstat [Boolean] whether to expect dirstat section
      # @return [Array<Array<String>, String|nil, Array<String>, String>]
      #
      def split_sections(output, include_dirstat)
        lines = output.lines
        first_diff_index = lines.index { |l| l.start_with?('diff --git') } || lines.length
        pre_diff_lines = lines[0...first_diff_index].map(&:chomp).reject(&:empty?)
        patch_text = lines[first_diff_index..].join
        split_pre_diff(pre_diff_lines, include_dirstat, patch_text)
      end

      def split_pre_diff(pre_diff_lines, include_dirstat, patch_text)
        shortstat_index = pre_diff_lines.index { |l| l.match?(/^\s*\d+\s+files?\s+changed/) }
        return [pre_diff_lines, nil, [], patch_text] unless shortstat_index

        [pre_diff_lines[0...shortstat_index], pre_diff_lines[shortstat_index],
         include_dirstat ? pre_diff_lines[(shortstat_index + 1)..] : [], patch_text]
      end

      # Methods for parsing patch metadata lines (index, mode, rename, etc.)
      # @api private
      module PatchMetadataParser
        private

        def parse_metadata_line(line)
          try_parse_index(line)
          try_parse_file_mode(line)
          try_parse_old_new_mode(line)
          try_parse_rename(line)
          try_parse_similarity(line)
          try_mark_binary(line)
        end

        def try_parse_index(line)
          return unless (match = line.match(INDEX_PATTERN))

          @current_file[:src_sha] = match[1]
          @current_file[:dst_sha] = match[2]
          return unless (mode = match[3]&.strip)
          return unless @current_file[:src_mode].nil? && @current_file[:dst_mode].nil?

          @current_file[:src_mode] = @current_file[:dst_mode] = mode
        end

        def try_parse_file_mode(line)
          return unless (match = line.match(FILE_MODE_PATTERN))

          type, mode = match.captures
          @current_file[:status] = PATCH_STATUS_MAP.fetch(type, :modified)
          apply_file_mode(type, mode)
        end

        def try_parse_old_new_mode(line)
          if (match = line.match(OLD_MODE_PATTERN))
            @current_file[:src_mode] = match[1]
            detect_type_change
          elsif (match = line.match(NEW_MODE_PATTERN))
            @current_file[:dst_mode] = match[1]
            detect_type_change
          end
        end

        def detect_type_change
          src_mode = @current_file[:src_mode]
          dst_mode = @current_file[:dst_mode]
          return unless src_mode && dst_mode

          # Type change occurs when the file type bits differ (e.g., 100644 vs 120000)
          # The first 3 digits represent the file type
          @current_file[:status] = :type_changed if src_mode[0, 3] != dst_mode[0, 3]
        end

        def apply_file_mode(type, mode)
          case type
          when 'new'
            @current_file[:dst_mode] = mode
            @current_file[:src_path] = nil
          when 'deleted'
            @current_file[:src_mode] = mode
            @current_file[:dst_path] = nil
          end
        end

        def try_parse_rename(line)
          try_parse_rename_or_copy(line, RENAME_FROM_PATTERN, RENAME_TO_PATTERN, :renamed) ||
            try_parse_rename_or_copy(line, COPY_FROM_PATTERN, COPY_TO_PATTERN, :copied)
        end

        def try_parse_rename_or_copy(line, from_pattern, to_pattern, status)
          if (match = line.match(from_pattern))
            @current_file[:src_path] = DiffParser.unescape_path(match[1])
            @current_file[:status] = status
          elsif (match = line.match(to_pattern))
            @current_file[:dst_path] = DiffParser.unescape_path(match[1])
            @current_file[:status] = status
          end
        end

        def try_parse_similarity(line)
          return unless (match = line.match(SIMILARITY_PATTERN))

          @current_file[:similarity] = match[1].to_i
        end

        def try_mark_binary(line)
          @current_file[:binary] = true if line.match?(BINARY_PATTERN) || line.match?(GIT_BINARY_PATCH_PATTERN)
        end
      end

      # Stateful parser for unified diff patch output
      # @api private
      class PatchFileParser
        include PatchMetadataParser

        def initialize(patch_text, numstat_map = {})
          @patch_text = patch_text
          @numstat_map = numstat_map
          @files = []
          @current_file = nil
        end

        def parse
          @patch_text.split("\n").each { |line| process_line(line) }
          finalize_current_file
          @files
        end

        private

        def process_line(line)
          if (match = line.match(DIFF_HEADER_PATTERN))
            start_new_file(match, line)
          elsif @current_file
            append_to_current_file(line)
          end
        end

        def start_new_file(match, line)
          finalize_current_file
          @current_file = default_file_state.merge(
            patch: line,
            src_path: Git::EscapedPath.new(match[2]).unescape,
            dst_path: Git::EscapedPath.new(match[4]).unescape
          )
        end

        def default_file_state
          { src_mode: nil, dst_mode: nil, src_sha: '', dst_sha: '',
            src_path: nil, dst_path: nil, status: :modified, similarity: nil, binary: false }
        end

        def append_to_current_file(line)
          parse_metadata_line(line)
          @current_file[:patch] = "#{@current_file[:patch]}\n#{line}"
        end

        def finalize_current_file
          return unless @current_file

          @files << build_patch_info
          @current_file = nil
        end

        def build_patch_info
          path = @current_file[:dst_path] || @current_file[:src_path]
          stats = @numstat_map.fetch(path, { insertions: 0, deletions: 0 })

          Git::DiffFilePatchInfo.new(
            src: build_file_ref(:src), dst: build_file_ref(:dst),
            patch: @current_file[:patch], status: @current_file[:status],
            similarity: @current_file[:similarity], binary: @current_file[:binary],
            insertions: stats[:insertions], deletions: stats[:deletions]
          )
        end

        def build_file_ref(side)
          path = @current_file[:"#{side}_path"]
          return nil if path.nil?

          Git::FileRef.new(
            mode: @current_file[:"#{side}_mode"] || '',
            sha: @current_file[:"#{side}_sha"] || '',
            path: path
          )
        end
      end
    end
  end
end
