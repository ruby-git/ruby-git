# frozen_string_literal: true

module Git
  # A worktree in a Git repository
  #
  # Represents a single linked or main worktree. Constructed by
  # {Git::Repository::WorktreeOperations#worktree} or populated by
  # {Git::Worktrees}.
  #
  # @example Add and remove a linked worktree
  #   worktree = repo.worktree('/path/to/new-worktree')
  #   worktree.add
  #   worktree.remove
  #
  # @deprecated Use {Git::Repository::WorktreeOperations#worktree_list} and the
  #   path-based worktree operations on {Git::Repository} instead
  #
  #   {Git::Repository::WorktreeOperations#worktree_list} returns immutable
  #   {Git::WorktreeInfo} value objects. Operations that lived on this class are
  #   called on the repository with the worktree path instead (for example
  #   {Git::Repository::WorktreeOperations#worktree_add} and
  #   {Git::Repository::WorktreeOperations#worktree_remove}). {#gcommit},
  #   {#add}, and {#remove} each emit a deprecation warning; the `dir`, `full`,
  #   `to_s`, and `to_a` readers do not.
  #
  # @api public
  #
  class Worktree
    # Full worktree descriptor including the optional commitish
    #
    # @return [String] the filesystem path, space-separated with the commitish
    #   when one was given at construction time
    #
    attr_accessor :full

    # Filesystem path of this worktree
    #
    # @return [String] the filesystem path of the worktree directory
    #
    attr_accessor :dir

    # Creates a new Worktree object
    #
    # @param base [Git::Repository] the repository that owns this
    #   worktree
    #
    # @param dir [String] filesystem path of the worktree
    #
    # @param gcommit [String, nil] commitish associated with the worktree;
    #   when non-nil it is appended to {#full}
    #
    # @return [void]
    #
    def initialize(base, dir, gcommit = nil)
      @full = dir
      @full += " #{gcommit}" unless gcommit.nil?
      @base = base
      @dir = dir
      @gcommit = gcommit
    end

    # Returns the commit (or commitish string) associated with this worktree
    #
    # When a commitish string was supplied at construction time (e.g. by
    # {Git::Worktrees} which passes the raw SHA from `git worktree list`), that
    # string is returned as-is. Otherwise the value is lazily resolved on first
    # call via `worktree_repository.gcommit(@full)` and the result is memoized.
    #
    # @example When resolved lazily (no commitish at construction)
    #   worktree = repo.worktree('/path/to/wt')
    #   worktree.gcommit  # => #<Git::Object::Commit ...>
    #
    # @example When the commitish was given at construction
    #   worktree = repo.worktrees['/path/to/wt']
    #   worktree.gcommit  # => "4bef5ab8c9..."   (raw SHA string)
    #
    # @return [Git::Object::Commit, String] a commit object when lazily
    #   resolved, or the raw commitish string when pre-set at construction
    #
    # @raise [Git::FailedError] if git must resolve the commit and exits with a
    #   non-zero exit status
    #
    # @deprecated Use {Git::WorktreeInfo#head} from
    #   {Git::Repository::WorktreeOperations#worktree_list} instead
    #
    #   `head` is always the commit SHA as a `String` (or `nil` for a bare main
    #   worktree). Call `repo.gcommit(info.head)` for the commit object.
    #
    # @see Git::WorktreeInfo#head
    #
    def gcommit
      Git::Deprecation.warn(
        'Git::Worktree#gcommit is deprecated and will be removed in v6.0.0. ' \
        'Use Git::WorktreeInfo#head from Git::Repository#worktree_list instead.'
      )
      @gcommit ||= worktree_repository.gcommit(@full)
      @gcommit
    end

    # Creates this worktree on disk
    #
    # Runs `git worktree add` for {#dir}, optionally at the commitish passed
    # at construction time.
    #
    # @example Add a worktree
    #   worktree = repo.worktree('/path/to/new-worktree')
    #   worktree.add
    #
    # @return [String] stdout from the git command
    #
    # @raise [Git::FailedError] if git exits with a non-zero exit status
    #
    # @deprecated Use {Git::Repository::WorktreeOperations#worktree_add} instead
    #
    # @see Git::Repository::WorktreeOperations#worktree_add
    #
    def add
      Git::Deprecation.warn(
        'Git::Worktree#add is deprecated and will be removed in v6.0.0. ' \
        'Use Git::Repository#worktree_add instead.'
      )
      worktree_repository.worktree_add(@dir, @gcommit)
    end

    # Removes this worktree from disk
    #
    # Runs `git worktree remove` for {#dir}.
    #
    # @example Remove a worktree
    #   worktree.remove
    #
    # @return [String] stdout from the git command (typically empty)
    #
    # @raise [Git::FailedError] if git exits with a non-zero exit status
    #
    # @deprecated Use {Git::Repository::WorktreeOperations#worktree_remove} instead
    #
    # @see Git::Repository::WorktreeOperations#worktree_remove
    #
    def remove
      Git::Deprecation.warn(
        'Git::Worktree#remove is deprecated and will be removed in v6.0.0. ' \
        'Use Git::Repository#worktree_remove instead.'
      )
      worktree_repository.worktree_remove(@dir)
    end

    # Returns an array containing the full worktree descriptor
    #
    # @example Get the descriptor array
    #   worktree.to_a  # => ["/path/to/worktree"]
    #
    # @return [Array<String>] array containing the full worktree descriptor
    #
    def to_a
      [@full]
    end

    # Returns the full worktree descriptor as a string
    #
    # @example Get the descriptor string
    #   worktree.to_s  # => "/path/to/worktree"
    #
    # @return [String] the full worktree descriptor (path and optional commitish)
    #
    def to_s
      @full
    end

    private

    # @return [Git::Repository] the repository used for worktree operations
    #
    # @api private
    #
    def worktree_repository
      @base
    end
  end
end
