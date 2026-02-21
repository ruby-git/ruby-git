# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    # Implements the `git rm` command
    #
    # This command removes files from the working tree and from the index.
    #
    # @see https://git-scm.com/docs/git-rm git-rm
    #
    # @api private
    #
    # @example Basic usage
    #   rm = Git::Commands::Rm.new(execution_context)
    #   rm.call('file.txt')
    #   rm.call('file1.txt', 'file2.txt')
    #
    # @example Remove a directory recursively
    #   rm = Git::Commands::Rm.new(execution_context)
    #   rm.call('directory', r: true)
    #
    # @example Remove from the index only (keep working tree copy)
    #   rm = Git::Commands::Rm.new(execution_context)
    #   rm.call('file.txt', cached: true)
    #
    # @example Force removal of modified files
    #   rm = Git::Commands::Rm.new(execution_context)
    #   rm.call('modified_file.txt', force: true)
    #
    class Rm < Git::Commands::Base
      arguments do
        literal 'rm'
        flag_option %i[force f]
        flag_option :r
        flag_option :cached
        operand :pathspec, repeatable: true, required: true, separator: '--'
      end

      # @!method call(*, **)
      #
      #   Execute the git rm command
      #
      #   @overload call(*pathspec, **options)
      #
      #     @param pathspec [Array<String>] files or directories to be removed from the repository
      #       (relative to the worktree root). At least one pathspec is required.
      #
      #     @param options [Hash] command options
      #
      #     @option options [Boolean] :force (nil) Override the up-to-date check and remove files with
      #       local modifications. Without this, git rm will refuse to remove files that have
      #       uncommitted changes. Alias: :f
      #
      #     @option options [Boolean] :r (nil) Remove directories and their contents recursively
      #
      #     @option options [Boolean] :cached (nil) Only remove from the index, keeping the working tree files
      #
      #     @return [Git::CommandLineResult] the result of calling `git rm`
      #
      #     @raise [Git::FailedError] if the git command fails (e.g., no paths provided)
    end
  end
end
