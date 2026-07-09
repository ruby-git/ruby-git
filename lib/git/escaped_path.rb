# frozen_string_literal: true

module Git
  # Represents an escaped Git path string
  #
  # Git commands that output paths (e.g. ls-files, diff), will escape unusual
  # characters in the path with backslashes in the same way C escapes control
  # characters (e.g. \t for TAB, \n for LF, \\ for backslash) or bytes with values
  # larger than 0x80 (e.g. octal \302\265 for "micro" in UTF-8).
  #
  # @example Decode octal UTF-8 bytes
  #   Git::EscapedPath.new('\302\265').unescape # => "µ"
  #
  # @api private
  #
  class EscapedPath
    # Maps single-character escapes to their decoded byte values
    #
    # @return [Hash<String, Integer>] escape characters mapped to byte values
    UNESCAPES = {
      'a' => 0x07,
      'b' => 0x08,
      't' => 0x09,
      'n' => 0x0a,
      'v' => 0x0b,
      'f' => 0x0c,
      'r' => 0x0d,
      'e' => 0x1b,
      '\\' => 0x5c,
      '"' => 0x22,
      "'" => 0x27
    }.freeze

    # Returns the escaped path as provided by git output
    #
    # @return [String] the escaped path string
    attr_reader :path

    # Initializes an escaped path wrapper
    #
    # @param path [String] the path string with Git-style escape sequences
    #
    # @return [void]
    def initialize(path)
      @path = path
    end

    # Converts an escaped path to an unescaped UTF-8 path
    #
    # @example Decode escaped path output
    #   Git::EscapedPath.new("dir/\\342\\230\\240\\n").unescape
    #   # => "dir/☠\n"
    #
    # @return [String] the decoded path string
    def unescape
      bytes = escaped_path_to_bytes(path)
      str = bytes.pack('C*')
      str.force_encoding(Encoding::UTF_8)
    end

    private

    # Extracts an octal escape sequence starting at the given index
    #
    # @param path [String] the escaped path string
    #
    # @param index [Integer] the index where the sequence starts
    #
    # @return [Array(Integer, Integer)] decoded byte and consumed character count
    def extract_octal(path, index)
      [path[(index + 1)..(index + 3)].to_i(8), 4]
    end

    # Extracts a single-character escape sequence at the given index
    #
    # @param path [String] the escaped path string
    #
    # @param index [Integer] the index where the sequence starts
    #
    # @return [Array(Integer, Integer)] decoded byte and consumed character count
    def extract_escape(path, index)
      [UNESCAPES[path[index + 1]], 2]
    end

    # Extracts a non-escaped character byte at the given index
    #
    # @param path [String] the escaped path string
    #
    # @param index [Integer] the index of the character to decode
    #
    # @return [Array(Integer, Integer)] decoded byte and consumed character count
    def extract_single_char(path, index)
      [path[index].ord, 1]
    end

    # Decodes the next byte from the escaped path at the given index
    #
    # @param path [String] the escaped path string
    #
    # @param index [Integer] the index to decode from
    #
    # @return [Array(Integer, Integer)] decoded byte and consumed character count
    def next_byte(path, index)
      if path[index] == '\\' && path[index + 1] >= '0' && path[index + 1] <= '7'
        extract_octal(path, index)
      elsif path[index] == '\\' && UNESCAPES.include?(path[index + 1])
        extract_escape(path, index)
      else
        extract_single_char(path, index)
      end
    end

    # Converts an escaped path string into decoded bytes
    #
    # @param path [String] the escaped path string
    #
    # @return [Array<Integer>] decoded bytes in order
    def escaped_path_to_bytes(path)
      index = 0
      [].tap do |bytes|
        while index < path.length
          byte, chars_used = next_byte(path, index)
          bytes << byte
          index += chars_used
        end
      end
    end
  end
end
