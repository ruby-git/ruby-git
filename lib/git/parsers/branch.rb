# frozen_string_literal: true

require 'git/branch_info'
require 'git/branch_delete_result'
require 'git/branch_delete_failure'

module Git
  module Parsers
    # Parser for git branch command output
    #
    # Handles parsing of `git branch --list` and `git branch --delete` output
    # into structured data objects.
    #
    # ## Design Note: Namespace Organization
    #
    # This parser creates and returns {Git::BranchInfo} and {Git::BranchDeleteResult}
    # objects, which live at the top-level `Git::` namespace rather than within
    # `Git::Parsers::`. This is intentional:
    #
    # - **Parsers are infrastructure** - marked `@api private`, users shouldn't
    #   interact with them directly
    # - **Info/Result classes are public API** - returned by commands and used
    #   throughout the codebase
    # - **Info classes are domain entities** - represent core git concepts
    #   (branches as data)
    # - **Result classes are operation outcomes** - represent command results,
    #   not parsing details
    #
    # Keeping Info/Result classes at `Git::` improves discoverability and correctly
    # reflects their role as public types rather than parser internals.
    #
    # @api private
    #
    module Branch
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
      FORMAT_STRING = '%(refname)|%(objectname)|%(HEAD)|%(worktreepath)|%(symref)|%(upstream)'

      # Delimiter used in format output
      FIELD_DELIMITER = '|'

      # Regex to parse successful deletion lines from stdout
      # Matches: Deleted branch branchname (was abc123).
      # Matches: Deleted remote-tracking branch origin/branchname (was abc123).
      # Uses non-greedy match to capture branch names containing spaces
      DELETED_BRANCH_REGEX = /^Deleted (?:remote-tracking )?branch (.+?) \(was/

      # Regex to parse error messages from stderr
      # Matches: error: branch 'branchname' not found.
      ERROR_BRANCH_REGEX = /^error: branch '([^']+)'(.*)$/

      module_function

      # Parse git branch --list output into BranchInfo objects
      #
      # @example
      #   BranchParser.parse_list("main|abc123|*|||\nfeature|def456||||\n")
      #   # => [#<Git::BranchInfo name: "main", ...>, ...]
      #
      # @param stdout [String] output from git branch --list --format=...
      # @return [Array<Git::BranchInfo>] parsed branch information
      #
      def parse_list(stdout)
        stdout.split("\n").filter_map { |line| parse_branch_line(line) }
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

      # Parse deleted branch names from stdout
      #
      # @example
      #   BranchParser.parse_deleted_branches("Deleted branch feature (was abc123).\n")
      #   # => ["feature"]
      #
      # @param stdout [String] command stdout
      # @return [Array<String>] names of successfully deleted branches
      #
      def parse_deleted_branches(stdout)
        stdout.scan(DELETED_BRANCH_REGEX).flatten
      end

      # Parse error messages from stderr into a map
      #
      # @example
      #   BranchParser.parse_error_messages("error: branch 'missing' not found.\n")
      #   # => {"missing" => "error: branch 'missing' not found."}
      #
      # @param stderr [String] command stderr
      # @return [Hash<String, String>] map of branch name to error message
      #
      def parse_error_messages(stderr)
        stderr.each_line.with_object({}) do |line, hash|
          match = line.match(ERROR_BRANCH_REGEX)
          hash[match[1]] = line.strip if match
        end
      end

      # Build the BranchDeleteResult from parsed data
      #
      # @param requested_names [Array<String>] originally requested branch names
      # @param existing_branches [Hash<String, Git::BranchInfo>] branches that existed before delete
      # @param deleted_names [Array<String>] names confirmed deleted in stdout
      # @param error_map [Hash<String, String>] map of branch name to error message
      # @return [Git::BranchDeleteResult] the result object
      #
      def build_delete_result(requested_names, existing_branches, deleted_names, error_map)
        deleted = deleted_names.filter_map { |name| existing_branches[name] }

        not_deleted = (requested_names - deleted_names).map do |name|
          error_message = error_map[name] || "branch '#{name}' could not be deleted"
          Git::BranchDeleteFailure.new(name: name, error_message: error_message)
        end

        Git::BranchDeleteResult.new(deleted: deleted, not_deleted: not_deleted)
      end
    end
  end
end
