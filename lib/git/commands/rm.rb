# frozen_string_literal: true

require 'git/commands/arguments'

module Git
  module Commands
    # Implements the `git rm` command
    #
    # This command removes files from the working tree and from the index.
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
    #   rm.call('directory', recursive: true)
    #
    # @example Remove from the index only (keep working tree copy)
    #   rm = Git::Commands::Rm.new(execution_context)
    #   rm.call('file.txt', cached: true)
    #
    # @example Force removal of modified files
    #   rm = Git::Commands::Rm.new(execution_context)
    #   rm.call('modified_file.txt', force: true)
    #
    class Rm
      # Arguments DSL for building command-line arguments
      ARGS = Arguments.define do
        static 'rm'
        flag :force, args: '-f'
        flag :recursive, args: '-r'
        flag :cached
        positional :paths, variadic: true, required: true, separator: '--'
      end.freeze

      # Initialize the Rm command
      #
      # @param execution_context [Git::ExecutionContext, Git::Lib] the context for executing git commands
      #
      def initialize(execution_context)
        @execution_context = execution_context
      end

      # Execute the git rm command
      #
      # @overload call(*paths, **options)
      #
      #   @param paths [Array<String>] files or directories to be removed from the repository
      #     (relative to the worktree root). At least one path is required.
      #
      #   @param options [Hash] command options
      #
      #   @option options [Boolean] :force (nil) Override the up-to-date check and remove files with
      #     local modifications. Without this, git rm will refuse to remove files that have
      #     uncommitted changes.
      #
      #   @option options [Boolean] :recursive (nil) Remove directories and their contents recursively
      #
      #   @option options [Boolean] :cached (nil) Only remove from the index, keeping the working tree files
      #
      # @raise [Git::FailedError] if the git command fails (e.g., no paths provided)
      #
      # @return [Git::CommandLineResult] the result of the command
      #
      def call(*, **)
        args = ARGS.bind(*, **)
        @execution_context.command(*args)
      end
    end
  end
end
