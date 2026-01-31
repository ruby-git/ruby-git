# frozen_string_literal: true

require_relative 'file_ref'

module Git
  # Immutable value object representing a single file's patch information
  #
  # DiffFilePatchInfo encapsulates the parsed data from a unified diff for one file,
  # including source and destination file references, the patch text, change type,
  # and line statistics.
  #
  # @api public
  #
  # @example A modified file patch
  #   patch_info = Git::DiffFilePatchInfo.new(
  #     src: Git::FileRef.new(mode: '100644', sha: 'abc1234', path: 'lib/foo.rb'),
  #     dst: Git::FileRef.new(mode: '100644', sha: 'def5678', path: 'lib/foo.rb'),
  #     patch: "diff --git a/lib/foo.rb b/lib/foo.rb\n...",
  #     status: :modified,
  #     similarity: nil,
  #     binary: false,
  #     insertions: 10,
  #     deletions: 5
  #   )
  #
  # @example A new file patch (src is nil)
  #   patch_info = Git::DiffFilePatchInfo.new(
  #     src: nil,
  #     dst: Git::FileRef.new(mode: '100644', sha: 'abc1234', path: 'lib/new.rb'),
  #     patch: "diff --git a/lib/new.rb b/lib/new.rb\nnew file mode 100644\n...",
  #     status: :added,
  #     similarity: nil,
  #     binary: false,
  #     insertions: 20,
  #     deletions: 0
  #   )
  #
  # @!attribute [r] src
  #   @return [FileRef, nil] the source file reference, or nil for new/added files
  #
  # @!attribute [r] dst
  #   @return [FileRef, nil] the destination file reference, or nil for deleted files
  #
  # @!attribute [r] patch
  #   @return [String] the full unified diff patch text for this file
  #
  # @!attribute [r] status
  #   @return [Symbol] the change status (:added, :modified, :deleted, :renamed, :copied, :type_changed)
  #
  # @!attribute [r] similarity
  #   @return [Integer, nil] similarity percentage for renames/copies (0-100), nil otherwise
  #
  # @!attribute [r] binary
  #   @return [Boolean] whether this is a binary file
  #
  # @!attribute [r] insertions
  #   @return [Integer] number of lines inserted
  #
  # @!attribute [r] deletions
  #   @return [Integer] number of lines deleted
  #
  DiffFilePatchInfo = Data.define(
    :src,
    :dst,
    :patch,
    :status,
    :similarity,
    :binary,
    :insertions,
    :deletions
  ) do
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

    # Get the source file path
    #
    # Returns the source path if it exists. Useful for renames/copies to see
    # where the file came from.
    #
    # @return [String, nil] the source file path, or nil if no source (added files)
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
