# frozen_string_literal: true

module Git
  # Represents an object returned by `git fsck`
  #
  # This class provides information about dangling, missing, unreachable, or
  # problematic Git objects found during repository integrity checks.
  #
  # @api public
  #
  class FsckObject
    # The type of the Git object
    # @return [Symbol] one of :commit, :tree, :blob, or :tag
    attr_reader :type

    # The SHA-1 hash of the object
    # @return [String] the 40-character SHA-1 hash
    attr_reader :sha

    # A warning or error message associated with this object
    # @return [String, nil] the message, or nil if no message
    attr_reader :message

    # A name describing how the object is reachable (from --name-objects)
    # @return [String, nil] the name, or nil if not provided
    attr_reader :name

    # Create a new FsckObject
    #
    # @param type [Symbol] the object type (:commit, :tree, :blob, or :tag)
    # @param sha [String] the 40-character SHA-1 hash
    # @param message [String, nil] optional warning/error message
    # @param name [String, nil] optional name from --name-objects (e.g., "HEAD~2^2:src/")
    #
    def initialize(type:, sha:, message: nil, name: nil)
      @type = type
      @sha = sha
      @message = message
      @name = name
    end

    # Returns the SHA as the string representation
    # @return [String] the SHA-1 hash
    def to_s
      sha
    end
  end
end
