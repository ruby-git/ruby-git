# frozen_string_literal: true

require 'git/errors'
require 'git/status_file_info'

module Git
  module Parsers
    # Parser for `git status --porcelain=v2 -z` output
    #
    # Builds one {Git::StatusFileInfo} per entry. With `-z` every entry is
    # NUL-terminated and paths are emitted verbatim (no quoting), so a path may
    # contain spaces but never a NUL. The original path of a rename or copy
    # entry is the NUL-terminated token that follows the entry.
    #
    # Every entry type of the porcelain v2 format is handled: `1` (ordinary),
    # `2` (rename or copy), `u` (unmerged), `?` (untracked), and `!` (ignored).
    # `#` header lines, emitted with `--branch` or `--show-stash`, are skipped.
    #
    # {Git::StatusFileInfo} lives at the top-level `Git::` namespace rather than
    # within `Git::Parsers::` because it is public API returned to callers,
    # while this parser is infrastructure.
    #
    # @example Parse the output of `git status --porcelain=v2 -z`
    #   Git::Parsers::Status.parse("? new.txt\0")
    #   #=> [#<data Git::StatusFileInfo path="new.txt", index_status="?", ...>]
    #
    # @see https://git-scm.com/docs/git-status#_porcelain_format_version_2
    #
    # @api private
    #
    module Status
      # Separator between entries (and between a rename entry and its original path)
      ENTRY_SEPARATOR = "\0"

      # Separator between the fields of one entry
      FIELD_SEPARATOR = / /

      # First character of an ordinary (changed, added, or deleted) entry
      ORDINARY_ENTRY = '1'

      # First character of a rename or copy entry
      RENAMED_ENTRY = '2'

      # First character of an unmerged entry
      UNMERGED_ENTRY = 'u'

      # First character of an untracked entry
      UNTRACKED_ENTRY = '?'

      # First character of an ignored entry
      IGNORED_ENTRY = '!'

      # First character of a header line
      HEADER_LINE = '#'

      # Field count of an ordinary entry: `1 <XY> <sub> <mH> <mI> <mW> <hH> <hI> <path>`
      ORDINARY_FIELD_COUNT = 9

      # Field count of a rename or copy entry, which adds `<X><score>` before the path
      RENAMED_FIELD_COUNT = 10

      # Field count of an unmerged entry: `u <XY> <sub> <m1> <m2> <m3> <mW> <h1> <h2> <h3> <path>`
      UNMERGED_FIELD_COUNT = 11

      # Field count of an untracked or ignored entry: `? <path>` or `! <path>`
      PATH_ONLY_FIELD_COUNT = 2

      # Every {Git::StatusFileInfo} member set to `nil`, for entries that lack a field
      #
      # @return [Hash{Symbol => nil}]
      #
      EMPTY_MEMBERS = Git::StatusFileInfo.members.to_h { |member| [member, nil] }.freeze

      module_function

      # Parse `git status --porcelain=v2 -z` output into StatusFileInfo objects
      #
      # @example Parse two entries
      #   Git::Parsers::Status.parse(
      #     "1 .M N... 100644 100644 100644 #{sha} #{sha} lib/foo.rb\0? new.txt\0"
      #   ).map(&:path) #=> ["lib/foo.rb", "new.txt"]
      #
      # @param stdout [String] the NUL-separated output of `git status --porcelain=v2 -z`
      #
      # @return [Array<Git::StatusFileInfo>] one entry per reported path, in git's order
      #
      # @raise [Git::UnexpectedResultError] if an entry does not match the porcelain v2 format
      #
      def parse(stdout)
        tokens = stdout.split(ENTRY_SEPARATOR)
        files = []
        until tokens.empty?
          entry = tokens.shift
          files << parse_entry(entry, tokens) unless entry.start_with?(HEADER_LINE)
        end
        files
      end

      # Parse one entry, consuming its original path from `tokens` for renames and copies
      #
      # @param entry [String] the entry line without its NUL terminator
      #
      # @param tokens [Array<String>] the entries that follow; a rename or copy
      #   entry's original path is shifted off the front
      #
      # @return [Git::StatusFileInfo] the parsed entry
      #
      # @raise [Git::UnexpectedResultError] if the entry type is not recognized
      #
      def parse_entry(entry, tokens)
        case entry[0]
        when ORDINARY_ENTRY then parse_ordinary(entry)
        when RENAMED_ENTRY then parse_renamed(entry, tokens.shift)
        when UNMERGED_ENTRY then parse_unmerged(entry)
        when UNTRACKED_ENTRY, IGNORED_ENTRY then parse_path_only(entry)
        else raise Git::UnexpectedResultError, unexpected_entry_error(entry)
        end
      end

      # Parse an ordinary (`1`) entry
      #
      # @param entry [String] the entry line
      #
      # @return [Git::StatusFileInfo] the parsed entry
      #
      # @raise [Git::UnexpectedResultError] if the entry does not have nine fields
      #
      def parse_ordinary(entry)
        _type, xy, submodule, mode_head, mode_index, mode_worktree, sha_head, sha_index, path =
          split_fields(entry, ORDINARY_FIELD_COUNT)
        build_file_info(xy, path:, submodule:, mode_head:, mode_index:, mode_worktree:, sha_head:, sha_index:)
      end

      # Parse a rename or copy (`2`) entry
      #
      # @param entry [String] the entry line
      #
      # @param original_path [String, nil] the NUL-terminated token that followed
      #   the entry, or `nil` when the output ended
      #
      # @return [Git::StatusFileInfo] the parsed entry
      #
      # @raise [Git::UnexpectedResultError] if the entry does not have ten fields
      #   or the original path is missing
      #
      def parse_renamed(entry, original_path)
        _type, xy, submodule, mode_head, mode_index, mode_worktree, sha_head, sha_index, score, path =
          split_fields(entry, RENAMED_FIELD_COUNT)
        raise Git::UnexpectedResultError, unexpected_entry_error(entry) if original_path.nil?

        build_file_info(
          xy,
          path:, submodule:, mode_head:, mode_index:, mode_worktree:, sha_head:, sha_index:,
          original_path:, rename_score: score[1..].to_i
        )
      end

      # Parse an unmerged (`u`) entry
      #
      # @param entry [String] the entry line
      #
      # @return [Git::StatusFileInfo] the parsed entry with its stage data in
      #   `unmerged_stages`
      #
      # @raise [Git::UnexpectedResultError] if the entry does not have eleven fields
      #
      def parse_unmerged(entry)
        _type, xy, submodule, mode1, mode2, mode3, mode_worktree, sha1, sha2, sha3, path =
          split_fields(entry, UNMERGED_FIELD_COUNT)
        stages = unmerged_stages([mode1, mode2, mode3], [sha1, sha2, sha3])
        build_file_info(xy, path:, submodule:, mode_worktree:, unmerged_stages: stages)
      end

      # Parse an untracked (`?`) or ignored (`!`) entry
      #
      # The entry's single status character is used for both status positions,
      # matching the `??` and `!!` codes of the short format.
      #
      # @param entry [String] the entry line
      #
      # @return [Git::StatusFileInfo] the parsed entry with `nil` metadata
      #
      # @raise [Git::UnexpectedResultError] if the entry does not have two fields
      #
      def parse_path_only(entry)
        type, path = split_fields(entry, PATH_ONLY_FIELD_COUNT)
        build_file_info(type * 2, path: path)
      end

      # Split an entry into exactly `count` fields, the last of which is the path
      #
      # The path may contain spaces, so the split is limited to `count` fields.
      #
      # @param entry [String] the entry line
      #
      # @param count [Integer] the number of fields the entry type has
      #
      # @return [Array<String>] the fields
      #
      # @raise [Git::UnexpectedResultError] if the entry has fewer fields
      #
      def split_fields(entry, count)
        fields = entry.split(FIELD_SEPARATOR, count)
        return fields if fields.length == count

        raise Git::UnexpectedResultError, unexpected_entry_error(entry)
      end

      # Build the frozen stage hash of an unmerged entry
      #
      # @param modes [Array<String>] the stage 1, 2, and 3 modes
      #
      # @param shas [Array<String>] the stage 1, 2, and 3 object names
      #
      # @return [Hash{Integer => Hash{Symbol => String}}] frozen `\\{ mode:, sha: }`
      #   hashes keyed by stage number
      #
      def unmerged_stages(modes, shas)
        modes.zip(shas).each_with_index.to_h do |(mode, sha), index|
          [index + 1, { mode: mode, sha: sha }.freeze]
        end.freeze
      end

      # Build a {Git::StatusFileInfo}, defaulting every member not given to `nil`
      #
      # @param statuses [String] the two status characters, `X` then `Y`
      #
      # @param members [Hash{Symbol => Object}] the members that the entry provides
      #
      # @option members [String] :path the repository-relative path
      #
      # @return [Git::StatusFileInfo] the value object
      #
      def build_file_info(statuses, **members)
        Git::StatusFileInfo.new(
          **EMPTY_MEMBERS, index_status: statuses[0], worktree_status: statuses[1], **members
        )
      end

      # Generate the error message for an entry that does not match the format
      #
      # @param entry [String] the offending entry line
      #
      # @return [String] the message
      #
      def unexpected_entry_error(entry)
        "Unexpected entry in output from `git status --porcelain=v2 -z`: #{entry.inspect}"
      end
    end
  end
end
