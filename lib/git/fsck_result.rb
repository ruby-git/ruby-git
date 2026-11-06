# frozen_string_literal: true

module Git
  # Represents the result of running `git fsck`
  #
  # This class provides structured access to the objects found during a
  # repository integrity check, categorized by their status, along with the exit
  # status and stderr of the run.
  #
  # git reports some findings, such as a branch that points at a tag, only in the
  # exit status and stderr. A result for such a run has no flagged objects, but
  # {#any_issues?} still returns true.
  #
  # @api public
  #
  class FsckResult
    # Objects not referenced by any other object
    #
    # @return [Array<Git::FsckObject>]
    attr_reader :dangling

    # Objects that are referenced but not present in the repository
    #
    # @return [Array<Git::FsckObject>]
    attr_reader :missing

    # Objects not reachable from any ref
    #
    # @return [Array<Git::FsckObject>]
    attr_reader :unreachable

    # Objects with warnings (each includes a message)
    #
    # @return [Array<Git::FsckObject>]
    attr_reader :warnings

    # Objects that failed a check (each includes a message)
    #
    # An object git cannot read gets no `error in` line, so it is not listed here
    # and appears only in {#stderr}.
    #
    # @return [Array<Git::FsckObject>]
    attr_reader :errors

    # Root nodes (commits with no parents) when --root is used
    #
    # @return [Array<Git::FsckObject>]
    attr_reader :root

    # Tagged objects when --tags is used
    #
    # @return [Array<Git::FsckObject>]
    attr_reader :tagged

    # The exit status of `git fsck`
    #
    # git sets a bit in this status for each kind of problem it finds.
    #
    # @return [Integer]
    attr_reader :exit_status

    # What `git fsck` wrote to stderr
    #
    # For a finding that is not on an object list, this is where git names the ref,
    # object, or file that failed.
    #
    # @return [String]
    attr_reader :stderr

    # rubocop:disable Metrics/ParameterLists

    # Create a new FsckResult
    #
    # @param dangling [Array<Git::FsckObject>] dangling objects
    #
    # @param missing [Array<Git::FsckObject>] missing objects
    #
    # @param unreachable [Array<Git::FsckObject>] unreachable objects
    #
    # @param warnings [Array<Git::FsckObject>] objects with warnings
    #
    # @param errors [Array<Git::FsckObject>] objects that failed a check
    #
    # @param root [Array<Git::FsckObject>] root nodes
    #
    # @param tagged [Array<Git::FsckObject>] tagged objects
    #
    # @param exit_status [Integer] the exit status of `git fsck`
    #
    # @param stderr [String] what `git fsck` wrote to stderr
    #
    def initialize(
      dangling: [], missing: [], unreachable: [], warnings: [], errors: [], root: [], tagged: [], exit_status: 0,
      stderr: ''
    )
      @dangling = dangling
      @missing = missing
      @unreachable = unreachable
      @warnings = warnings
      @errors = errors
      @root = root
      @tagged = tagged
      @exit_status = exit_status
      @stderr = stderr
    end

    # rubocop:enable Metrics/ParameterLists

    # Returns true if any issues were found
    #
    # An issue is a flagged object or a nonzero {#exit_status}.
    #
    # @example Check for repository issues
    #   result = git.fsck
    #   puts "Repository has issues!" if result.any_issues?
    #
    # @return [Boolean]
    #
    def any_issues?
      !exit_status.zero? || [dangling, missing, unreachable, warnings, errors].any?(&:any?)
    end

    # Returns true if no issues were found
    #
    # Returns false for a nonzero {#exit_status}, even with no flagged objects.
    #
    # @example Check if the result is empty
    #   result = git.fsck
    #   puts "Repository is clean" if result.empty?
    #
    # @return [Boolean]
    #
    def empty?
      !any_issues?
    end

    # Returns all objects from all categories (excluding informational root/tagged)
    #
    # @example Iterate over all objects
    #   result = git.fsck
    #   result.all_objects.each { |obj| puts obj.oid }
    #
    # @return [Array<Git::FsckObject>]
    #
    def all_objects
      dangling + missing + unreachable + warnings + errors
    end

    # Returns the total number of flagged objects
    #
    # A finding git reports only in {#exit_status} and {#stderr} is not counted, so
    # this can be 0 when {#any_issues?} is true.
    #
    # @example Count flagged objects
    #   result = git.fsck
    #   puts "Found #{result.count} flagged objects"
    #
    # @return [Integer]
    #
    def count
      all_objects.size
    end

    # Returns a hash representation of the result
    #
    # @example Convert to a hash
    #   result = git.fsck
    #   result.to_h # => { dangling: [...], missing: [...], ... }
    #
    # @return [Hash{Symbol => Array<Git::FsckObject>}]
    #
    def to_h
      {
        dangling: dangling, missing: missing, unreachable: unreachable,
        warnings: warnings, errors: errors, root: root, tagged: tagged
      }
    end
  end
end
