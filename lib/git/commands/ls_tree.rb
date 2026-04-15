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
    # @see https://git-scm.com/docs/git-ls-tree git-ls-tree documentation
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

        operand :tree_ish, required: true

        end_of_options

        operand :path, repeatable: true
      end

      # @!method call(*, **)
      #
      #   @overload call(tree_ish, *path, **options)
      #
      #     Execute the git ls-tree command
      #
      #     @param tree_ish [String] The tree object to list (SHA, branch name, tag, etc.)
      #
      #     @param path [Array<String>] Optional path(s) to restrict the listing. When given,
      #       only entries matching these paths are shown.
      #
      #     @param options [Hash] command options
      #
      #     @option options [Boolean] :d (nil) Show only the named tree entry itself, not its
      #       children. Only meaningful together with `:r`.
      #
      #     @option options [Boolean] :r (nil) Recurse into sub-trees.
      #
      #     @option options [Boolean] :t (nil) Show tree entries even when going to recurse
      #       or truncate to a directory that would be shown in combination with `-r`.
      #       Has no effect if `-r` was not passed. `-t` implies `-r`.
      #
      #     @option options [Boolean] :long (nil) Show object size of blob (file) objects.
      #       Cannot be combined with `:name_only` or `:object_only`.
      #
      #       Alias: :l
      #
      #     @option options [Boolean] :z (nil) Use NUL (`\0`) as line terminator instead of
      #       newline, and do not quote filenames.
      #
      #     @option options [Boolean] :name_only (nil) List only filenames, one per line.
      #       Cannot be combined with `:long`.
      #
      #       Alias: :name_status
      #
      #     @option options [Boolean] :object_only (nil) List only the object names (SHAs),
      #       one per line. Cannot be combined with `:long` or `:name_only`.
      #
      #     @option options [Boolean] :full_name (nil) Show full path names instead of paths
      #       relative to the current working directory. Maps to `--full-name`.
      #
      #     @option options [Boolean] :full_tree (nil) Do not limit the listing to the current
      #       working directory. Implies `:full_name`. Maps to `--full-tree`.
      #
      #     @option options [Boolean, String] :abbrev (nil) When `true`, use git's default
      #       abbreviated object name length. When a string (e.g. `'8'`), use exactly that
      #       many hex digits. Maps to `--abbrev[=<n>]`.
      #
      #     @option options [String] :format (nil) A format string that interpolates
      #       `%(fieldname)` placeholders from tree entries. Maps to `--format=<format>`.
      #
      #     @return [Git::CommandLineResult] the result of calling `git ls-tree`
      #
      #     @raise [ArgumentError] if `:tree_ish` is not provided
      #
      #     @raise [ArgumentError] if unsupported options are provided
      #
      #     @raise [Git::FailedError] if the command returns a non-zero exit status
    end
  end
end
