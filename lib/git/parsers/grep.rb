# frozen_string_literal: true

module Git
  module Parsers
    # Parser for `git grep` output
    #
    # Provides a class method that transforms raw `git grep --null` output into a
    # structured Hash consumed by the `Git::Repository::ObjectOperations` facade.
    #
    # This parser is a pure text transformer with no exit-status logic. The
    # calling facade is responsible for interpreting the command's exit status
    # before delegating output parsing to this class.
    #
    # @api private
    #
    module Grep
      module_function

      # Parse `git grep --line-number --null --no-color` output into a match hash
      #
      # With `--null`, git separates the path and line number fields with NUL
      # bytes: `treeish:filename\0linenum\0text\n`. This keeps filenames that
      # contain `:<digits>:` from being confused with the line-number delimiter.
      #
      # @param output [String] raw output from `git grep --null --line-number`
      #
      # @return [Hash<String, Array<Array(Integer, String)>>] hash mapping
      #   `"treeish:filename"` keys to arrays of `[line_number, text]` pairs
      #
      # @api private
      #
      def parse(output)
        output.each_line.with_object(Hash.new { |h, k| h[k] = [] }) do |line, hsh|
          filename, line_num, text = line.chomp.split("\0", 3)
          next unless text && line_num&.match?(/\A\d+\z/)

          hsh[filename] << [line_num.to_i, text]
        end
      end
    end
  end
end
