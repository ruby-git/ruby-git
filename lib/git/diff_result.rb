# frozen_string_literal: true

require_relative 'dirstat_info'

module Git
  # Immutable result object from git diff commands
  #
  # Contains summary statistics and per-file information from various diff formats.
  # The `files` array contains one of:
  # - DiffFileNumstatInfo (from --numstat)
  # - DiffFileRawInfo (from --raw)
  # - DiffFilePatchInfo (from --patch)
  #
  # @api public
  #
  # @!attribute [r] files_changed
  #   @return [Integer] number of files changed (from --shortstat)
  #
  # @!attribute [r] total_insertions
  #   @return [Integer] total lines inserted across all files (from --shortstat)
  #
  # @!attribute [r] total_deletions
  #   @return [Integer] total lines deleted across all files (from --shortstat)
  #
  # @!attribute [r] files
  #   @return [Array<DiffFileNumstatInfo, DiffFileRawInfo, DiffFilePatchInfo>] per-file information
  #
  # @!attribute [r] dirstat
  #   @return [DirstatInfo, nil] directory statistics if requested, nil otherwise
  #
  DiffResult = Data.define(:files_changed, :total_insertions, :total_deletions, :files, :dirstat)
end
