# frozen_string_literal: true

module Git
  # Represents the result of running `git fsck`
  #
  # This class provides structured access to the objects found during a
  # repository integrity check, categorized by their status.
  #
  # @api public
  #
  class FsckResult
    # Objects not referenced by any other object
    # @return [Array<Git::FsckObject>]
    attr_reader :dangling

    # Objects that are referenced but not present in the repository
    # @return [Array<Git::FsckObject>]
    attr_reader :missing

    # Objects not reachable from any ref
    # @return [Array<Git::FsckObject>]
    attr_reader :unreachable

    # Objects with warnings (each includes a message)
    # @return [Array<Git::FsckObject>]
    attr_reader :warnings

    # Root nodes (commits with no parents) when --root is used
    # @return [Array<Git::FsckObject>]
    attr_reader :root

    # Tagged objects when --tags is used
    # @return [Array<Git::FsckObject>]
    attr_reader :tagged

    # rubocop:disable Metrics/ParameterLists

    # Create a new FsckResult
    #
    # @param dangling [Array<Git::FsckObject>] dangling objects
    # @param missing [Array<Git::FsckObject>] missing objects
    # @param unreachable [Array<Git::FsckObject>] unreachable objects
    # @param warnings [Array<Git::FsckObject>] objects with warnings
    # @param root [Array<Git::FsckObject>] root nodes
    # @param tagged [Array<Git::FsckObject>] tagged objects
    #
    def initialize(dangling: [], missing: [], unreachable: [], warnings: [], root: [], tagged: [])
      @dangling = dangling
      @missing = missing
      @unreachable = unreachable
      @warnings = warnings
      @root = root
      @tagged = tagged
    end

    # rubocop:enable Metrics/ParameterLists

    # Returns true if any issues were found
    #
    # @return [Boolean]
    #
    # @example
    #   result = git.fsck
    #   puts "Repository has issues!" if result.any_issues?
    #
    def any_issues?
      [dangling, missing, unreachable, warnings].any?(&:any?)
    end

    # Returns true if no issues were found
    #
    # @return [Boolean]
    #
    # @example
    #   result = git.fsck
    #   puts "Repository is clean" if result.empty?
    #
    def empty?
      !any_issues?
    end

    # Returns all objects from all categories (excluding informational root/tagged)
    #
    # @return [Array<Git::FsckObject>]
    #
    # @example
    #   result = git.fsck
    #   result.all_objects.each { |obj| puts obj.sha }
    #
    def all_objects
      dangling + missing + unreachable + warnings
    end

    # Returns the total number of issues found
    #
    # @return [Integer]
    #
    # @example
    #   result = git.fsck
    #   puts "Found #{result.count} issues"
    #
    def count
      all_objects.size
    end

    # Returns a hash representation of the result
    #
    # @return [Hash{Symbol => Array<Git::FsckObject>}]
    #
    # @example
    #   result = git.fsck
    #   result.to_h # => { dangling: [...], missing: [...], ... }
    #
    def to_h
      {
        dangling: dangling, missing: missing, unreachable: unreachable,
        warnings: warnings, root: root, tagged: tagged
      }
    end
  end
end
