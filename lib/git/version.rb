# frozen_string_literal: true

module Git
  # The current gem version
  # @return [String] the current gem version.
  VERSION = '4.1.2'

  # Represents a git version with major, minor, and patch components
  #
  # Git versions follow a strict major.minor.patch format. This class provides
  # parsing from git command output (which may include platform suffixes) and
  # comparison operations for version gating.
  #
  # @!attribute [r] major
  #   The major version number
  #   @return [Integer]
  #
  # @!attribute [r] minor
  #   The minor version number
  #   @return [Integer]
  #
  # @!attribute [r] patch
  #   The patch version number
  #   @return [Integer]
  #
  # @example Creating a version directly
  #   version = Git::Version.new(2, 42, 1)
  #   version.to_s  #=> "2.42.1"
  #
  # @example Parsing from git version output
  #   Git::Version.parse('git version 2.42.1')  #=> Git::Version.new(2, 42, 1)
  #   Git::Version.parse('2.39.2 (Apple Git-143)')  #=> Git::Version.new(2, 39, 2)
  #
  # @example Parsing versions with platform suffixes
  #   Git::Version.parse('2.42.0.windows.1')  #=> Git::Version.new(2, 42, 0)
  #
  # @example Comparing versions
  #   Git::Version.new(2, 42, 1) > Git::Version.new(2, 28, 0)  #=> true
  #
  # @api public
  #
  Version = Data.define(:major, :minor, :patch) do
    include Comparable

    # Parse a version string into a Version object
    #
    # Handles git's version output format, stripping platform suffixes
    # (like `.windows.1` or `.vfs.0`) and padding two-segment versions
    # to three segments.
    #
    # @param string [String] version string to parse
    #
    # @return [Git::Version] the parsed version
    #
    # @raise [ArgumentError] if the string cannot be parsed as a version
    #
    # @example
    #   Git::Version.parse('2.42.1')  #=> Git::Version.new(2, 42, 1)
    #   Git::Version.parse('git version 2.42.1')  #=> Git::Version.new(2, 42, 1)
    #   Git::Version.parse('2.42.0.windows.1')  #=> Git::Version.new(2, 42, 0)
    #
    def self.parse(string)
      version_match = string&.match(/(\d+)\.(\d+)(?:\.(\d+))?/)
      raise ArgumentError, "Invalid version: #{string.inspect}" unless version_match

      major = version_match[1].to_i
      minor = version_match[2].to_i
      patch = (version_match[3] || '0').to_i

      new(major, minor, patch)
    end

    # Compare this version to another
    #
    # @param other [Git::Version] the version to compare to
    #
    # @return [Integer] -1, 0, or 1
    #
    def <=>(other)
      [major, minor, patch] <=> [other.major, other.minor, other.patch]
    end

    # Return the version as a dotted string
    #
    # @return [String] the version in "major.minor.patch" format
    #
    def to_s
      "#{major}.#{minor}.#{patch}"
    end

    # Return a readable representation
    #
    # @return [String] inspect string
    #
    def inspect
      "#<Git::Version #{self}>"
    end
  end
end
