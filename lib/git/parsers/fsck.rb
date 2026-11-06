# frozen_string_literal: true

require 'git/fsck_object'
require 'git/fsck_result'

module Git
  module Parsers
    # Parser for git fsck command output
    #
    # Handles parsing of `git fsck` output into structured data objects
    # for dangling, missing, unreachable objects, warnings, errors, roots, and tagged
    # objects.
    #
    # ## Design Note: Namespace Organization
    #
    # This parser creates and returns {Git::FsckObject} and {Git::FsckResult}
    # objects, which live at the top-level `Git::` namespace rather than within
    # `Git::Parsers::`. This is intentional:
    #
    # - **Parsers are infrastructure** - marked `@api private`, users shouldn't
    #   interact with them directly
    # - **Result classes are public API** - returned by commands and used
    #   throughout the codebase
    # - **FsckObject and FsckResult represent operation outcomes** - they describe
    #   repository integrity status, not parsing details
    #
    # Keeping these classes at `Git::` improves discoverability and correctly
    # reflects their role as public types rather than parser internals.
    #
    # @api private
    #
    module Fsck
      # Pattern matcher for dangling/missing/unreachable object lines
      # Matches lines like:
      #   dangling commit abc123...
      #   missing blob def456...
      #   unreachable tree 789abc... (name)
      OBJECT_PATTERN = /\A(dangling|missing|unreachable) (\w+) ([0-9a-f]{40})(?: \((.+)\))?\z/

      # Pattern matcher for warning and error lines about an object, which git writes
      # to stderr
      # Matches lines like:
      #   warning in commit abc123...: message here
      #   error in tree abc123...: message here
      #   error in blob abc123... (:path): message here
      #
      # The name is greedy because a path in it can contain `): `.
      FINDING_PATTERN = /\A(warning|error) in (\w+) ([0-9a-f]{40})(?: \((.+)\))?: (.+)\z/

      # The result list for each kind of finding in {FINDING_PATTERN}
      FINDING_LISTS = { 'warning' => :warnings, 'error' => :errors }.freeze

      # Pattern matcher for root commit lines
      # Matches lines like:
      #   root abc123...
      ROOT_PATTERN = /\Aroot ([0-9a-f]{40})\z/

      # Pattern matcher for tagged object lines
      # Matches lines like:
      #   tagged commit abc123... (tagname) in def456...
      TAGGED_PATTERN = /\Atagged (\w+) ([0-9a-f]{40}) \((.+)\) in ([0-9a-f]{40})\z/

      module_function

      # Parse git fsck output into a FsckResult object
      #
      # @example
      #   Git::Parsers::Fsck.parse("dangling commit abc123...\n", exit_status: 0, stderr: '')
      #   # => #<Git::FsckResult dangling: [...], exit_status: 0, stderr: ''>
      #
      # @param stdout [String] output from git fsck command
      #
      # @param exit_status [Integer] exit status of the git fsck command
      #
      # @param stderr [String] stderr from the git fsck command, which is where git
      #   writes object warnings and errors
      #
      # @return [Git::FsckResult] the parsed result
      #
      def parse(stdout, exit_status:, stderr:)
        result = { dangling: [], missing: [], unreachable: [], warnings: [], errors: [], root: [], tagged: [] }
        stdout.each_line { |line| parse_line(line.strip, result) }
        stderr.each_line { |line| parse_finding_line(line.strip, result) }
        remove_repeated_findings(result)
        Git::FsckResult.new(**result, exit_status: exit_status, stderr: stderr)
      end

      # Parse a single line of fsck stdout
      #
      # @param line [String] a line of output
      #
      # @param result [Hash] the result hash to populate
      #
      # @return [Boolean] true if the line was parsed
      #
      def parse_line(line, result)
        parse_object_line(line, result) ||
          parse_root_line(line, result) ||
          parse_tagged_line(line, result)
      end

      # Drop findings git repeated for another copy of an object
      #
      # git checks each stored copy, so an object both loose and in a pack gets the same
      # line twice.
      #
      # @param result [Hash] the result hash to update
      #
      # @return [void]
      #
      def remove_repeated_findings(result)
        %i[warnings errors].each { |list| result[list].uniq! { |object| [object.oid, object.message] } }
      end

      # Parse a dangling/missing/unreachable object line
      #
      # @param line [String] a line of output
      #
      # @param result [Hash] the result hash to populate
      #
      # @return [Boolean] true if the line was parsed
      #
      def parse_object_line(line, result)
        return unless (match = OBJECT_PATTERN.match(line))

        result[match[1].to_sym] << Git::FsckObject.new(type: match[2].to_sym, oid: match[3], name: match[4])
      end

      # Parse a warning or error line
      #
      # @param line [String] a line of output
      #
      # @param result [Hash] the result hash to populate
      #
      # @return [Array<Git::FsckObject>, nil] the list the line was added to, or nil if
      #   the line did not match
      #
      def parse_finding_line(line, result)
        return unless (match = FINDING_PATTERN.match(line))

        result[FINDING_LISTS[match[1]]] <<
          Git::FsckObject.new(type: match[2].to_sym, oid: match[3], name: match[4], message: match[5])
      end

      # Parse a root line
      #
      # @param line [String] a line of output
      #
      # @param result [Hash] the result hash to populate
      #
      # @return [Boolean] true if the line was parsed
      #
      def parse_root_line(line, result)
        return unless (match = ROOT_PATTERN.match(line))

        result[:root] << Git::FsckObject.new(type: :commit, oid: match[1])
      end

      # Parse a tagged line
      #
      # @param line [String] a line of output
      #
      # @param result [Hash] the result hash to populate
      #
      # @return [Boolean] true if the line was parsed
      #
      def parse_tagged_line(line, result)
        return unless (match = TAGGED_PATTERN.match(line))

        result[:tagged] << Git::FsckObject.new(type: match[1].to_sym, oid: match[2], name: match[3])
      end
    end
  end
end
