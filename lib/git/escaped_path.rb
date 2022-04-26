# frozen_string_literal: true

module Git
  # Represents an escaped Git path string
  #
  # Git commands that output paths (e.g. ls-files, diff), will escape usual
  # characters in the path with backslashes in the same way C escapes control
  # characters (e.g. \t for TAB, \n for LF, \\ for backslash) or bytes with values
  # larger than 0x80 (e.g. octal \302\265 for "micro" in UTF-8).
  #
  # @example
  #   Git::GitPath.new('\302\265').unescape # => "µ"
  #
  class EscapedPath
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

    attr_reader :path

    def initialize(path)
      @path = path
    end

    # Convert an escaped path to an unescaped path
    def unescape
      bytes = escaped_path_to_bytes(path)
      str = bytes.pack('C*')
      str.force_encoding(Encoding::UTF_8)
    end

    private

    def extract_octal(path, index)
      [path[index + 1..index + 4].to_i(8), 4]
    end

    def extract_escape(path, index)
      [UNESCAPES[path[index + 1]], 2]
    end

    def extract_single_char(path, index)
      [path[index].ord, 1]
    end

    def next_byte(path, index)
      if path[index] == '\\' && path[index + 1] >= '0' && path[index + 1] <= '7'
        extract_octal(path, index)
      elsif path[index] == '\\' && UNESCAPES.include?(path[index + 1])
        extract_escape(path, index)
      else
        extract_single_char(path, index)
      end
    end

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
