# frozen_string_literal: true

module Git
  # Immutable value object representing a reference to a file at a specific point in time
  #
  # FileRef encapsulates the mode, SHA, and path of a file as it exists on one side
  # of a diff. This is used to represent either the source (before) or destination
  # (after) state of a file in a diff operation.
  #
  # When a file doesn't exist on a side of the diff (e.g., src for new files,
  # dst for deleted files), the entire FileRef should be nil rather than having
  # a FileRef with nil attributes.
  #
  # @api public
  #
  # @example A modified file's source reference
  #   src = Git::FileRef.new(mode: '100644', sha: 'abc1234', path: 'lib/foo.rb')
  #
  # @example A new file (src would be nil, not a FileRef)
  #   # src = nil
  #   dst = Git::FileRef.new(mode: '100644', sha: 'def5678', path: 'lib/new_file.rb')
  #
  # @!attribute [r] mode
  #   @return [String] the file mode (e.g., '100644' for regular file, '100755' for executable,
  #     '120000' for symlink)
  #
  # @!attribute [r] sha
  #   @return [String] the blob SHA (object identifier)
  #
  # @!attribute [r] path
  #   @return [String] the file path relative to repository root
  #
  FileRef = Data.define(:mode, :sha, :path) do
    # Check if this is a regular file (not executable, symlink, etc.)
    #
    # @return [Boolean] true if mode is 100644
    #
    def regular_file?
      mode == '100644'
    end

    # Check if this is an executable file
    #
    # @return [Boolean] true if mode is 100755
    #
    def executable?
      mode == '100755'
    end

    # Check if this is a symbolic link
    #
    # @return [Boolean] true if mode is 120000
    #
    def symlink?
      mode == '120000'
    end

    # Return the mode as an integer (parsed as octal)
    #
    # Useful for bit operations on file permissions.
    #
    # @return [Integer] the mode as an integer
    #
    # @example Check file permissions
    #   ref.mode_bits & 0o777  # => 0o644 (420 decimal)
    #
    # @example Check if group writable
    #   (ref.mode_bits & 0o020) != 0
    #
    def mode_bits
      mode.to_i(8)
    end
  end
end
