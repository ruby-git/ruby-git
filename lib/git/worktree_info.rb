# frozen_string_literal: true

module Git
  # Immutable value object for one entry of `git worktree list`
  #
  # Each entry carries what `git worktree list --porcelain` reports for a
  # worktree: its path, the checked-out HEAD and branch, and whether it is bare,
  # detached, locked, or prunable, with the reason git gives for the last two.
  #
  # @example A locked linked worktree with a branch checked out
  #   info = Git::WorktreeInfo.new(
  #     path: '/tmp/wt/linked',
  #     head: 'f3e2c1ffb860086504eeb27b77a1d0028b68fd8f',
  #     branch: 'refs/heads/linked',
  #     bare: false,
  #     detached: false,
  #     locked: true,
  #     lock_reason: 'on purpose',
  #     prunable: false,
  #     prune_reason: nil
  #   )
  #
  #   info.path         # => '/tmp/wt/linked'
  #   info.head         # => 'f3e2c1ffb860086504eeb27b77a1d0028b68fd8f'
  #   info.branch       # => 'refs/heads/linked'
  #   info.locked?      # => true
  #   info.lock_reason  # => 'on purpose'
  #   info.detached?    # => false
  #   info.to_s         # => '/tmp/wt/linked'
  #
  # @example Pass an entry back to a worktree operation
  #   info = repo.worktree_list.find { |w| w.branch == 'refs/heads/linked' }
  #   repo.worktree_remove(info)
  #
  # @see Git::Repository::WorktreeOperations#worktree_list for the repository
  #   method that returns these
  #
  # @api public
  #
  # @!attribute [r] path
  #   @return [String] the worktree directory as git reports it
  #
  # @!attribute [r] head
  #   @return [String, nil] the full object ID of the checked-out HEAD commit
  #     (the all-zero object ID when the branch has no commits yet), or nil for a
  #     bare main worktree
  #
  # @!attribute [r] branch
  #   @return [String, nil] the full refname of the checked-out branch (e.g.,
  #     'refs/heads/main'), or nil when the worktree is bare or detached
  #
  # @!attribute [r] bare
  #   @return [Boolean] true if this is the main worktree of a bare repository
  #
  # @!attribute [r] detached
  #   @return [Boolean] true if HEAD is detached in this worktree
  #
  # @!attribute [r] locked
  #   @return [Boolean] true if the worktree is locked
  #
  # @!attribute [r] lock_reason
  #   @return [String, nil] the reason given when the worktree was locked, or nil
  #     when it is not locked or was locked without a reason
  #
  # @!attribute [r] prunable
  #   @return [Boolean] true if `git worktree prune` would remove this entry
  #
  # @!attribute [r] prune_reason
  #   @return [String, nil] git's explanation of why the entry is prunable, or
  #     nil when it is not prunable
  #
  WorktreeInfo = Data.define(
    :path,
    :head,
    :branch,
    :bare,
    :detached,
    :locked,
    :lock_reason,
    :prunable,
    :prune_reason
  ) do
    # Whether this is the main worktree of a bare repository
    #
    # @example
    #   info.bare? # => false
    #
    # @return [Boolean] true if the worktree is bare
    def bare? = bare

    # Whether HEAD is detached in this worktree
    #
    # @example
    #   info.detached? # => false
    #
    # @return [Boolean] true if HEAD is detached
    def detached? = detached

    # Whether the worktree is locked
    #
    # @example
    #   info.locked? # => true
    #
    # @return [Boolean] true if the worktree is locked
    def locked? = locked

    # Whether `git worktree prune` would remove this entry
    #
    # @example
    #   info.prunable? # => false
    #
    # @return [Boolean] true if the entry is prunable
    def prunable? = prunable

    # Returns the worktree path
    #
    # Lets an entry be passed directly to the worktree operations that take a
    # path, such as {Git::Repository::WorktreeOperations#worktree_remove}.
    #
    # @example Convert to string
    #   info.to_s # => '/tmp/wt/linked'
    #
    # @return [String] the worktree path
    def to_s
      path
    end
  end
end
