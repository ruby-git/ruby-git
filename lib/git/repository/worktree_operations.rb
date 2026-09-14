# frozen_string_literal: true

require 'git/commands/worktree'
require 'git/parsers/worktree'
require 'git/worktree_info'

module Git
  class Repository
    # Facade methods for worktree operations: listing, adding, removing, moving,
    # locking, repairing, and pruning worktrees
    #
    # Included by {Git::Repository}.
    #
    # @api private
    #
    module WorktreeOperations
      # Returns every worktree attached to the repository
      #
      # Lists the main worktree first, then each linked worktree, in the order
      # git reports them. The main worktree of a bare repository is included
      # with {Git::WorktreeInfo#bare?} true and no head or branch.
      #
      # @example List all worktrees
      #   repo.worktree_list.map(&:path)
      #   #=> ["/path/to/main", "/tmp/feature"]
      #
      # @example Find the worktree that has a branch checked out
      #   info = repo.worktree_list.find { |w| w.branch == 'refs/heads/feature' }
      #   info.path     #=> "/tmp/feature"
      #   info.head     #=> "b8c63202c3c0ebd37b7e45fd0c22e6c20d5bead1"
      #   info.locked?  #=> false
      #
      # @return [Array<Git::WorktreeInfo>] one entry per worktree
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      # @raise [Git::UnexpectedResultError] if the worktree listing cannot be
      #   parsed
      #
      # @see https://git-scm.com/docs/git-worktree git-worktree documentation
      #
      def worktree_list
        result = Git::Commands::Worktree::List.new(@execution_context).call(porcelain: true)
        Git::Parsers::Worktree.parse_list(result.stdout)
      end

      # Create a new linked worktree at the given directory
      #
      # Returns the entry that {#worktree_list} reports for the new worktree.
      # Its `path` is the directory as git records it: absolute, with symlinks
      # resolved, so `/tmp/feature` on macOS comes back as
      # `/private/tmp/feature`.
      #
      # @example Create a worktree at a path (auto-creates a branch)
      #   info = repo.worktree_add('/tmp/feature')
      #   info.path    #=> "/private/tmp/feature"
      #   info.branch  #=> "refs/heads/feature"
      #
      # @example Create a worktree and check out an existing commitish
      #   repo.worktree_add('/tmp/hotfix', 'main').head
      #   #=> "4bef5ab0c8e7c19c6be2c0f55ccd45eec1f3d32a"
      #
      # @param dir [String] filesystem path for the new worktree, absolute or
      #   relative to the current directory
      #
      # @param commitish [String, nil] branch, tag, or commit to check out
      #
      #   When `nil`, git checks out the branch named after the final path
      #   component, creating it when no such branch exists
      #
      # @return [Git::WorktreeInfo] the new worktree's entry from {#worktree_list}
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      # @raise [Git::UnexpectedResultError] if the worktree listing cannot be
      #   parsed or does not contain an entry for the new worktree's directory
      #   (for example, it was removed by another process before the lookup)
      #
      # @note When `commitish` is `nil` and git creates the branch, it does so
      #   before it creates the worktree, so a failure after that point leaves
      #   the new branch in place without a worktree. A branch that already
      #   existed is left as it was.
      #
      # @see https://git-scm.com/docs/git-worktree git-worktree documentation
      #
      def worktree_add(dir, commitish = nil)
        args = [dir]
        args << commitish unless commitish.nil?

        Git::Commands::Worktree::Add.new(@execution_context).call(*args)

        # git records the path as given with symlinks resolved, so compare by
        # identity rather than by string: this covers symlinks, case-insensitive
        # filesystems, and Unicode normalization on macOS
        worktree_list.find { |worktree| File.identical?(worktree.path, dir) } ||
          raise(Git::UnexpectedResultError, "worktree was created but not found in the worktree list: #{dir}")
      end

      # Remove a linked worktree
      #
      # @example Remove a worktree by path
      #   repo.worktree_remove('/tmp/feature')
      #
      # @example Remove a worktree from the list
      #   info = repo.worktree_list.find { |w| w.branch == 'refs/heads/feature' }
      #   repo.worktree_remove(info)
      #
      # @param worktree [String, Git::WorktreeInfo] the path of the worktree to
      #   remove, or its entry from {#worktree_list}
      #
      # @return [String] the output from the git worktree remove command
      #   (typically empty)
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      # @see https://git-scm.com/docs/git-worktree git-worktree documentation
      #
      def worktree_remove(worktree)
        Git::Commands::Worktree::Remove.new(@execution_context).call(worktree.to_s).stdout
      end

      # Move a linked worktree to a new location
      #
      # @example Move a worktree
      #   repo.worktree_move('/tmp/feature', '/tmp/feature-moved')
      #
      # @example Move a locked worktree
      #   repo.worktree_move('/tmp/feature', '/tmp/feature-moved', force: 2)
      #
      # @param worktree [String, Git::WorktreeInfo] the path of the worktree to
      #   move, or its entry from {#worktree_list}
      #
      # @param new_path [String] the destination path
      #
      # @param opts [Hash] options for the move
      #
      # @option opts [Boolean, Integer, nil] :force (nil) override git's
      #   safeguards; git refuses to move a locked worktree unless the flag is
      #   given twice, so pass `2` for that
      #
      # @return [String] the output from the git worktree move command
      #   (typically empty)
      #
      # @raise [ArgumentError] if unsupported options are provided
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      # @see https://git-scm.com/docs/git-worktree git-worktree documentation
      #
      def worktree_move(worktree, new_path, opts = {})
        Git::Commands::Worktree::Move.new(@execution_context).call(worktree.to_s, new_path, **opts).stdout
      end

      # Lock a linked worktree so that `git worktree prune` leaves it alone
      #
      # Lock a worktree whose directory is on removable media or a network
      # share that is not always mounted.
      #
      # @example Lock a worktree
      #   repo.worktree_lock('/tmp/feature')
      #
      # @example Lock a worktree with a reason
      #   repo.worktree_lock('/tmp/feature', reason: 'on an external drive')
      #
      # @param worktree [String, Git::WorktreeInfo] the path of the worktree to
      #   lock, or its entry from {#worktree_list}
      #
      # @param opts [Hash] options for the lock
      #
      # @option opts [String, nil] :reason (nil) an explanation stored with the
      #   lock and reported as {Git::WorktreeInfo#lock_reason}
      #
      # @return [String] the output from the git worktree lock command
      #   (typically empty)
      #
      # @raise [ArgumentError] if unsupported options are provided
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      # @see https://git-scm.com/docs/git-worktree git-worktree documentation
      #
      def worktree_lock(worktree, opts = {})
        Git::Commands::Worktree::Lock.new(@execution_context).call(worktree.to_s, **opts).stdout
      end

      # Unlock a linked worktree
      #
      # @example Unlock a worktree
      #   repo.worktree_unlock('/tmp/feature')
      #
      # @param worktree [String, Git::WorktreeInfo] the path of the worktree to
      #   unlock, or its entry from {#worktree_list}
      #
      # @return [String] the output from the git worktree unlock command
      #   (typically empty)
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      # @see https://git-scm.com/docs/git-worktree git-worktree documentation
      #
      def worktree_unlock(worktree)
        Git::Commands::Worktree::Unlock.new(@execution_context).call(worktree.to_s).stdout
      end

      # Repair the links between the repository and its linked worktrees
      #
      # With no paths, repairs the link from each linked worktree back to the
      # repository, which is needed after the repository directory was moved.
      # Given the current paths of linked worktrees that were moved without
      # {#worktree_move}, also repairs the repository's links to them.
      #
      # @example Repair after the repository directory was moved
      #   repo.worktree_repair
      #
      # @example Repair after a linked worktree was moved by hand
      #   repo.worktree_repair('/new/path/to/feature')
      #
      # @param paths [Array<String, Git::WorktreeInfo>] the current paths of the
      #   worktrees to repair, or their entries from {#worktree_list}
      #
      # @return [String] the output from the git worktree repair command, which
      #   reports each repair made
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      # @see https://git-scm.com/docs/git-worktree git-worktree documentation
      #
      def worktree_repair(*paths)
        Git::Commands::Worktree::Repair.new(@execution_context).call(*paths.map(&:to_s)).stdout
      end

      # Prune stale worktree administrative files
      #
      # Removes stale administrative files from `$GIT_DIR/worktrees`. A
      # worktree becomes stale when its directory no longer exists on disk.
      #
      # @example Prune stale worktrees
      #   repo.worktree_prune
      #
      # @return [String] the output from the git worktree prune command
      #   (typically empty)
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      # @see https://git-scm.com/docs/git-worktree git-worktree documentation
      #
      def worktree_prune
        Git::Commands::Worktree::Prune.new(@execution_context).call.stdout
      end
    end
  end
end
