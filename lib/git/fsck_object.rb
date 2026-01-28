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

    # The object identifier (OID) of the object
    # @return [String] the 40-character object identifier
    attr_reader :oid

    # A warning or error message associated with this object
    # @return [String, nil] the message, or nil if no message
    attr_reader :message

    # A name describing how the object is reachable (from --name-objects)
    # @return [String, nil] the name, or nil if not provided
    attr_reader :name

    # Create a new FsckObject
    #
    # @param type [Symbol] the object type (:commit, :tree, :blob, or :tag)
    # @param oid [String] the 40-character object identifier
    # @param message [String, nil] optional warning/error message
    # @param name [String, nil] optional name from --name-objects (e.g., "HEAD~2^2:src/")
    #
    def initialize(type:, oid:, message: nil, name: nil)
      @type = type
      @oid = oid
      @message = message
      @name = name
    end

    # Returns the OID as the string representation
    # @return [String] the object identifier
    def to_s
      oid
    end
  end
end
