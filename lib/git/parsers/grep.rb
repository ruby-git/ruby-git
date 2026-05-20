# frozen_string_literal: true

module Git
  module Parsers
    # Parser for `git grep` output
    #
    # Provides a class method that transforms raw `git grep` output lines into
    # a structured Hash consumed by the `Git::Repository::ObjectOperations`
    # facade.
    #
    # This parser is a pure text transformer with no exit-status logic. The
    # calling facade is responsible for interpreting the command's exit status
    # before delegating output parsing to this class.
    #
    # @api private
    #
    module Grep
      module_function

      # Parse `git grep --line-number --no-color` output lines into a match hash
      #
      # Each line is expected in the format produced by
      # `git grep --line-number --no-color`: `treeish:filename:linenum:text`.
      #
      # @param lines [Array<String>] output lines from `git grep`
      #
      # @return [Hash<String, Array<Array(Integer, String)>>] hash mapping
      #   `"treeish:filename"` keys to arrays of `[line_number, text]` pairs
      #
      # @api private
      #
      def parse(lines)
        lines.each_with_object(Hash.new { |h, k| h[k] = [] }) do |line, hsh|
          filename, line_num, text = parse_line(line)
          next unless filename && line_num && text

          hsh[filename] << [line_num.to_i, text]
        end
      end

      def parse_line(line)
        return line.split("\0", 3) if line.include?("\0")

        parse_colon_delimited_line(line)
      end

      def parse_colon_delimited_line(line)
        match = line.match(/\A(.*?):(\d+):(.*)/)
        return unless match

        _full, filename, line_num, text = match.to_a
        [filename, line_num, text]
      end
    end
  end
end
