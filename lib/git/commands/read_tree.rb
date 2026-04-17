# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    # Implements the `git read-tree` command
    #
    # Reads tree information into the index. Optionally performs a merge
    # (single-tree, two-way fast-forward, or three-way) with the `-m` flag,
    # and updates the working tree files with `-u`.
    #
    # @example Read a single tree into the index
    #   read_tree = Git::Commands::ReadTree.new(execution_context)
    #   result = read_tree.call('HEAD')
    #
    # @example Read a tree under a prefix directory
    #   read_tree = Git::Commands::ReadTree.new(execution_context)
    #   result = read_tree.call('HEAD', prefix: 'subdir/')
    #
    # @example Perform a three-way merge
    #   read_tree = Git::Commands::ReadTree.new(execution_context)
    #   result = read_tree.call('base', 'ours', 'theirs', m: true, u: true)
    #
    # @example Empty the index
    #   read_tree = Git::Commands::ReadTree.new(execution_context)
    #   result = read_tree.call(empty: true)
    #
    # @note `arguments` block audited against https://git-scm.com/docs/git-read-tree/2.53.0
    #
    # @see https://git-scm.com/docs/git-read-tree git-read-tree
    #
    # @see Git::Commands
    #
    # @api private
    #
    class ReadTree < Git::Commands::Base
      arguments do
        literal 'read-tree'

        # Merge mode
        flag_option :m
        flag_option :trivial
        flag_option :aggressive
        flag_option :reset
        value_option :prefix, inline: true

        # Working tree update
        flag_option :u
        flag_option :i

        # Dry run and progress
        flag_option %i[dry_run n]
        flag_option :v

        # Filtering and output
        value_option :index_output, inline: true
        flag_option :recurse_submodules, negatable: true
        flag_option :no_sparse_checkout
        flag_option :empty

        # Feedback control
        flag_option %i[quiet q]

        end_of_options

        operand :tree_ish, repeatable: true
      end

      # @!method call(*, **)
      #
      #   @overload call(*tree_ish, **options)
      #
      #     Execute the `git read-tree` command
      #
      #     @param tree_ish [Array<String>] zero or more tree-ish objects to
      #       read into the index
      #
      #       Pass one tree-ish for a simple read or single-tree merge, two
      #       for a fast-forward (two-way) merge, or three for a three-way
      #       merge. Omit when using the `:empty` option.
      #
      #     @param options [Hash] command options
      #
      #     @option options [Boolean] :m (false) perform a merge, not just a
      #       read
      #
      #     @option options [Boolean] :trivial (false) restrict three-way merge
      #       to happen only if there is no file-level merging required
      #
      #     @option options [Boolean] :aggressive (false) resolve a few more
      #       three-way merge cases internally beyond the trivial defaults
      #
      #     @option options [Boolean] :reset (false) same as `-m`, except that
      #       unmerged entries are discarded instead of failing
      #
      #     @option options [String] :prefix (nil) keep the current index
      #       contents, and read the named tree-ish under the directory at
      #       the given prefix
      #
      #       Maps to `--prefix=<prefix>`.
      #
      #     @option options [Boolean] :u (false) after a successful merge,
      #       update the files in the work tree with the result
      #
      #     @option options [Boolean] :i (false) disable the check with the
      #       working tree, meant for creating a merge of trees not directly
      #       related to the current working tree status
      #
      #     @option options [Boolean] :dry_run (false) check if the command
      #       would error out, without updating the index or files for real
      #
      #       Alias: `:n`
      #
      #     @option options [Boolean] :v (false) show the progress of checking
      #       files out
      #
      #     @option options [String] :index_output (nil) write the resulting
      #       index in the named file instead of `$GIT_INDEX_FILE`
      #
      #       Maps to `--index-output=<file>`.
      #
      #     @option options [Boolean] :recurse_submodules (nil) update the
      #       content of all active submodules according to the commit
      #       recorded in the superproject
      #
      #       Pass `true` to emit `--recurse-submodules`; pass `false` to emit
      #       `--no-recurse-submodules`.
      #
      #     @option options [Boolean] :no_sparse_checkout (false) disable
      #       sparse checkout support even if `core.sparseCheckout` is true
      #
      #     @option options [Boolean] :empty (false) empty the index instead of
      #       reading tree object(s)
      #
      #     @option options [Boolean] :quiet (false) suppress feedback messages
      #
      #       Alias: `:q`
      #
      #     @return [Git::CommandLineResult] the result of calling
      #       `git read-tree`
      #
      #     @raise [ArgumentError] if unsupported options are provided
      #
      #     @raise [Git::FailedError] if git exits with a non-zero exit
      #       status
    end
  end
end
