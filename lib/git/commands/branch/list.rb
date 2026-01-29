# frozen_string_literal: true

require 'git/branch_info'
require 'git/commands/arguments'

module Git
  module Commands
    module Branch
      # Implements the `git branch --list` command
      #
      # This command lists existing branches with optional filtering and formatting.
      # Uses `--format` to retrieve structured data including target OID and upstream.
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
        # Format string for git branch --format
        #
        # Fields (pipe-delimited):
        # 1. refname - full ref name (e.g., refs/heads/main, refs/remotes/origin/main)
        # 2. objectname - full SHA of the commit the branch points to
        # 3. HEAD - '*' if current branch, empty otherwise
        # 4. worktreepath - path if checked out in another worktree, empty otherwise
        # 5. symref - target ref if symbolic reference, empty otherwise
        # 6. upstream - full upstream ref (e.g., refs/remotes/origin/main), empty if none
        #
        # @api private
        FORMAT_STRING = '%(refname)|%(objectname)|%(HEAD)|%(worktreepath)|%(symref)|%(upstream)'

        # Delimiter used in format output
        FIELD_DELIMITER = '|'

        # Arguments DSL for building command-line arguments
        #
        # NOTE: The order of definitions here determines the order of arguments
        # in the final command line.
        #
        ARGS = Arguments.define do
          static 'branch'
          static '--list'
          inline_value :format
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
        def call(*, **)
          args = ARGS.build(*, format: FORMAT_STRING, **)
          lines = @execution_context.command(*args, raise_on_failure: false).stdout.split("\n")
          parse_branches(lines)
        end

        private

        # Parse the output lines from git branch --format
        #
        # @param lines [Array<String>] output lines from git branch command
        # @return [Array<Git::BranchInfo>] parsed branch data
        #
        def parse_branches(lines)
          lines.filter_map { |line| parse_branch_line(line) }
        end

        # Parse a single formatted branch line
        #
        # @param line [String] the line to parse (pipe-delimited fields)
        # @return [Git::BranchInfo, nil] branch info object, or nil if line should be skipped
        #
        def parse_branch_line(line)
          fields = line.split(FIELD_DELIMITER, 6)

          return nil if non_branch_entry?(fields[0])

          build_branch_info(fields)
        end

        # Build a BranchInfo from parsed fields
        #
        # @param fields [Array<String>] the parsed fields: [refname, objectname, head, worktreepath, symref, upstream]
        # @return [Git::BranchInfo] the branch info object
        #
        def build_branch_info(fields)
          raw_refname, objectname, head, worktreepath, symref, upstream = fields
          current = head == '*'

          Git::BranchInfo.new(
            refname: normalize_refname(raw_refname),
            target_oid: presence(objectname),
            current: current,
            worktree: in_other_worktree?(worktreepath, current),
            symref: presence(symref),
            upstream: build_upstream_info(upstream)
          )
        end

        # Check if the refname represents a detached HEAD state or non-branch entry
        #
        # Git outputs special entries for detached HEAD and non-branch states:
        # - "(HEAD detached at <ref>)" when in detached HEAD state
        # - "(not a branch)" for non-branch entries
        #
        # @param refname [String] the refname to check
        # @return [Boolean] true if this is a non-branch entry
        #
        def non_branch_entry?(refname)
          refname.match?(/^\(HEAD detached/) || refname.match?(/^\(not a branch\)/)
        end

        # Normalize a full refname to the expected format
        #
        # Converts:
        # - refs/heads/main -> main
        # - refs/remotes/origin/main -> remotes/origin/main
        #
        # @param refname [String] the full refname from git
        # @return [String] normalized refname
        #
        def normalize_refname(refname)
          refname.sub(%r{^refs/heads/}, '').sub(%r{^refs/}, '')
        end

        # Check if the branch is checked out in another worktree
        #
        # worktree is true when the branch is checked out in ANOTHER worktree
        # (worktreepath is non-empty AND it's not the current branch)
        #
        # @param worktreepath [String, nil] the worktree path from git output
        # @param current [Boolean] whether this is the current branch
        # @return [Boolean] true if checked out in another worktree
        #
        def in_other_worktree?(worktreepath, current)
          has_worktree = !worktreepath.nil? && !worktreepath.empty?
          has_worktree && !current
        end

        # Build upstream BranchInfo from upstream refname
        #
        # @param upstream_ref [String, nil] the upstream ref (e.g., 'refs/remotes/origin/main')
        # @return [Git::BranchInfo, nil] upstream branch info or nil
        #
        def build_upstream_info(upstream_ref)
          return nil if upstream_ref.nil? || upstream_ref.empty?

          Git::BranchInfo.new(
            refname: normalize_refname(upstream_ref),
            target_oid: nil, # We don't have upstream's OID from this format
            current: false,
            worktree: false,
            symref: nil,
            upstream: nil # Upstream branches don't have their own upstream in this context
          )
        end

        # Return value if non-empty, nil otherwise
        #
        # @param value [String, nil] the value to check
        # @return [String, nil] the value or nil
        #
        def presence(value)
          value.nil? || value.empty? ? nil : value
        end
      end
    end
  end
end
