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

        # Delimiter for separating records (tags) in output
        # Using the ASCII record separator (RS, 0x1E / "\x1e") to delimit complete tag records.
        # This allows multi-line messages (which contain newlines) to be parsed correctly
        # since we split by record separator first, then by field delimiter.
        RECORD_DELIMITER = "\x1e"

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
        # - %(contents) - full tag message (can be multi-line)
        #
        # Each tag record is terminated by the RECORD_DELIMITER to allow multi-line messages.
        FORMAT_STRING = [
          '%(refname:short)',
          '%(objectname)',
          '%(*objectname)',
          '%(objecttype)',
          '%(taggername)',
          '%(taggeremail)',
          '%(taggerdate:iso8601-strict)',
          '%(contents)'
        ].join(FIELD_DELIMITER) + RECORD_DELIMITER

        # Arguments DSL for building command-line arguments
        #
        # NOTE: The order of definitions here determines the order of arguments
        # in the final command line.
        #
        ARGS = Arguments.define do
          literal 'tag'
          literal '--list'
          literal "--format=#{FORMAT_STRING}"
          value_option :sort, inline: true, repeatable: true
          flag_or_value_option :contains, inline: true
          flag_or_value_option :no_contains, inline: true
          flag_or_value_option :merged, inline: true
          flag_or_value_option :no_merged, inline: true
          flag_or_value_option :points_at, inline: true
          flag_option %i[ignore_case i]
          operand :patterns, repeatable: true
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
        #   @option options [Boolean, String] :contains (nil) List only tags that contain the
        #     specified commit. Pass `true` to use HEAD, or a commit reference string.
        #
        #   @option options [Boolean, String] :no_contains (nil) List only tags that don't contain
        #     the specified commit. Pass `true` to use HEAD, or a commit reference string.
        #
        #   @option options [Boolean, String] :merged (nil) List only tags whose commits are
        #     reachable from the specified commit. Pass `true` to use HEAD, or a commit reference string.
        #
        #   @option options [Boolean, String] :no_merged (nil) List only tags whose commits are
        #     not reachable from the specified commit. Pass `true` to use HEAD, or a commit reference string.
        #
        #   @option options [Boolean, String] :points_at (nil) List only tags that point at the
        #     specified object. Pass `true` to use HEAD, or an object reference string.
        #
        #   @option options [Boolean] :ignore_case (nil) Sorting and filtering tags are
        #     case insensitive. Alias: `:i`
        #
        # @return [Array<Git::TagInfo>] array of tag info objects
        #
        # @raise [ArgumentError] if unsupported options are provided
        #
        def call(*, **)
          args = ARGS.bind(*, **)
          output = @execution_context.command(*args, raise_on_failure: false).stdout
          # Split by record separator
          # Each record may have a leading newline from the previous record's %(contents) output
          # Use lstrip to remove leading whitespace (which includes the newline) from each record
          records = output.split(RECORD_DELIMITER).map(&:lstrip).reject(&:empty?)
          parse_tags(records)
        end

        private

        # Parse the tag records from git tag --format output
        #
        # @param records [Array<String>] tag records from git tag command (split by record separator)
        # @return [Array<Git::TagInfo>] parsed tag data
        #
        # @raise [Git::UnexpectedResultError] if any record has unexpected format
        #
        def parse_tags(records)
          records.map.with_index { |record, index| parse_tag_record(record, index, records) }
        end

        # Parse a single formatted tag record
        #
        # The record format is:
        #   name<FS>sha<FS>deref<FS>objecttype<FS>tagger_name<FS>tagger_email<FS>tagger_date<FS>message
        # where <FS> is the unit separator character ("\x1f").
        #
        # For lightweight tags, Git emits empty strings for the tagger fields and message;
        # these are converted to nil by {#parse_optional_field} and {#parse_message}.
        #
        # @param record [String] a single tag record from git tag --format output
        # @param index [Integer] record index for error reporting
        # @param all_records [Array<String>] all output records for error messages
        # @return [Git::TagInfo] tag info with all fields populated
        #
        # @raise [Git::UnexpectedResultError] if record format is unexpected
        #
        def parse_tag_record(record, index, all_records)
          parts = record.split(FIELD_DELIMITER, FIELD_COUNT)

          unless parts.length == FIELD_COUNT
            raise Git::UnexpectedResultError, unexpected_tag_record_error(all_records, record, index)
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
        # Strips trailing newlines that git adds to %(contents) output
        def parse_message(objecttype, message)
          stripped = message.chomp
          objecttype == 'tag' && !stripped.empty? ? stripped : nil
        end

        # Generate error message for unexpected tag record format
        #
        # @param records [Array<String>] all output records
        # @param record [String] the problematic record
        # @param index [Integer] the record index
        # @return [String] formatted error message
        #
        def unexpected_tag_record_error(records, record, index)
          format_str = FORMAT_STRING.gsub(FIELD_DELIMITER, '<FS>').gsub(RECORD_DELIMITER, '<RS>')
          <<~ERROR
            Unexpected record in output from `git tag --list --format=#{format_str}`, at index #{index}

            Expected #{FIELD_COUNT} fields separated by '\\x1f' (unit separator), got #{record.split(FIELD_DELIMITER, -1).length}

            Full output:
              #{records.join("\n  ")}

            Record at index #{index}:
              "#{record}"
          ERROR
        end
      end
    end
  end
end
