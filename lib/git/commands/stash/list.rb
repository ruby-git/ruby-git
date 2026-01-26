# frozen_string_literal: true

require 'git/stash_info'

module Git
  module Commands
    module Stash
      # List all stash entries
      #
      # Returns information about all stash entries in the repository.
      # Each stash entry is parsed and returned as a {Git::StashInfo} object
      # containing comprehensive metadata including SHA, branch, message,
      # author/committer details, and timestamps.
      #
      # @see https://git-scm.com/docs/git-stash git-stash documentation
      # @api private
      #
      # @example List all stashes
      #   stashes = Git::Commands::Stash::List.new(execution_context).call
      #   stashes.each do |s|
      #     puts "#{s.short_sha} #{s.name}: #{s.message} (#{s.author_name})"
      #   end
      #
      class List
        # Field separator used in custom format output
        # Using a non-printable unit separator (US, 0x1F) to avoid collisions with
        # stash messages and author/committer fields, while still working with
        # Process.spawn (which doesn't allow NUL bytes in arguments)
        FIELD_SEPARATOR = "\x1f"

        # Custom format for git stash list that extracts all available metadata
        # %H  = full commit SHA
        # %h  = abbreviated commit SHA
        # %gd = reflog selector (stash@\\{n\\})
        # %gs = reflog subject (the stash message)
        # %an = author name
        # %ae = author email
        # %aI = author date (ISO 8601 format)
        # %cn = committer name
        # %ce = committer email
        # %cI = committer date (ISO 8601 format)
        STASH_FORMAT = [
          '%H',  # 0: full SHA
          '%h',  # 1: short SHA
          '%gd', # 2: reflog selector
          '%gs', # 3: reflog subject (message)
          '%an', # 4: author name
          '%ae', # 5: author email
          '%aI', # 6: author date
          '%cn', # 7: committer name
          '%ce', # 8: committer email
          '%cI'  # 9: committer date
        ].join(FIELD_SEPARATOR)

        # Number of fields expected in the parsed output
        FIELD_COUNT = 10

        # Field indices for parsed output
        module Fields
          SHA = 0
          SHORT_SHA = 1
          REFLOG = 2
          MESSAGE = 3
          AUTHOR_NAME = 4
          AUTHOR_EMAIL = 5
          AUTHOR_DATE = 6
          COMMITTER_NAME = 7
          COMMITTER_EMAIL = 8
          COMMITTER_DATE = 9
        end

        # Pattern to extract branch from standard stash messages
        # Matches "WIP on <branch>:" or "On <branch>:" at the start
        BRANCH_PATTERN = /^(?:WIP on|On)\s+([^:]+):/

        # Creates a new List command instance
        #
        # @param execution_context [Git::ExecutionContext] the execution context for running commands
        #
        def initialize(execution_context)
          @execution_context = execution_context
        end

        # List all stash entries
        #
        # @return [Array<Git::StashInfo>] array of stash information objects
        #
        # @raise [Git::UnexpectedResultError] if stash output cannot be parsed
        #
        def call
          lines = @execution_context.command_lines('stash', 'list', "--format=#{STASH_FORMAT}")
          lines.each_with_index.map { |line, idx| parse_stash_line(line, idx, lines) }
        end

        private

        # Parse a single stash list line into a StashInfo object
        #
        # @param line [String] a line from git stash list output (custom format)
        # @param expected_index [Integer] the expected stash index for validation
        # @param all_lines [Array<String>] all output lines (for error messages)
        #
        # @return [Git::StashInfo] parsed stash info
        #
        # @raise [Git::UnexpectedResultError] if line format is unexpected
        #
        def parse_stash_line(line, expected_index, all_lines)
          parts = line.split(FIELD_SEPARATOR, FIELD_COUNT)
          return build_stash_info(parts, expected_index) if parts.length == FIELD_COUNT

          raise Git::UnexpectedResultError, unexpected_stash_line_error(all_lines, line, expected_index)
        end

        # Build a StashInfo from parsed format parts
        #
        # @param parts [Array<String>] the parsed format fields
        # @param expected_index [Integer] fallback index if not parseable from reflog
        # @return [Git::StashInfo]
        #
        def build_stash_info(parts, expected_index)
          index = extract_index(parts[Fields::REFLOG]) || expected_index

          Git::StashInfo.new(**stash_info_attrs(parts, index))
        end

        # Build StashInfo attributes hash from parsed parts
        #
        # @param parts [Array<String>] the parsed format fields
        # @param index [Integer] the resolved stash index
        # @return [Hash] attributes for StashInfo.new
        #
        def stash_info_attrs(parts, index) # rubocop:disable Metrics/MethodLength
          {
            index: index,
            name: parts[Fields::REFLOG],
            sha: parts[Fields::SHA],
            short_sha: parts[Fields::SHORT_SHA],
            branch: extract_branch(parts[Fields::MESSAGE]),
            message: parts[Fields::MESSAGE],
            author_name: parts[Fields::AUTHOR_NAME],
            author_email: parts[Fields::AUTHOR_EMAIL],
            author_date: parts[Fields::AUTHOR_DATE],
            committer_name: parts[Fields::COMMITTER_NAME],
            committer_email: parts[Fields::COMMITTER_EMAIL],
            committer_date: parts[Fields::COMMITTER_DATE]
          }
        end

        # Extract the stash index from a reflog selector
        #
        # @param reflog_selector [String] e.g., "stash@\\{0\\}"
        # @return [Integer, nil] the index or nil if not found
        #
        def extract_index(reflog_selector)
          match = reflog_selector&.match(/stash@\{(\d+)\}/)
          match ? match[1].to_i : nil
        end

        # Extract the branch name from a stash message
        #
        # @param message [String] the stash message
        # @return [String, nil] the branch name or nil for custom messages
        #
        def extract_branch(message)
          match = BRANCH_PATTERN.match(message)
          match ? match[1] : nil
        end

        # Generate error message for unexpected stash line format
        #
        # @param lines [Array<String>] all output lines
        # @param line [String] the problematic line
        # @param index [Integer] the stash index
        # @return [String] formatted error message
        #
        def unexpected_stash_line_error(lines, line, index)
          format_str = STASH_FORMAT.gsub(FIELD_SEPARATOR, '<FS>')
          <<~ERROR
            Unexpected line in output from `git stash list --format=#{format_str}`, at index #{index}

            Expected #{FIELD_COUNT} fields separated by '\\x1f' (unit separator), got #{line.split(FIELD_SEPARATOR, -1).length}

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
