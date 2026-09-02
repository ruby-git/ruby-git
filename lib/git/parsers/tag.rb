# frozen_string_literal: true

require 'time'

require 'git/author_info'
require 'git/tag_info'
require 'git/tag_delete_result'
require 'git/tag_delete_failure'

module Git
  module Parsers
    # Parser for git tag command output
    #
    # Handles parsing of `git tag --list` and `git tag --delete` output
    # into structured data objects.
    #
    # @note Known limitation: If a tag message contains the field delimiter
    #   character (\x1f, ASCII unit separator), it will be preserved correctly
    #   since the message is the last field. However, messages are rarely crafted
    #   with non-printable control characters.
    #
    # ## Design Note: Namespace Organization
    #
    # This parser creates and returns {Git::TagInfo} and {Git::TagDeleteResult}
    # objects, which live at the top-level `Git::` namespace rather than within
    # `Git::Parsers::`. This is intentional:
    #
    # - **Parsers are infrastructure** - marked `@api private`, users shouldn't
    #   interact with them directly
    # - **Info/Result classes are public API** - returned by commands and used
    #   throughout the codebase
    # - **Info classes are domain entities** - represent core git concepts
    #   (tags as data)
    # - **Result classes are operation outcomes** - represent command results,
    #   not parsing details
    #
    # Keeping Info/Result classes at `Git::` improves discoverability and correctly
    # reflects their role as public types rather than parser internals.
    #
    # @api private
    #
    module Tag
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

      # Regex to parse successful deletion lines from stdout
      # Matches: Deleted tag 'tagname' (was abc123)
      DELETED_TAG_REGEX = /^Deleted tag '([^']+)'/

      # Regex to parse error messages from stderr
      # Matches: error: tag 'tagname' not found.
      ERROR_TAG_REGEX = /^error: tag '([^']+)'(.*)$/

      module_function

      # Parse git tag --list output into TagInfo objects
      #
      # @example
      #   TagParser.parse_list("v1.0.0\x1f...\x1e\n")
      #   # => [#<Git::TagInfo name: "v1.0.0", ...>]
      #
      # @param stdout [String] output from git tag --list --format=...
      #
      # @return [Array<Git::TagInfo>] parsed tag information
      #
      # @raise [Git::UnexpectedResultError] if any record has unexpected format
      #
      def parse_list(stdout)
        # Split by record separator
        # Each record may have a leading newline from the previous record's %(contents) output
        # Use lstrip to remove leading whitespace (which includes the newline) from each record
        records = stdout.split(RECORD_DELIMITER).map(&:lstrip).reject(&:empty?)
        records.map.with_index { |record, index| parse_tag_record(record, index, records) }
      end

      # Parse a single formatted tag record
      #
      # The record format is:
      #   name<FS>sha<FS>deref<FS>objecttype<FS>tagger_name<FS>tagger_email<FS>tagger_date<FS>message
      # where <FS> is the unit separator character ("\x1f").
      #
      # For lightweight tags, Git emits empty strings for the tagger fields and message;
      # these are converted to nil by {#parse_tagger} and {#parse_message}.
      #
      # @param record [String] a single tag record from git tag --format output
      #
      # @param index [Integer] record index for error reporting
      #
      # @param all_records [Array<String>] all output records for error messages
      #
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
      #
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
        oid, target_oid = resolve_oids(parts[3], parts[1], parts[2])
        build_tag_info_object(parts, oid, target_oid)
      end

      # Resolves canonical and target object OIDs from git tag format fields
      #
      # @param objecttype [String] the object type from git output
      #
      # @param objectname [String] the object OID from %(objectname)
      #
      # @param dereferenced [String] the object OID from %(*objectname)
      #
      # @return [Array((String, nil), String)] the two-element tuple
      #   `[oid, target_oid]`
      #
      def resolve_oids(objecttype, objectname, dereferenced)
        objecttype == 'tag' ? [objectname, dereferenced] : [nil, objectname]
      end

      # Builds a TagInfo object from normalized parser values
      #
      # @param parts [Array<String>] the parsed format fields
      #
      # @param oid [String, nil] the tag object's OID or nil for lightweight tags
      #
      # @param target_oid [String] the target object OID
      #
      # @return [Git::TagInfo] the tag info with all fields populated
      #
      def build_tag_info_object(parts, oid, target_oid)
        Git::TagInfo.new(
          name: parts[0], oid: oid, target_oid: target_oid, objecttype: parts[3],
          tagger: parse_tagger(parts[4], parts[5], parts[6]), message: parse_message(parts[3], parts[7])
        )
      end

      # Build the tagger identity from the tagger name, email, and date fields
      #
      # Git emits empty strings for all three fields when there is no tag object
      # (lightweight tags) or the tag object has no tagger header, in which case
      # the tagger is nil. Otherwise the angle brackets git wraps around
      # `%(taggeremail)` are stripped and the strict ISO 8601
      # `%(taggerdate:iso8601-strict)` value is parsed into a `Time` that
      # preserves the UTC offset. A partially populated identity (for example an
      # empty name with an email and date) is kept as emitted rather than dropped,
      # and an empty date becomes `nil`.
      #
      # @example An annotated tag's tagger
      #   parse_tagger('John Doe', '<john@example.com>', '2024-01-15T10:30:00-08:00')
      #   #=> #<data Git::AuthorInfo name="John Doe", email="john@example.com", ...>
      #
      # @example A lightweight tag has no tagger
      #   parse_tagger('', '', '') #=> nil
      #
      # @param name [String] the `%(taggername)` field
      #
      # @param email [String] the `%(taggeremail)` field, including angle brackets
      #
      # @param date [String] the `%(taggerdate:iso8601-strict)` field
      #
      # @return [Git::AuthorInfo, nil] the tagger, or nil when all three fields are empty
      #
      # @raise [Git::UnexpectedResultError] if a non-empty date is not a valid ISO 8601
      #   date
      #
      def parse_tagger(name, email, date)
        return nil if [name, email, date].all?(&:empty?)

        Git::AuthorInfo.new(
          name: name,
          email: email.delete_prefix('<').delete_suffix('>'),
          date: date.empty? ? nil : parse_date(date)
        )
      end

      # Parse a `%(taggerdate:iso8601-strict)` field into a Time
      #
      # @param date [String] the date field in strict ISO 8601 format
      #
      # @return [Time] the parsed time, preserving the UTC offset
      #
      # @raise [Git::UnexpectedResultError] if the field is not a valid ISO 8601 date
      #
      def parse_date(date)
        Time.iso8601(date)
      rescue ArgumentError => e
        raise Git::UnexpectedResultError,
              "Unexpected tagger date #{date.inspect} in output from `git tag --list`: #{e.message}"
      end

      # Parse message field, returning nil for lightweight tags or empty messages
      # Strips trailing newlines that git adds to %(contents) output
      #
      # @param objecttype [String] the object type ('tag' or 'commit')
      #
      # @param message [String] the raw message field
      #
      # @return [String, nil] the message or nil
      #
      def parse_message(objecttype, message)
        stripped = message.chomp
        objecttype == 'tag' && !stripped.empty? ? stripped : nil
      end

      # Parse deleted tag names from stdout
      #
      # @example
      #   TagParser.parse_deleted_tags("Deleted tag 'v1.0.0' (was abc123)\n")
      #   # => ["v1.0.0"]
      #
      # @param stdout [String] command stdout
      #
      # @return [Array<String>] names of successfully deleted tags
      #
      def parse_deleted_tags(stdout)
        stdout.scan(DELETED_TAG_REGEX).flatten
      end

      # Parse error messages from stderr into a map
      #
      # @example
      #   TagParser.parse_error_messages("error: tag 'missing' not found.\n")
      #   # => {"missing" => "error: tag 'missing' not found."}
      #
      # @param stderr [String] command stderr
      #
      # @return [Hash<String, String>] map of tag name to error message
      #
      def parse_error_messages(stderr)
        stderr.each_line.with_object({}) do |line, hash|
          match = line.match(ERROR_TAG_REGEX)
          hash[match[1]] = line.strip if match
        end
      end

      # Build the TagDeleteResult from parsed data
      #
      # @param requested_names [Array<String>] originally requested tag names
      #
      # @param existing_tags [Hash<String, Git::TagInfo>] tags that existed before delete
      #
      # @param deleted_names [Array<String>] names confirmed deleted in stdout
      #
      # @param error_map [Hash<String, String>] map of tag name to error message
      #
      # @return [Git::TagDeleteResult] the result object
      #
      def build_delete_result(requested_names, existing_tags, deleted_names, error_map)
        deleted = deleted_names.filter_map { |name| existing_tags[name] }

        not_deleted = (requested_names - deleted_names).map do |name|
          error_message = error_map[name] || "tag '#{name}' could not be deleted"
          Git::TagDeleteFailure.new(name: name, error_message: error_message)
        end

        Git::TagDeleteResult.new(deleted: deleted, not_deleted: not_deleted)
      end

      # Generate error message for unexpected tag record format
      #
      # @param records [Array<String>] all output records
      #
      # @param record [String] the problematic record
      #
      # @param index [Integer] the record index
      #
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
