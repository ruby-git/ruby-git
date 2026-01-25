# frozen_string_literal: true

require 'git/commands/arguments'

module Git
  module Commands
    module Checkout
      # Implements the `git checkout` command for restoring working tree files
      #
      # This command replaces files in the working tree with versions from
      # the index (when tree_ish is nil) or a specified tree-ish (commit,
      # branch, tag, etc.).
      #
      # @see https://git-scm.com/docs/git-checkout git-checkout
      #
      # @api private
      #
      # @example Restore a file from the index (discard uncommitted changes)
      #   files = Git::Commands::Checkout::Files.new(execution_context)
      #   files.call(nil, 'file.txt')
      #
      # @example Restore a file from HEAD
      #   files.call('HEAD', 'file.txt')
      #
      # @example Restore a file from a specific commit
      #   files.call('HEAD~1', 'file.txt')
      #
      # @example Restore multiple files from a branch
      #   files.call('main', 'file1.txt', 'file2.txt')
      #
      # @example Resolve merge conflict by choosing "ours" version
      #   files.call(nil, 'conflicted.txt', ours: true)
      #
      # @example Read paths from a file
      #   files.call('main', pathspec_from_file: 'paths.txt')
      #
      class Files
        # Arguments DSL for building command-line arguments
        #
        # NOTE: The order of definitions determines the order of arguments
        # in the final command line.
        #
        ARGS = Arguments.define do
          flag %i[force f], args: '--force'
          flag :ours, args: '--ours'
          flag :theirs, args: '--theirs'
          flag %i[merge m], args: '--merge'
          inline_value :conflict, args: '--conflict'
          negatable_flag :overlay
          inline_value :pathspec_from_file, args: '--pathspec-from-file'
          flag :pathspec_file_nul, args: '--pathspec-file-nul'

          positional :tree_ish, required: true, allow_nil: true
          positional :paths, variadic: true, separator: '--'
        end.freeze

        # Initialize the Files command
        #
        # @param execution_context [Git::ExecutionContext, Git::Lib] the context for executing git commands
        #
        def initialize(execution_context)
          @execution_context = execution_context
        end

        # Execute the git checkout command for restoring files
        #
        # @overload call(tree_ish, *paths, **options)
        #
        #   @param tree_ish [String, nil] The commit, branch, or tree to restore
        #     files from. When nil, files are restored from the index.
        #
        #   @param paths [Array<String>] The files or directories to restore.
        #     Required unless pathspec_from_file is provided.
        #
        #   @param options [Hash] command options
        #
        #   @option options [Boolean] :force (nil) Ignore unmerged entries. Alias: :f
        #
        #   @option options [Boolean] :ours (nil) For unmerged paths, use stage #2
        #
        #   @option options [Boolean] :theirs (nil) For unmerged paths, use stage #3
        #
        #   @option options [Boolean] :merge (nil) Recreate the conflicted merge.
        #     Alias: :m
        #
        #   @option options [String] :conflict (nil) Conflict marker style: 'merge',
        #     'diff3', 'zdiff3'
        #
        #   @option options [Boolean] :overlay (nil) true for --overlay, false for
        #     --no-overlay
        #
        #   @option options [String] :pathspec_from_file (nil) Read paths from file
        #     ('-' for stdin)
        #
        #   @option options [Boolean] :pathspec_file_nul (nil) NUL-separated paths in
        #     pathspec file
        #
        # @return [String] the command output (typically empty on success)
        #
        # @raise [Git::FailedError] if the checkout fails
        #
        def call(*, **)
          args = ARGS.build(*, **)
          @execution_context.command('checkout', *args)
        end
      end
    end
  end
end
