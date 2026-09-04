# frozen_string_literal: true

require 'git/worktree_info'

module Git
  module Parsers
    # Parser for git worktree command output
    #
    # Handles parsing of `git worktree list --porcelain` output into structured
    # data objects.
    #
    # @note Known limitation: git C-quotes a lock or prune reason that contains
    #   unusual characters such as a newline or a non-ASCII byte (see the
    #   `--porcelain` description in the git-worktree documentation). The reason
    #   is returned as git prints it, quotes and escapes included; it is not
    #   unquoted.
    #
    # ## Design Note: Namespace Organization
    #
    # This parser creates and returns {Git::WorktreeInfo} objects, which live at
    # the top-level `Git::` namespace rather than within `Git::Parsers::`. This
    # is intentional:
    #
    # - **Parsers are infrastructure** - marked `@api private`, users shouldn't
    #   interact with them directly
    # - **Info classes are public API** - returned by commands and used throughout
    #   the codebase
    # - **Info classes are domain entities** - represent core git concepts
    #   (worktrees as data)
    #
    # Keeping Info classes at `Git::` improves discoverability and correctly
    # reflects their role as public types rather than parser internals.
    #
    # @api private
    #
    module Worktree
      # Pattern splitting a porcelain line into its key and optional value
      #
      # The key is everything before the first space and the value is everything
      # after it, so a path or reason that contains spaces is kept intact. The
      # pattern matches every line; a line with no space has a nil value.
      LINE_PATTERN = /\A(?<key>[^ ]*)(?: (?<value>.*))?\z/

      # Attribute values for a worktree with no flags set
      #
      # @return [Hash{Symbol => Object}]
      DEFAULT_ATTRS = {
        head: nil, branch: nil, bare: false, detached: false,
        locked: false, lock_reason: nil, prunable: false, prune_reason: nil
      }.freeze

      module_function

      # Parse git worktree list --porcelain output into WorktreeInfo objects
      #
      # Records are separated by a blank line. Each record starts with a
      # `worktree <path>` line followed by any of `HEAD <sha>`, `branch <ref>`,
      # `bare`, `detached`, `locked [<reason>]`, and `prunable <reason>`.
      #
      # @example
      #   Git::Parsers::Worktree.parse_list(
      #     "worktree /tmp/wt/main\nHEAD f3e2c1f...\nbranch refs/heads/main\n"
      #   )
      #   # => [#<data Git::WorktreeInfo path="/tmp/wt/main", ...>]
      #
      # @param stdout [String] output from `git worktree list --porcelain`
      #
      # @return [Array<Git::WorktreeInfo>] one entry per worktree, in the order
      #   git listed them (the main worktree first)
      #
      # @raise [Git::UnexpectedResultError] if a record does not start with a
      #   `worktree` line or contains an unrecognized key
      #
      def parse_list(stdout)
        records(stdout).map { |lines| parse_record(lines, stdout) }
      end

      # Split the output into records, each an array of chomped non-blank lines
      #
      # Blank lines separate records. `chunk` drops every run of lines whose
      # block value is `:_separator`, so only the non-blank runs are returned.
      #
      # @param stdout [String] output from `git worktree list --porcelain`
      #
      # @return [Array<Array<String>>] the lines of each record
      #
      def records(stdout)
        stdout.each_line(chomp: true).chunk { |line| line.empty? ? :_separator : true }.map { |_, lines| lines }
      end

      # Parse one record into a WorktreeInfo
      #
      # @param lines [Array<String>] the lines of the record
      #
      # @param stdout [String] the full output (for error messages)
      #
      # @return [Git::WorktreeInfo] the parsed entry
      #
      # @raise [Git::UnexpectedResultError] if the record does not start with a
      #   `worktree` line or contains an unrecognized key
      #
      def parse_record(lines, stdout)
        key, path = split_line(lines.first)
        unless key == 'worktree' && path
          raise Git::UnexpectedResultError,
                unexpected_line_error(stdout, lines.first, 'expected a record to start with "worktree <path>"')
        end

        Git::WorktreeInfo.new(path: path, **DEFAULT_ATTRS, **record_attrs(lines.drop(1), stdout))
      end

      # Collect the attributes set by the lines that follow the `worktree` line
      #
      # @param lines [Array<String>] the record's lines after the first
      #
      # @param stdout [String] the full output (for error messages)
      #
      # @return [Hash{Symbol => Object}] the attributes to override in DEFAULT_ATTRS
      #
      # @raise [Git::UnexpectedResultError] if a line has an unrecognized key
      #
      def record_attrs(lines, stdout)
        lines.each_with_object({}) { |line, attrs| attrs.merge!(line_attrs(line, stdout)) }
      end

      # Map one porcelain line to the WorktreeInfo attributes it sets
      #
      # @param line [String] a chomped line of porcelain output
      #
      # @param stdout [String] the full output (for error messages)
      #
      # @return [Hash{Symbol => Object}] the attributes set by the line
      #
      # @raise [Git::UnexpectedResultError] if the line has an unrecognized key
      #
      def line_attrs(line, stdout)
        key, value = split_line(line)

        case key
        when 'HEAD' then { head: value }
        when 'branch' then { branch: value }
        when 'bare' then { bare: true }
        when 'detached' then { detached: true }
        when 'locked' then { locked: true, lock_reason: value }
        when 'prunable' then { prunable: true, prune_reason: value }
        else raise Git::UnexpectedResultError, unexpected_line_error(stdout, line, 'unrecognized key')
        end
      end

      # Split a porcelain line into its key and optional value
      #
      # @param line [String] a chomped line of porcelain output
      #
      # @return [Array(String, String), Array(String, nil)] the key and the
      #   value, or nil when the line has no value
      #
      def split_line(line)
        match = LINE_PATTERN.match(line)
        [match[:key], match[:value]]
      end

      # Generate the error message for a line the parser cannot handle
      #
      # @param stdout [String] the full output
      #
      # @param line [String] the problematic line
      #
      # @param reason [String] why the line is unexpected
      #
      # @return [String] the formatted error message
      #
      def unexpected_line_error(stdout, line, reason)
        <<~ERROR
          Unexpected line in output from `git worktree list --porcelain`: #{reason}

          Line:
            "#{line}"

          Full output:
            #{stdout.gsub("\n", "\n  ")}
        ERROR
      end
    end
  end
end
