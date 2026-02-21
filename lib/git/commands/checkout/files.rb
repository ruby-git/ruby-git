# frozen_string_literal: true

require 'git/commands/base'

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
      #   files.call(pathspec: ['file.txt'])
      #
      # @example Restore a file from HEAD
      #   files.call('HEAD', pathspec: ['file.txt'])
      #
      # @example Restore a file from a specific commit
      #   files.call('HEAD~1', pathspec: ['file.txt'])
      #
      # @example Restore multiple files from a branch
      #   files.call('main', pathspec: ['file1.txt', 'file2.txt'])
      #
      # @example Resolve merge conflict by choosing "ours" version
      #   files.call(pathspec: ['conflicted.txt'], ours: true)
      #
      # @example Read paths from a file
      #   files.call('main', pathspec_from_file: 'paths.txt')
      #
      class Files < Base
        arguments do
          literal 'checkout'
          flag_option %i[force f]
          flag_option :ours
          flag_option :theirs
          flag_option %i[merge m]
          value_option :conflict, inline: true
          flag_option :overlay, negatable: true
          value_option :pathspec_from_file, inline: true
          flag_option :pathspec_file_nul

          operand :tree_ish
          value_option :pathspec, as_operand: true, repeatable: true, separator: '--'
        end

        # Execute the git checkout command for restoring files
        #
        # @overload call(tree_ish = nil, pathspec: nil, **options)
        #
        #   @param tree_ish [String, nil] The commit, branch, or tree to restore
        #     files from. When nil, files are restored from the index.
        #
        #   @param pathspec [String, Array<String>, nil] The files or directories
        #     to restore. Required unless pathspec_from_file is provided.
        #
        #   @param options [Hash] command options
        #
        #   @option options [Array<String>, String] :pathspec The files or directories
        #     to restore. Required unless :pathspec_from_file is provided.
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
        #     ('-' for stdin). Required unless :pathspec is provided.
        #
        #   @option options [Boolean] :pathspec_file_nul (nil) NUL-separated paths in
        #     pathspec file
        #
        # @return [Git::CommandLineResult] the result of the command
        #
        # @raise [ArgumentError] if neither :pathspec nor :pathspec_from_file is provided
        #
        # @raise [Git::FailedError] if the checkout fails
        #
        def call(...) = super # rubocop:disable Lint/UselessMethodDefinition
      end
    end
  end
end
