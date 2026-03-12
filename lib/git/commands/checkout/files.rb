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
      # @see Git::Commands
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
      class Files < Git::Commands::Base
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
          end_of_options
          value_option :pathspec, as_operand: true, repeatable: true
        end

        # @!method call(*, **)
        #
        #   @overload call(tree_ish = nil, **options)
        #
        #     Execute the git checkout command for restoring files
        #
        #     @param tree_ish [String, nil] The commit, branch, or tree to restore
        #       files from
        #
        #       When `nil`, files are restored from the index
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean] :force (nil) Ignore unmerged entries
        #
        #       Alias: `:f`
        #
        #     @option options [Boolean] :ours (nil) For unmerged paths, use stage #2
        #
        #     @option options [Boolean] :theirs (nil) For unmerged paths, use stage #3
        #
        #     @option options [Boolean] :merge (nil) Recreate the conflicted merge
        #
        #       Alias: `:m`
        #
        #     @option options [String] :conflict (nil) Conflict marker style:
        #       `merge`, `diff3`, or `zdiff3`
        #
        #     @option options [Boolean] :overlay (nil) Use `true` for `--overlay`,
        #       `false` for `--no-overlay`
        #
        #     @option options [String] :pathspec_from_file (nil) Read paths from file
        #       (`'-'` for stdin)
        #
        #       Required unless `:pathspec` is provided
        #
        #     @option options [Boolean] :pathspec_file_nul (nil) NUL-separated paths in
        #       pathspec file
        #
        #     @option options [Array<String>, String] :pathspec The files or directories
        #       to restore
        #
        #       Required unless `:pathspec_from_file` is provided
        #
        #     @return [Git::CommandLineResult] the result of calling `git checkout`
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
        #
        #   @api public
        #
      end
    end
  end
end
