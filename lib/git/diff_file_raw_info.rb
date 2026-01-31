# frozen_string_literal: true

require_relative 'file_ref'

module Git
  # Immutable value object representing status info for a single file from git raw diff output
  #
  # Contains the source and destination file references, change status,
  # similarity percentage (for renames/copies), and line change statistics.
  #
  # @api public
  #
  # @example A modified file
  #   info = Git::DiffFileRawInfo.new(
  #     src: Git::FileRef.new(mode: '100644', sha: 'abc1234', path: 'lib/foo.rb'),
  #     dst: Git::FileRef.new(mode: '100644', sha: 'def5678', path: 'lib/foo.rb'),
  #     status: :modified,
  #     similarity: nil,
  #     insertions: 5,
  #     deletions: 2,
  #     binary: false
  #   )
  #
  # @example A new file (src is nil)
  #   info = Git::DiffFileRawInfo.new(
  #     src: nil,
  #     dst: Git::FileRef.new(mode: '100644', sha: 'abc1234', path: 'lib/new.rb'),
  #     status: :added,
  #     similarity: nil,
  #     insertions: 10,
  #     deletions: 0,
  #     binary: false
  #   )
  #
  # @example A renamed file
  #   info = Git::DiffFileRawInfo.new(
  #     src: Git::FileRef.new(mode: '100644', sha: 'abc1234', path: 'lib/old.rb'),
  #     dst: Git::FileRef.new(mode: '100644', sha: 'def5678', path: 'lib/new.rb'),
  #     status: :renamed,
  #     similarity: 95,
  #     insertions: 2,
  #     deletions: 1,
  #     binary: false
  #   )
  #
  # @!attribute [r] src
  #   @return [FileRef, nil] the source file reference, or nil for new/added files
  #
  # @!attribute [r] dst
  #   @return [FileRef, nil] the destination file reference, or nil for deleted files
  #
  # @!attribute [r] status
  #   @return [Symbol] the change status (:added, :modified, :deleted, :renamed, :copied, :type_changed)
  #
  # @!attribute [r] similarity
  #   @return [Integer, nil] similarity percentage for renames/copies (0-100), nil otherwise
  #
  # @!attribute [r] insertions
  #   @return [Integer] number of lines inserted
  #
  # @!attribute [r] deletions
  #   @return [Integer] number of lines deleted
  #
  # @!attribute [r] binary
  #   @return [Boolean] whether this is a binary file
  #
  DiffFileRawInfo = Data.define(:src, :dst, :status, :similarity, :insertions, :deletions, :binary) do
    # Get the primary file path
    #
    # Returns the destination path if it exists, otherwise the source path.
    # This is the "current" or "canonical" path for the file.
    #
    # @return [String] the file path
    #
    def path
      dst&.path || src&.path
    end

    # Get the source path (for renames/copies)
    #
    # @return [String, nil] the source path, or nil if file was added
    #
    def src_path
      src&.path
    end

    # Check if this is a binary file
    #
    # @return [Boolean] true if the file is binary
    #
    def binary?
      binary
    end

    # Check if this file was renamed
    #
    # @return [Boolean]
    #
    def renamed?
      status == :renamed
    end

    # Check if this file was copied
    #
    # @return [Boolean]
    #
    def copied?
      status == :copied
    end

    # Check if this file was added
    #
    # @return [Boolean]
    #
    def added?
      status == :added
    end

    # Check if this file was deleted
    #
    # @return [Boolean]
    #
    def deleted?
      status == :deleted
    end
  end
end
