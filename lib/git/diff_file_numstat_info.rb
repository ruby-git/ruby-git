# frozen_string_literal: true

module Git
  # Immutable value object representing stats for a single file from git numstat output
  #
  # @api private
  #
  # Work in progress; this class is internal for now and may be made public in a future release.
  #
  # @!attribute [r] path
  #   @return [String] the file path (destination path for renames)
  #
  # @!attribute [r] src_path
  #   @return [String, nil] the source path for renamed files, nil otherwise
  #
  # @!attribute [r] insertions
  #   @return [Integer] number of lines inserted
  #
  # @!attribute [r] deletions
  #   @return [Integer] number of lines deleted
  #
  DiffFileNumstatInfo = Data.define(:path, :src_path, :insertions, :deletions) do
    # Check if this file was renamed
    #
    # @return [Boolean] true if the file was renamed
    #
    def renamed?
      !src_path.nil?
    end
  end
end
