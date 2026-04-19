# frozen_string_literal: true

module Git
  # Represents a git version constraint with minimum and upper bound versions
  #
  # Used by {Git::Commands::Base.requires_git_version} to declare version requirements
  # and by {Git::VersionError} to report constraint violations.
  #
  # @example Minimum version only
  #   constraint = Git::VersionConstraint.new(min: Git::Version.parse('2.30.0'))
  #   constraint.too_old?(Git::Version.parse('2.28.0'))  #=> true
  #   constraint.too_new?(Git::Version.parse('2.28.0'))  #=> false
  #
  # @example Upper bound only
  #   constraint = Git::VersionConstraint.new(before: Git::Version.parse('2.50.0'))
  #   constraint.too_old?(Git::Version.parse('2.51.0'))  #=> false
  #   constraint.too_new?(Git::Version.parse('2.51.0'))  #=> true
  #
  # @example Both bounds
  #   constraint = Git::VersionConstraint.new(
  #     min: Git::Version.parse('2.30.0'),
  #     before: Git::Version.parse('2.50.0')
  #   )
  #   constraint.satisfied_by?(Git::Version.parse('2.40.0'))  #=> true
  #
  # @api public
  #
  VersionConstraint = Data.define(:min, :before) do
    # @param min [Git::Version, nil] minimum version (inclusive)
    # @param before [Git::Version, nil] upper bound version (exclusive)
    def initialize(min: nil, before: nil)
      super
    end

    # Check if the given version is too old (below the minimum)
    #
    # @param version [Git::Version] the version to check
    #
    # @return [Boolean] true if version is below the minimum, false otherwise
    #
    def too_old?(version)
      return false unless min

      version < min
    end

    # Check if the given version is too new (at or past the upper bound)
    #
    # @param version [Git::Version] the version to check
    #
    # @return [Boolean] true if version is at or past the upper bound, false otherwise
    #
    def too_new?(version)
      return false unless before

      version >= before
    end

    # Check if the given version satisfies this constraint
    #
    # @param version [Git::Version] the version to check
    #
    # @return [Boolean] true if the version satisfies the constraint
    #
    def satisfied_by?(version)
      !too_old?(version) && !too_new?(version)
    end

    # Return a human-readable representation of this constraint
    #
    # @return [String] the constraint in git version range form
    #
    def to_s
      return ">= #{min}, < #{before}" if min && before
      return ">= #{min}" if min
      return "< #{before}" if before

      'any version'
    end
  end
end
