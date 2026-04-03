# frozen_string_literal: true

module Git
  module Commands
    # Implements `git worktree` subcommands for managing multiple working trees
    #
    # Split into subclasses because each subcommand has a distinct call shape
    # and option set:
    #
    # - {Worktree::Add} — create a new linked worktree
    # - {Worktree::List} — list all worktrees
    # - {Worktree::Lock} — prevent a worktree from being pruned
    # - {Worktree::Move} — move a worktree to a new location
    # - {Worktree::Prune} — prune stale worktree administrative files
    # - {Worktree::Remove} — remove a worktree
    # - {Worktree::Repair} — repair worktree administrative files
    # - {Worktree::Unlock} — allow a worktree to be pruned
    #
    # Management subcommands ({Add}, {Lock}, {Move}, {Prune}, {Remove},
    # {Repair}, {Unlock}) inherit from {Worktree::ManagementBase}, which
    # unconditionally unsets `GIT_INDEX_FILE` in the subprocess environment.
    # Git worktrees maintain their own index files; leaving `GIT_INDEX_FILE`
    # set causes silent corruption of both the main and the linked worktree
    # indexes.
    #
    # @see https://git-scm.com/docs/git-worktree git-worktree documentation
    #
    # @api private
    #
    module Worktree
    end
  end
end
