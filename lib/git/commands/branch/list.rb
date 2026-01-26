# frozen_string_literal: true

require 'git/branch_info'
require 'git/commands/arguments'

module Git
  module Commands
    module Branch
      # Implements the `git branch --list` command
      #
      # This command lists existing branches with optional filtering and formatting.
      #
      # @see https://git-scm.com/docs/git-branch git-branch
      #
      # @api private
      #
      # @example Basic branch listing
      #   list = Git::Commands::Branch::List.new(execution_context)
      #   branches = list.call
      #
      # @example List all branches (local and remote)
      #   list = Git::Commands::Branch::List.new(execution_context)
      #   all_branches = list.call(all: true)
      #
      # @example List branches containing a commit
      #   list = Git::Commands::Branch::List.new(execution_context)
      #   branches = list.call(contains: 'abc123')
      #
      # @example List branches with patterns
      #   list = Git::Commands::Branch::List.new(execution_context)
      #   feature_branches = list.call(patterns: 'feature/*')
      #
      class List
        # Arguments DSL for building command-line arguments
        #
        # NOTE: The order of definitions here determines the order of arguments
        # in the final command line.
        #
        ARGS = Arguments.define do
          static 'branch'
          static '--list'
          flag :all, args: '-a'
          flag :remotes, args: '-r'
          inline_value :sort, multi_valued: true
          value :contains
          value :no_contains
          value :merged
          value :no_merged
          value :points_at
          positional :patterns, variadic: true
        end.freeze

        # Regular expression for parsing git branch output
        #
        # Matches the format of each line in `git branch` output, capturing:
        # - The prefix indicating branch state (current, checked out in worktree, or neither)
        # - The branch reference name
        # - Optional symbolic reference target
        #
        BRANCH_LINE_REGEXP = /
          ^
            # Prefix indicates if this branch is checked out. The prefix is one of:
            (?:
              (?<current>\*[[:blank:]]) |  # Current branch (checked out in the current worktree)
              (?<worktree>\+[[:blank:]]) | # Branch checked out in a different worktree
              [[:blank:]]{2}               # Branch not checked out
            )

            # The branch's full refname
            (?:
              (?<not_a_branch>\(not[[:blank:]]a[[:blank:]]branch\)) |
               (?:\(HEAD[[:blank:]]detached[[:blank:]]at[[:blank:]](?<detached_ref>[^)]+)\)) |
              (?<refname>[^[[:blank:]]]+)
            )

            # Optional symref
            # If this ref is a symbolic reference, this is the ref referenced
            (?:
              [[:blank:]]->[[:blank:]](?<symref>.*)
            )?
          $
        /x

        # Initialize the List command
        #
        # @param execution_context [Git::ExecutionContext, Git::Lib] the context for executing git commands
        #
        def initialize(execution_context)
          @execution_context = execution_context
        end

        # Execute the git branch --list command
        #
        # @overload call(*patterns, **options)
        #
        #   @param patterns [Array<String>] Shell wildcard patterns to filter
        #   branches
        #
        #     If multiple patterns are given, a branch is shown if it matches any of the patterns.
        #
        #   @param options [Hash] command options
        #
        #   @option options [Boolean] :all (nil) List both local and remote branches
        #   (adds -a flag)
        #
        #   @option options [Boolean] :remotes (nil) List only remote-tracking
        #   branches (adds -r flag)
        #
        #   @option options [String, Array<String>] :sort (nil) Sort branches by the
        #   specified key(s)
        #
        #     Give an array to add multiple --sort options. Prefix each key with '-' for
        #     descending order. For example, sort: ['refname', '-committerdate']).
        #
        #   @option options [String] :contains (nil) List only branches that contain
        #     the specified commit
        #
        #   @option options [String] :no_contains (nil) List only branches that don't
        #     contain the specified commit
        #
        #   @option options [String] :merged (nil) List only branches merged into the
        #     specified commit
        #
        #   @option options [String] :no_merged (nil) List only branches not merged
        #     into the specified commit
        #
        #   @option options [String] :points_at (nil) List only branches that point
        #     at the specified object
        #
        # @return [Array<Git::BranchInfo>] array of branch info objects
        #
        # @raise [ArgumentError] if unsupported options are provided
        #
        # @raise [Git::UnexpectedResultError] if git output format is unexpected
        #
        def call(*, **)
          args = ARGS.build(*, **)
          lines = @execution_context.command_lines(*args)
          parse_branches(lines, args)
        end

        private

        # Parse the output lines from git branch
        #
        # @param lines [Array<String>] output lines from git branch command
        # @param args [Array<String>] the arguments passed to git branch
        # @return [Array<Array>] parsed branch data
        #
        def parse_branches(lines, args)
          lines.each_with_index.filter_map do |line, index|
            parse_branch_line(line, index, lines, args)
          end
        end

        # Parse a single branch line
        #
        # @param line [String] the line to parse
        # @param index [Integer] the line index (for error messages)
        # @param all_lines [Array<String>] all output lines (for error messages)
        # @param args [Array<String>] the arguments passed to git branch
        # @return [Array, nil] parsed branch data or nil if line should be filtered
        #
        def parse_branch_line(line, index, all_lines, args)
          match_data = match_branch_line(line, index, all_lines, args)

          # Filter out non-branch lines (detached HEAD, etc.)
          return nil if match_data[:not_a_branch] || match_data[:detached_ref]

          format_branch_data(match_data)
        end

        # Match a branch line against the expected format
        #
        # @param line [String] the line to match
        # @param index [Integer] the line index (for error messages)
        # @param all_lines [Array<String>] all output lines (for error messages)
        # @param args [Array<String>] the arguments passed to git branch
        # @return [MatchData] the match data
        # @raise [Git::UnexpectedResultError] if line doesn't match expected format
        #
        def match_branch_line(line, index, all_lines, args)
          match_data = line.match(BRANCH_LINE_REGEXP)
          raise Git::UnexpectedResultError, unexpected_branch_line_error(all_lines, line, index, args) unless match_data

          match_data
        end

        # Format match data into BranchInfo object
        #
        # @param match_data [MatchData] the regex match data
        # @return [Git::BranchInfo] branch info object
        #
        def format_branch_data(match_data)
          Git::BranchInfo.new(
            refname: match_data[:refname],
            current: !match_data[:current].nil?,
            worktree: !match_data[:worktree].nil?,
            symref: match_data[:symref]
          )
        end

        # Generate error message for unexpected branch line format
        #
        # @param lines [Array<String>] all output lines
        # @param line [String] the problematic line
        # @param index [Integer] the line index
        # @param args [Array<String>] the arguments passed to git (includes command name)
        # @return [String] formatted error message
        #
        def unexpected_branch_line_error(lines, line, index, args)
          command_str = "git #{args.join(' ')}".strip
          <<~ERROR
            Unexpected line in output from `#{command_str}`, line #{index + 1}

            Full output:
              #{lines.join("\n  ")}

            Line #{index + 1}:
              "#{line}"
          ERROR
        end
      end
    end
  end
end
