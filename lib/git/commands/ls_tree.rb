# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    # Implements the `git ls-tree` command
    #
    # Lists the contents of a tree object, showing the mode, type, object
    # name, and file name of each item. Supports recursive listing, output
    # format control, and path filtering.
    #
    # @note `arguments` block audited against https://git-scm.com/docs/git-ls-tree/2.53.0
    #
    # @see https://git-scm.com/docs/git-ls-tree git-ls-tree
    #
    # @api private
    #
    # @example List the top-level tree of HEAD
    #   ls_tree = Git::Commands::LsTree.new(execution_context)
    #   ls_tree.call('HEAD')
    #
    # @example Recursively list all files under HEAD
    #   ls_tree = Git::Commands::LsTree.new(execution_context)
    #   ls_tree.call('HEAD', r: true)
    #
    # @example List only file names recursively
    #   ls_tree = Git::Commands::LsTree.new(execution_context)
    #   ls_tree.call('HEAD', r: true, name_only: true)
    #
    # @example List entries under a specific path
    #   ls_tree = Git::Commands::LsTree.new(execution_context)
    #   ls_tree.call('HEAD', 'lib/')
    #
    class LsTree < Git::Commands::Base
      arguments do
        literal 'ls-tree'

        # Listing behavior
        flag_option :d
        flag_option :r
        flag_option :t
        flag_option %i[long l]
        flag_option :z

        # Output format
        flag_option %i[name_only name_status]
        flag_option :object_only
        flag_option :full_name
        flag_option :full_tree
        flag_or_value_option :abbrev, inline: true
        value_option :format, inline: true

        end_of_options

        operand :tree_ish, required: true
        operand :path, repeatable: true
      end

      # @!method call(*, **)
      #
      #   @overload call(tree_ish, *path, **options)
      #
      #     Execute the git ls-tree command
      #
      #     @param tree_ish [String] the tree object to list (SHA, branch name, tag, etc.)
      #
      #     @param path [Array<String>] optional path(s) to restrict the listing
      #
      #       When given, only entries matching these paths are shown.
      #
      #     @param options [Hash] command options
      #
      #     @option options [Boolean] :d (false) show only the named tree entry itself,
      #       not its children
      #
      #     @option options [Boolean] :r (false) recurse into sub-trees
      #
      #     @option options [Boolean] :t (false) show tree entries even when going to
      #       recurse them
      #
      #       Implies recursive listing (`:r`) in git.
      #
      #     @option options [Boolean] :long (false) show object size of blob (file)
      #       objects
      #
      #       Cannot be combined with `:name_only` or `:object_only`.
      #
      #       Alias: :l
      #
      #     @option options [Boolean] :z (false) use NUL (`\0`) as line terminator
      #       instead of newline, and do not quote filenames
      #
      #     @option options [Boolean] :name_only (false) list only filenames, one per
      #       line
      #
      #       Cannot be combined with `:object_only` or `:long`.
      #
      #       Alias: :name_status
      #
      #     @option options [Boolean] :object_only (false) list only the object names
      #       (SHAs), one per line
      #
      #       Cannot be combined with `:name_only` or `:long`.
      #
      #     @option options [Boolean] :full_name (false) show full path names instead
      #       of paths relative to the current working directory
      #
      #     @option options [Boolean] :full_tree (false) do not limit the listing to
      #       the current working directory; implies `:full_name`
      #
      #     @option options [Boolean, String] :abbrev (nil) use abbreviated object names
      #
      #       When `true`, uses git's default abbreviated name length. When a string
      #       (e.g. `'8'`), uses exactly that many hex digits.
      #
      #     @option options [String] :format (nil) a format string that interpolates
      #       `%(fieldname)` placeholders from tree entries
      #
      #       Cannot be combined with `:long`, `:name_only`, or `:object_only`.
      #
      #     @return [Git::CommandLineResult] the result of calling `git ls-tree`
      #
      #     @raise [ArgumentError] if unsupported options are provided
      #
      #     @raise [ArgumentError] if the tree-ish operand is missing
      #
      #     @raise [Git::FailedError] if git exits with a non-zero exit status
    end
  end
end
