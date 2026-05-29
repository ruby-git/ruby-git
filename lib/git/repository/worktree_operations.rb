# frozen_string_literal: true

require 'git/commands/worktree'

module Git
  class Repository
    # Facade methods for worktree operations
    #
    # Included by {Git::Repository}.
    #
    # @api public
    #
    module WorktreeOperations
      # Returns all worktrees as an array of directory and SHA pairs
      #
      # Lists all worktrees attached to the repository, including the main
      # worktree and all linked worktrees. The output is parsed from
      # `git worktree list --porcelain`.
      #
      # @example List all worktrees
      #   repo.worktrees_all
      #   #=> [["/path/to/main", "4bef5ab..."], ["/tmp/worktree-1", "b8c6320..."]]
      #
      # @return [Array<Array(String, String)>] array of `[directory, sha]` pairs
      #
      #   `directory` is the worktree path reported by git (absolute or relative,
      #   depending on repository configuration); `sha` is the full SHA of the
      #   checked-out HEAD commit
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      # @see https://git-scm.com/docs/git-worktree git-worktree documentation
      #
      def worktrees_all
        worktree_entries = []
        current_directory = ''
        command_output = Git::Commands::Worktree::List.new(@execution_context).call(porcelain: true).stdout

        command_output.each_line(chomp: true) do |line|
          key, value = line.split(' ', 2)
          current_directory = value if key == 'worktree'
          worktree_entries << [current_directory, value] if key == 'HEAD'
        end

        worktree_entries
      end

      # Create a new linked worktree at the given directory
      #
      # @example Create a worktree at a path (auto-creates a branch)
      #   repo.worktree_add('/tmp/feature')
      #
      # @example Create a worktree and check out an existing commitish
      #   repo.worktree_add('/tmp/hotfix', 'main')
      #
      # @param dir [String] filesystem path for the new worktree
      #
      # @param commitish [String, nil] branch, tag, or commit to check out
      #
      #   When `nil`, git creates a new branch named after the final path component
      #
      # @return [String] the output from the git worktree add command
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      # @see https://git-scm.com/docs/git-worktree git-worktree documentation
      #
      def worktree_add(dir, commitish = nil)
        args = [dir]
        args << commitish unless commitish.nil?

        Git::Commands::Worktree::Add.new(@execution_context).call(*args).stdout
      end

      # Remove a linked worktree
      #
      # @example Remove a worktree
      #   repo.worktree_remove('/tmp/feature')
      #
      # @param dir [String] filesystem path of the worktree to remove
      #
      # @return [String] the output from the git worktree remove command
      #   (typically empty)
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      # @see https://git-scm.com/docs/git-worktree git-worktree documentation
      #
      def worktree_remove(dir)
        Git::Commands::Worktree::Remove.new(@execution_context).call(dir).stdout
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
