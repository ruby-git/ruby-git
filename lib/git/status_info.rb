# frozen_string_literal: true

require 'git/status_file_info'

module Git
  # Immutable value object for the status of a repository's index and working tree
  #
  # Holds one {Git::StatusFileInfo} per path that `git status` reports, in the
  # order git listed them, together with the repository's `core.ignoreCase`
  # setting. The derived readers (`changed`, `added`, `deleted`, `untracked`,
  # `unmerged`) return the matching files keyed by path and are computed on each
  # call. The path predicates (`changed?`, `added?`, `deleted?`, `untracked?`)
  # compare paths case-insensitively when `ignore_case` is `true`.
  #
  # @example Inspect repository status
  #   status = repo.status_info
  #   status.changed.each_key { |path| puts "Modified: #{path}" }
  #   status.added.each_key { |path| puts "Added: #{path}" }
  #   status.deleted.each_key { |path| puts "Deleted: #{path}" }
  #   status.untracked.each_key { |path| puts "Untracked: #{path}" }
  #
  # @example Check one path
  #   status = repo.status_info
  #   status.changed?('lib/foo.rb')       #=> true
  #   status['lib/foo.rb'].worktree_status #=> "M"
  #
  # @see Git::StatusFileInfo
  #
  # @see Git::Repository#status_info
  #
  # @api public
  #
  # @!attribute [r] files
  #
  #   @return [Array<Git::StatusFileInfo>] every reported path in git's output
  #     order; the array is frozen
  #
  # @!attribute [r] ignore_case
  #
  #   @return [Boolean] `true` when the repository's `core.ignoreCase` is true,
  #     making the path predicates compare paths case-insensitively
  #
  StatusInfo = Data.define(:files, :ignore_case) do
    # Creates a status value object holding a frozen copy of the given files
    #
    # @example Build a status from parsed files
    #   Git::StatusInfo.new(files: files, ignore_case: false)
    #
    # @param files [Array<Git::StatusFileInfo>] the reported paths in git's
    #   output order
    #
    # @param ignore_case [Boolean] whether path predicates ignore case
    #
    def initialize(files:, ignore_case:)
      super(files: files.dup.freeze, ignore_case: ignore_case)
    end

    # Returns the files modified or type-changed in the index or working tree
    #
    # @example List modified paths
    #   repo.status_info.changed.keys #=> ["lib/foo.rb"]
    #
    # @return [Hash{String => Git::StatusFileInfo}] changed files keyed by path
    #
    def changed = files_by_path(&:changed?)

    # Returns the files added to the index that are not in HEAD
    #
    # @example List added paths
    #   repo.status_info.added.keys #=> ["lib/new.rb"]
    #
    # @return [Hash{String => Git::StatusFileInfo}] added files keyed by path
    #
    def added = files_by_path(&:added?)

    # Returns the files deleted from the index or working tree
    #
    # @example List deleted paths
    #   repo.status_info.deleted.keys #=> ["lib/old.rb"]
    #
    # @return [Hash{String => Git::StatusFileInfo}] deleted files keyed by path
    #
    def deleted = files_by_path(&:deleted?)

    # Returns the files in the working tree that git does not track
    #
    # @example List untracked paths
    #   repo.status_info.untracked.keys #=> ["notes.txt"]
    #
    # @return [Hash{String => Git::StatusFileInfo}] untracked files keyed by path
    #
    def untracked = files_by_path(&:untracked?)

    # Returns the files with merge conflicts
    #
    # @example List conflicted paths
    #   repo.status_info.unmerged.keys #=> ["lib/conflict.rb"]
    #
    # @return [Hash{String => Git::StatusFileInfo}] unmerged files keyed by path
    #
    def unmerged = files_by_path(&:unmerged?)

    # Returns `true` if `path` is modified in the index or working tree
    #
    # @example Check a path
    #   repo.status_info.changed?('lib/foo.rb') #=> true
    #
    # @param path [String] the repository-relative path to check
    #
    # @return [Boolean] `true` when the path is in {#changed}
    #
    def changed?(path) = path_in?(changed, path)

    # Returns `true` if `path` was added to the index
    #
    # @example Check a path
    #   repo.status_info.added?('lib/new.rb') #=> true
    #
    # @param path [String] the repository-relative path to check
    #
    # @return [Boolean] `true` when the path is in {#added}
    #
    def added?(path) = path_in?(added, path)

    # Returns `true` if `path` was deleted from the index or working tree
    #
    # @example Check a path
    #   repo.status_info.deleted?('lib/old.rb') #=> true
    #
    # @param path [String] the repository-relative path to check
    #
    # @return [Boolean] `true` when the path is in {#deleted}
    #
    def deleted?(path) = path_in?(deleted, path)

    # Returns `true` if `path` is not tracked by git
    #
    # @example Check a path
    #   repo.status_info.untracked?('notes.txt') #=> true
    #
    # @param path [String] the repository-relative path to check
    #
    # @return [Boolean] `true` when the path is in {#untracked}
    #
    def untracked?(path) = path_in?(untracked, path)

    # Returns the {Git::StatusFileInfo} for the given path
    #
    # The path is matched exactly, regardless of `ignore_case`.
    #
    # @example Look up a path
    #   repo.status_info['lib/foo.rb'] #=> #<data Git::StatusFileInfo path="lib/foo.rb", ...>
    #   repo.status_info['clean.rb']   #=> nil
    #
    # @param path [String] the repository-relative path
    #
    # @return [Git::StatusFileInfo, nil] the file, or `nil` when git did not report it
    #
    def [](path) = files.find { |file| file.path == path }

    private

    # Returns the files for which the block is truthy, keyed by path
    #
    # @return [Hash{String => Git::StatusFileInfo}] the selected files keyed by path
    #
    # @yield [file] each {Git::StatusFileInfo} in `files`
    #
    # @yieldparam file [Git::StatusFileInfo] one reported path
    #
    # @yieldreturn [Boolean] truthy to include the file
    #
    def files_by_path(&) = files.select(&).to_h { |file| [file.path, file] }

    # Returns `true` when `path` is a key of `collection`, honoring `ignore_case`
    #
    # @param collection [Hash{String => Git::StatusFileInfo}] files keyed by path
    #
    # @param path [String] the repository-relative path to look for
    #
    # @return [Boolean] `true` when the path is present
    #
    def path_in?(collection, path)
      return collection.key?(path) unless ignore_case

      collection.each_key.any? { |key| key.casecmp?(path) }
    end
  end
end
