# frozen_string_literal: true

require 'git/fsck_object'
require 'git/fsck_result'

module Git
  module Parsers
    # Parser for git fsck command output
    #
    # Handles parsing of `git fsck` output into structured data objects
    # for dangling, missing, unreachable objects, warnings, roots, and tagged objects.
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

      # Pattern matcher for warning lines
      # Matches lines like:
      #   warning in commit abc123...: message here
      WARNING_PATTERN = /\Awarning in (\w+) ([0-9a-f]{40}): (.+)\z/

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
      #   FsckParser.parse("dangling commit abc123...\nmissing blob def456...\n")
      #   # => #<Git::FsckResult dangling: [...], missing: [...]>
      #
      # @param stdout [String] output from git fsck command
      # @return [Git::FsckResult] the parsed result
      #
      def parse(stdout)
        result = { dangling: [], missing: [], unreachable: [], warnings: [], root: [], tagged: [] }
        stdout.each_line { |line| parse_line(line.strip, result) }
        Git::FsckResult.new(**result)
      end

      # Parse a single line of fsck output
      #
      # @param line [String] a line of output
      # @param result [Hash] the result hash to populate
      # @return [Boolean] true if the line was parsed
      #
      def parse_line(line, result)
        parse_object_line(line, result) ||
          parse_warning_line(line, result) ||
          parse_root_line(line, result) ||
          parse_tagged_line(line, result)
      end

      # Parse a dangling/missing/unreachable object line
      #
      # @param line [String] a line of output
      # @param result [Hash] the result hash to populate
      # @return [Boolean] true if the line was parsed
      #
      def parse_object_line(line, result)
        return unless (match = OBJECT_PATTERN.match(line))

        result[match[1].to_sym] << Git::FsckObject.new(type: match[2].to_sym, oid: match[3], name: match[4])
      end

      # Parse a warning line
      #
      # @param line [String] a line of output
      # @param result [Hash] the result hash to populate
      # @return [Boolean] true if the line was parsed
      #
      def parse_warning_line(line, result)
        return unless (match = WARNING_PATTERN.match(line))

        result[:warnings] << Git::FsckObject.new(type: match[1].to_sym, oid: match[2], message: match[3])
      end

      # Parse a root line
      #
      # @param line [String] a line of output
      # @param result [Hash] the result hash to populate
      # @return [Boolean] true if the line was parsed
      #
      def parse_root_line(line, result)
        return unless (match = ROOT_PATTERN.match(line))

        result[:root] << Git::FsckObject.new(type: :commit, oid: match[1])
      end

      # Parse a tagged line
      #
      # @param line [String] a line of output
      # @param result [Hash] the result hash to populate
      # @return [Boolean] true if the line was parsed
      #
      def parse_tagged_line(line, result)
        return unless (match = TAGGED_PATTERN.match(line))

        result[:tagged] << Git::FsckObject.new(type: match[1].to_sym, oid: match[2], name: match[3])
      end
    end
  end
end
