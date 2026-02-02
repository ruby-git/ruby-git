# frozen_string_literal: true

require 'git/commands/arguments'
require 'git/tag_info'

module Git
  module Commands
    module Tag
      # Implements the `git tag --list` command
      #
      # This command lists existing tags with optional filtering and sorting.
      #
      # @see https://git-scm.com/docs/git-tag git-tag
      #
      # @api private
      #
      # @example Basic tag listing
      #   list = Git::Commands::Tag::List.new(execution_context)
      #   tags = list.call
      #
      # @example List tags matching a pattern
      #   list = Git::Commands::Tag::List.new(execution_context)
      #   tags = list.call('v1.*')
      #
      # @example List tags containing a commit
      #   list = Git::Commands::Tag::List.new(execution_context)
      #   tags = list.call(contains: 'abc123')
      #
      # @example List tags with multiple patterns
      #   list = Git::Commands::Tag::List.new(execution_context)
      #   tags = list.call('v1.*', 'v2.*', sort: 'version:refname')
      #
      class List
        # Delimiter for separating fields in git tag --format output
        # Field separator used in custom format output
        # Using the ASCII unit separator (US, 0x1F / "\x1f"), a non-printable character,
        # minimizes the chance of collisions with tag names or messages and remains
        # safe to pass through Process.spawn and shell argument boundaries.
        FIELD_DELIMITER = "\x1f"

        # Number of fields expected in the parsed output
        FIELD_COUNT = 8

        # Format string for git tag --format
        #
        # Fields:
        # - %(refname:short) - tag name
        # - %(objectname) - SHA of the tag object (for annotated) or commit (for lightweight)
        # - %(*objectname) - Dereferenced SHA (commit ID for annotated tags, empty for lightweight)
        # - %(objecttype) - 'tag' for annotated tags, target object type (commit/tree/blob/etc.) for lightweight tags
        # - %(taggername) - tagger name (empty for lightweight tags)
        # - %(taggeremail) - tagger email (empty for lightweight tags)
        # - %(taggerdate:iso8601-strict) - tagger date in strict ISO 8601 format
        # - %(contents:subject) - first line of tag message
        FORMAT_STRING = [
          '%(refname:short)',
          '%(objectname)',
          '%(*objectname)',
          '%(objecttype)',
          '%(taggername)',
          '%(taggeremail)',
          '%(taggerdate:iso8601-strict)',
          '%(contents:subject)'
        ].join(FIELD_DELIMITER)

        # Arguments DSL for building command-line arguments
        #
        # NOTE: The order of definitions here determines the order of arguments
        # in the final command line.
        #
        ARGS = Arguments.define do
          static 'tag'
          static '--list'
          static "--format=#{FORMAT_STRING}"
          value :sort, inline: true, multi_valued: true
          value :contains
          value :no_contains
          value :merged
          value :no_merged
          value :points_at
          positional :patterns, variadic: true
        end.freeze

        # Initialize the List command
        #
        # @param execution_context [Git::ExecutionContext, Git::Lib] the context for executing git commands
        #
        def initialize(execution_context)
          @execution_context = execution_context
        end

        # Execute the git tag --list command
        #
        # @overload call(*patterns, **options)
        #
        #   @param patterns [Array<String>] Shell wildcard patterns to filter tags.
        #     Multiple patterns can be provided; a tag is shown if it matches any pattern.
        #
        #   @param options [Hash] command options
        #
        #   @option options [String, Array<String>] :sort (nil) Sort tags by the specified
        #     key(s). Prefix `-` to sort in descending order. Common keys: 'refname',
        #     '-refname', 'creatordate', '-creatordate', 'version:refname' (for semantic
        #     version sorting).
        #
        #   @option options [String] :contains (nil) List only tags that contain the
        #     specified commit.
        #
        #   @option options [String] :no_contains (nil) List only tags that don't contain
        #     the specified commit.
        #
        #   @option options [String] :merged (nil) List only tags whose commits are
        #     reachable from the specified commit.
        #
        #   @option options [String] :no_merged (nil) List only tags whose commits are
        #     not reachable from the specified commit.
        #
        #   @option options [String] :points_at (nil) List only tags that point at the
        #     specified object.
        #
        # @return [Array<Git::TagInfo>] array of tag info objects
        #
        # @raise [ArgumentError] if unsupported options are provided
        #
        def call(*, **)
          args = ARGS.build(*, **)
          lines = @execution_context.command(*args, raise_on_failure: false).stdout.split("\n")
          parse_tags(lines)
        end

        private

        # Parse the output lines from git tag --format
        #
        # @param lines [Array<String>] output lines from git tag command
        # @return [Array<Git::TagInfo>] parsed tag data
        #
        # @raise [Git::UnexpectedResultError] if any line has unexpected format
        #
        def parse_tags(lines)
          lines.map.with_index { |line, index| parse_tag_line(line, index, lines) }
        end

        # Parse a single formatted tag line
        #
        # The line format is:
        #   name<FS>sha<FS>objecttype<FS>tagger_name<FS>tagger_email<FS>tagger_date<FS>message
        # where <FS> is the unit separator character ("\x1f").
        #
        # For lightweight tags, Git emits empty strings for the tagger fields and message;
        # these are converted to nil by {#parse_optional_field} and {#parse_message}.
        #
        # @param line [String] a single line from git tag --format output
        # @param index [Integer] line index for error reporting
        # @param all_lines [Array<String>] all output lines for error messages
        # @return [Git::TagInfo] tag info with all fields populated
        #
        # @raise [Git::UnexpectedResultError] if line format is unexpected
        #
        def parse_tag_line(line, index, all_lines)
          parts = line.split(FIELD_DELIMITER, FIELD_COUNT)

          unless parts.length == FIELD_COUNT
            raise Git::UnexpectedResultError, unexpected_tag_line_error(all_lines, line, index)
          end

          build_tag_info(parts)
        end

        # Build a TagInfo object from parsed parts
        #
        # @param parts [Array<String>] the parsed format fields
        # @return [Git::TagInfo]
        #
        # @note For annotated tags:
        #   - oid = %(objectname) (the tag object's ID)
        #   - target_oid = %(*objectname) (the dereferenced commit ID)
        #
        # @note For lightweight tags:
        #   - oid = nil (lightweight tags are not objects)
        #   - target_oid = %(objectname) (the commit ID)
        #
        def build_tag_info(parts)
          objecttype = parts[3]
          objectname = parts[1]
          dereferenced = parts[2]

          # For annotated tags: oid is the tag object ID, target_oid is the dereferenced commit
          # For lightweight tags: oid is nil, target_oid is the objectname (the commit)
          if objecttype == 'tag'
            oid = objectname
            target_oid = dereferenced
          else
            oid = nil
            target_oid = objectname
          end

          Git::TagInfo.new(
            name: parts[0],
            oid: oid,
            target_oid: target_oid,
            objecttype: objecttype,
            tagger_name: parse_optional_field(parts[4]),
            tagger_email: parse_optional_field(parts[5]),
            tagger_date: parse_optional_field(parts[6]),
            message: parse_message(objecttype, parts[7])
          )
        end

        # Parse an optional field, returning nil if empty
        def parse_optional_field(value)
          value.empty? ? nil : value
        end

        # Parse message field, returning nil for lightweight tags or empty messages
        def parse_message(objecttype, message)
          objecttype == 'tag' && !message.empty? ? message : nil
        end

        # Generate error message for unexpected tag line format
        #
        # @param lines [Array<String>] all output lines
        # @param line [String] the problematic line
        # @param index [Integer] the line index
        # @return [String] formatted error message
        #
        def unexpected_tag_line_error(lines, line, index)
          format_str = FORMAT_STRING.gsub(FIELD_DELIMITER, '<FS>')
          <<~ERROR
            Unexpected line in output from `git tag --list --format=#{format_str}`, at index #{index}

            Expected #{FIELD_COUNT} fields separated by '\\x1f' (unit separator), got #{line.split(FIELD_DELIMITER, -1).length}

            Full output:
              #{lines.join("\n  ")}

            Line at index #{index}:
              "#{line}"
          ERROR
        end
      end
    end
  end
end
