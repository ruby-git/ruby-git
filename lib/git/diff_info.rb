# frozen_string_literal: true

module Git
  # Immutable value object representing a single file's diff information
  #
  # FileDiffInfo encapsulates the parsed data from a unified diff for one file,
  # including the file path, patch text, mode changes, object identifiers, and type.
  #
  # This class is used by DiffInfo for the legacy diff API.
  #
  # @api public
  #
  # @example Create a FileDiffInfo from parsed diff output
  #   diff_info = Git::FileDiffInfo.new(
  #     path: 'lib/example.rb',
  #     patch: "diff --git a/lib/example.rb b/lib/example.rb\n...",
  #     mode: '100644',
  #     src: 'abc1234',
  #     dst: 'def5678',
  #     type: 'modified',
  #     binary: false
  #   )
  #
  # @!attribute [r] path
  #   @return [String] the file path relative to the repository root
  #
  # @!attribute [r] patch
  #   @return [String] the full unified diff patch text for this file
  #
  # @!attribute [r] mode
  #   @return [String] the file mode (e.g., '100644' for regular files)
  #
  # @!attribute [r] src
  #   @return [String] the source blob object identifier
  #
  # @!attribute [r] dst
  #   @return [String] the destination blob object identifier
  #
  # @!attribute [r] type
  #   @return [String] the type of change: 'modified', 'new', 'deleted', 'renamed'
  #
  # @!attribute [r] binary
  #   @return [Boolean] whether this is a binary file
  #
  FileDiffInfo = Data.define(
    :path,
    :patch,
    :mode,
    :src,
    :dst,
    :type,
    :binary
  ) do
    # Check if this is a binary file
    #
    # @return [Boolean] true if the file is binary
    #
    def binary?
      binary
    end
  end

  # Immutable value object representing diff statistics and optional file patches
  #
  # DiffInfo encapsulates the parsed output from various git commands that produce
  # diff statistics (like `git stash show --stat`). When patches are requested,
  # it also includes the full patch information for each file.
  #
  # The stats hash structure:
  # - `:total` - Hash with `:insertions`, `:deletions`, `:lines`, `:files` keys
  # - `:files` - Hash mapping file paths to `{ insertions:, deletions: }` hashes
  #
  # @api public
  #
  # @example Create a DiffInfo from parsed stats output
  #   info = Git::DiffInfo.new(
  #     stats: {
  #       total: { insertions: 10, deletions: 5, lines: 15, files: 2 },
  #       files: {
  #         'lib/foo.rb' => { insertions: 8, deletions: 3 },
  #         'lib/bar.rb' => { insertions: 2, deletions: 2 }
  #       }
  #     },
  #     file_patches: []
  #   )
  #
  # @example Access statistics
  #   info.insertions  # => 10
  #   info.deletions   # => 5
  #   info.lines       # => 15
  #   info.file_count  # => 2
  #
  # @!attribute [r] stats
  #   @return [Hash] the statistics hash with :total and :files keys
  #
  # @!attribute [r] file_patches
  #   @return [Array<FileDiffInfo>] array of file diff info objects (empty if patch not requested)
  #
  DiffInfo = Data.define(:stats, :file_patches) do
    # @!method insertions
    #   @return [Integer] total number of lines inserted

    # @!method deletions
    #   @return [Integer] total number of lines deleted

    # @!method lines
    #   @return [Integer] total number of lines changed (insertions + deletions)

    # @!method file_count
    #   @return [Integer] number of files changed

    # Total number of lines inserted
    #
    # @return [Integer]
    #
    def insertions
      stats[:total][:insertions]
    end

    # Total number of lines deleted
    #
    # @return [Integer]
    #
    def deletions
      stats[:total][:deletions]
    end

    # Total number of lines changed (insertions + deletions)
    #
    # @return [Integer]
    #
    def lines
      stats[:total][:lines]
    end

    # Number of files changed
    #
    # @return [Integer]
    #
    def file_count
      stats[:total][:files]
    end

    # Per-file statistics hash
    #
    # @return [Hash<String, Hash>] mapping file paths to `{ insertions:, deletions: }` hashes
    #
    def file_stats
      stats[:files]
    end

    # Check if patch information is available
    #
    # @return [Boolean] true if file_patches were loaded
    #
    def patches?
      !file_patches.empty?
    end

    # Get patch info for a specific file
    #
    # @param path [String] the file path
    # @return [FileDiffInfo, nil] the diff info or nil if not found
    #
    def patch_for(path)
      file_patches.find { |p| p.path == path }
    end
  end
end
