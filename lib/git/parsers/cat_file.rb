# frozen_string_literal: true

module Git
  module Parsers
    # Parser for `git cat-file` commit and tag output
    #
    # Provides class methods that transform raw `git cat-file` output lines into
    # structured Hash objects consumed by the `Git::Repository::ObjectOperations`
    # facade.
    #
    # @api private
    #
    module CatFile
      module_function

      # Matches a single `git cat-file` header line
      #
      # @api private
      #
      CAT_FILE_HEADER_LINE = /\A(?<key>\w+) (?<value>.*)\z/

      # Parse `git cat-file commit` output into a structured Hash
      #
      # @param lines [Array<String>] mutable cat-file output lines, consumed
      #   in place during header parsing
      #
      # @param sha [String] the object name passed by the caller
      #
      # @return [Hash] commit data hash with string keys
      #
      # @api private
      #
      def parse_commit(lines, sha)
        headers = parse_commit_headers(lines)
        message = "#{lines.join("\n")}\n"
        { 'sha' => sha, 'message' => message }.merge(headers)
      end

      # Parse `git cat-file tag` output into a structured Hash
      #
      # @param lines [Array<String>] mutable cat-file output lines, consumed
      #   in place during header parsing; remaining lines become the message
      #
      # @param name [String] the tag name passed by the caller
      #
      # @return [Hash] tag data hash with string keys
      #
      # @api private
      #
      def parse_tag(lines, name)
        hsh = { 'name' => name }
        each_header(lines) { |key, value| hsh[key] = value }
        hsh['message'] = "#{lines.join("\n")}\n"
        hsh
      end

      # Extracts and returns commit headers from the front of `lines`
      #
      # Mutates `lines` in place, consuming header lines and the blank
      # separator line. After the call `lines` contains only message lines.
      #
      # @param lines [Array<String>] mutable cat-file output lines
      #
      # @return [Hash] parsed header key/value pairs; `parent` is always
      #   an Array
      #
      # @api private
      #
      def parse_commit_headers(lines)
        headers = { 'parent' => [] }
        each_header(lines) do |key, value|
          if key == 'parent'
            headers['parent'] << value
          else
            headers[key] = value
          end
        end
        headers
      end

      # Yields parsed header key/value pairs from `git cat-file` output lines
      #
      # Consumes header lines from the front of `lines` until a blank line is
      # encountered. Continuation lines that begin with a space are folded
      # into the previous header value using newline separators.
      #
      # @param lines [Array<String>] mutable output lines from a cat-file response
      #
      # @yield [key, value] each parsed header pair
      #
      # @yieldparam key [String] header field name
      #
      # @yieldparam value [String] unfolded header value text
      #
      # @yieldreturn [void]
      #
      # @return [void]
      #
      # @api private
      #
      def each_header(lines)
        while (line = lines.shift) && (match = CAT_FILE_HEADER_LINE.match(line))
          key = match[:key]
          value_lines = [match[:value]]
          value_lines << lines.shift.lstrip while lines.first&.start_with?(' ')
          yield key, value_lines.join("\n")
        end
      end
    end
  end
end
