# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    # Implements the `git diff-index` command
    #
    # Compares a tree object to either the index or the working tree.
    #
    # When `--cached` is given (`cached: true`) it compares the tree to the index
    # (staged changes). Without `--cached` it compares the tree to the working tree,
    # treating any file that differs from the index as changed even if the on-disk
    # content is identical to the tree.
    #
    # @example Compare HEAD tree to the working tree (raw output)
    #   # git diff-index HEAD
    #   Git::Commands::DiffIndex.new(ctx).call('HEAD')
    #
    # @example Compare HEAD tree to the index (staged changes, raw output)
    #   # git diff-index --cached HEAD
    #   Git::Commands::DiffIndex.new(ctx).call('HEAD', cached: true)
    #
    # @example Compare HEAD tree to the index, showing a patch
    #   # git diff-index --cached --patch HEAD
    #   Git::Commands::DiffIndex.new(ctx).call('HEAD', cached: true, patch: true)
    #
    # @example Limit comparison to a specific path
    #   # git diff-index --cached HEAD -- lib/
    #   Git::Commands::DiffIndex.new(ctx).call('HEAD', 'lib/', cached: true)
    #
    # @note `arguments` block audited against https://git-scm.com/docs/git-diff-index/2.53.0
    #
    # @see https://git-scm.com/docs/git-diff-index git-diff-index documentation
    #
    # @see Git::Commands
    #
    # @api private
    #
    class DiffIndex < Git::Commands::Base
      arguments do
        literal 'diff-index'

        # diff-index-specific options
        flag_option :m
        flag_option :cached
        flag_option :merge_base

        # Output format selection
        flag_option %i[patch p u]
        flag_option %i[no_patch s]
        flag_option :raw
        flag_option :patch_with_raw
        value_option %i[unified U], inline: true
        value_option :output, inline: true
        value_option :output_indicator_new, inline: true
        value_option :output_indicator_old, inline: true
        value_option :output_indicator_context, inline: true

        # Diff algorithm
        flag_option :indent_heuristic, negatable: true
        flag_option :minimal
        flag_option :patience
        flag_option :histogram
        value_option :anchored, inline: true, repeatable: true
        value_option :diff_algorithm, inline: true

        # Statistics output formats
        flag_or_value_option :stat, inline: true
        value_option :stat_width, inline: true
        value_option :stat_name_width, inline: true
        value_option :stat_graph_width, inline: true
        value_option :stat_count, inline: true
        flag_option :compact_summary
        flag_option :numstat
        flag_option :shortstat
        flag_or_value_option %i[dirstat X], inline: true
        flag_option :cumulative
        flag_or_value_option :dirstat_by_file, inline: true
        flag_option :summary
        flag_option :patch_with_stat

        # Name and path display
        flag_option :z
        flag_option :name_only
        flag_option :name_status
        flag_or_value_option :submodule, inline: true

        # Color output
        flag_or_value_option :color, inline: true, negatable: true
        flag_or_value_option :color_moved, inline: true, negatable: true
        value_option :color_moved_ws, inline: true
        flag_option :no_color_moved_ws

        # Word diff
        flag_or_value_option :word_diff, inline: true
        value_option :word_diff_regex, inline: true
        flag_or_value_option :color_words, inline: true

        # Whitespace handling
        flag_option :ignore_cr_at_eol
        flag_option :ignore_space_at_eol
        flag_option %i[ignore_space_change b]
        flag_option %i[ignore_all_space w]
        flag_option :ignore_blank_lines
        value_option %i[ignore_matching_lines I], inline: true, repeatable: true
        flag_option :check
        value_option :ws_error_highlight, inline: true

        # Rename/copy detection
        flag_option :no_renames
        flag_option :rename_empty, negatable: true
        flag_option :full_index
        flag_option :binary
        flag_or_value_option :abbrev, inline: true
        flag_or_value_option %i[break_rewrites B], inline: true
        flag_or_value_option %i[find_renames M], inline: true
        flag_or_value_option %i[find_copies C], inline: true
        flag_option :find_copies_harder
        flag_option %i[irreversible_delete D]

        # Pickaxe / filtering
        value_option :l, inline: true
        value_option :diff_filter, inline: true
        value_option :S, inline: true
        value_option :G, inline: true
        value_option :find_object, inline: true
        flag_option :pickaxe_all
        flag_option :pickaxe_regex
        value_option :O, inline: true
        value_option :skip_to, inline: true
        value_option :rotate_to, inline: true

        # Miscellaneous diff options
        flag_option :R
        flag_or_value_option :relative, inline: true, negatable: true
        flag_option %i[text a]
        value_option :inter_hunk_context, inline: true
        flag_option %i[function_context W]
        flag_option :exit_code
        flag_option :quiet
        flag_option :ext_diff, negatable: true
        flag_option :textconv, negatable: true
        flag_or_value_option :ignore_submodules, inline: true
        value_option :src_prefix, inline: true
        value_option :dst_prefix, inline: true
        flag_option :no_prefix
        flag_option :default_prefix
        value_option :line_prefix, inline: true
        flag_option :ita_invisible_in_index
        value_option :max_depth, inline: true

        # Operands: git diff-index does not accept -- before <tree-ish>.
        # end_of_options is placed between tree_ish and path so that -- is emitted
        # only when path arguments are present, disambiguating paths from revisions.
        operand :tree_ish, required: true
        end_of_options
        operand :path, repeatable: true
      end

      # git diff-index exits 1 when differences are found (e.g. with --exit-code)
      allow_exit_status 0..1

      # @!method call(*, **)
      #
      #   @overload call(tree_ish, **options)
      #     Compare a tree to the index or working tree
      #
      #     @example Compare HEAD to the working tree
      #       # git diff-index HEAD
      #       DiffIndex.new(ctx).call('HEAD')
      #
      #     @example Compare HEAD to the index (staged changes only)
      #       # git diff-index --cached HEAD
      #       DiffIndex.new(ctx).call('HEAD', cached: true)
      #
      #     @param tree_ish [String] the tree object to compare
      #       against (e.g., `'HEAD'`, a commit SHA, or a tag
      #       name)
      #
      #     @param options [Hash] command options
      #
      #     @option options [Boolean] :m (false) treat non-checked-out files as up to date
      #
      #       By default, files recorded in the index but not checked out are reported as
      #       deleted. This flag makes `git diff-index` report all such files as up to date.
      #
      #     @option options [Boolean] :cached (false) compare the tree to the index only (staged
      #       changes), without considering the working tree
      #
      #     @option options [Boolean] :merge_base (false) use the merge base between the tree-ish
      #       and `HEAD` rather than the tree-ish directly
      #
      #       `tree_ish` must be a commit when this option is used.
      #
      #     @option options [Boolean] :patch (false) generate unified diff patch output
      #
      #       Alias: :p, :u
      #
      #     @option options [Boolean] :no_patch (false) suppress all diff output
      #
      #       Alias: :s
      #
      #     @option options [Boolean] :raw (false) generate diff in raw format (default output)
      #
      #     @option options [Boolean] :patch_with_raw (false) synonym for `patch: true, raw: true`
      #
      #     @option options [Integer, String] :unified (nil) number of context lines around diff
      #       hunks (e.g., `3`)
      #
      #       Alias: :U
      #
      #     @option options [String] :output (nil) write diff output to a file instead of stdout
      #
      #     @option options [String] :output_indicator_new (nil) character for new lines in patch output
      #
      #     @option options [String] :output_indicator_old (nil) character for old lines in patch output
      #
      #     @option options [String] :output_indicator_context (nil) character for context lines in patch output
      #
      #     @option options [Boolean] :indent_heuristic (false) shift hunk boundaries for readability
      #       (`--indent-heuristic`)
      #
      #     @option options [Boolean] :no_indent_heuristic (false) do not shift hunk boundaries
      #       for readability (`--no-indent-heuristic`)
      #
      #     @option options [Boolean] :minimal (false) spend extra time to minimize diff size
      #
      #     @option options [Boolean] :patience (false) use patience diff algorithm
      #
      #     @option options [Boolean] :histogram (false) use histogram diff algorithm
      #
      #     @option options [String, Array<String>] :anchored (nil) anchor lines matching the given
      #       text to prevent them from appearing as additions or deletions (repeatable)
      #
      #     @option options [String] :diff_algorithm (nil) diff algorithm to use
      #
      #       Accepted values: `'default'`, `'myers'`, `'minimal'`, `'patience'`, `'histogram'`.
      #
      #     @option options [Boolean, String] :stat (nil) show a diffstat
      #
      #       Pass `true` for the default format, or a string like `'80,40,5'` for custom
      #       `width,name-width,count` limits.
      #
      #     @option options [Integer, String] :stat_width (nil) override diffstat total width
      #
      #     @option options [Integer, String] :stat_name_width (nil) override diffstat filename column width
      #
      #     @option options [Integer, String] :stat_graph_width (nil) override diffstat graph column width
      #
      #     @option options [Integer, String] :stat_count (nil) limit diffstat to this many lines
      #
      #     @option options [Boolean] :compact_summary (false) include creation/deletion mode changes in stat
      #
      #     @option options [Boolean] :numstat (false) show per-file insertion/deletion counts (machine-friendly)
      #
      #     @option options [Boolean] :shortstat (false) show aggregate totals line only
      #
      #     @option options [Boolean, String] :dirstat (nil) show distribution of changes per directory
      #
      #       Pass `true` for the default, or a string like `'lines,cumulative,10'` to pass params.
      #
      #       Alias: :X
      #
      #     @option options [Boolean] :cumulative (false) synonym for `dirstat: 'cumulative'`
      #
      #     @option options [Boolean, String] :dirstat_by_file (nil) synonym for `dirstat: 'files,...'`
      #
      #     @option options [Boolean] :summary (false) show condensed extended header information
      #
      #     @option options [Boolean] :patch_with_stat (false) synonym for `patch: true, stat: true`
      #
      #     @option options [Boolean] :z (false) use NUL as output field terminator instead of newline
      #
      #     @option options [Boolean] :name_only (false) show only changed file names
      #
      #     @option options [Boolean] :name_status (false) show changed file names with status letters
      #
      #     @option options [Boolean, String] :submodule (nil) how to show submodule differences
      #
      #       Pass `true` for the default, or a string like `'log'` or `'diff'` for a format name.
      #
      #     @option options [Boolean, String] :color (false) control diff colorization (`--color`)
      #
      #       Pass `true` for `--color` or a string like `'always'` or `'auto'` for a specific mode.
      #
      #     @option options [Boolean] :no_color (false) suppress colorized output (`--no-color`)
      #
      #     @option options [Boolean, String] :color_moved (false) color moved lines differently (`--color-moved`)
      #
      #       Pass `true` for the default, or a mode string such as `'zebra'` or `'dimmed-zebra'`.
      #
      #     @option options [Boolean] :no_color_moved (false) disable moved-line coloring (`--no-color-moved`)
      #
      #     @option options [String] :color_moved_ws (nil) whitespace handling for moved-line color detection
      #
      #       Comma-separated list of modes, e.g. `'ignore-space-at-eol,ignore-space-change'`.
      #
      #     @option options [Boolean] :no_color_moved_ws (false) synonym for `color_moved_ws: 'no'`
      #
      #     @option options [Boolean, String] :word_diff (nil) show a word-level diff
      #
      #       Pass `true` for the default `plain` mode, or a string like `'color'`, `'porcelain'`,
      #       or `'none'` for a specific mode.
      #
      #     @option options [String] :word_diff_regex (nil) regular expression defining word boundaries for word diff
      #
      #     @option options [Boolean, String] :color_words (nil) equivalent to `word_diff: 'color'`
      #       plus an optional word regex
      #
      #     @option options [Boolean] :ignore_cr_at_eol (false) ignore carriage-return at end of line
      #
      #     @option options [Boolean] :ignore_space_at_eol (false) ignore whitespace changes at end of line
      #
      #     @option options [Boolean] :ignore_space_change (false) ignore changes in amount of whitespace
      #
      #       Alias: :b
      #
      #     @option options [Boolean] :ignore_all_space (false) ignore all whitespace when comparing lines
      #
      #       Alias: :w
      #
      #     @option options [Boolean] :ignore_blank_lines (false) ignore changes whose lines are all blank
      #
      #     @option options [String, Array<String>] :ignore_matching_lines (nil) ignore changes whose lines all match
      #       the given regex (repeatable)
      #
      #       Alias: :I
      #
      #     @option options [Boolean] :check (false) warn if changes introduce whitespace errors or
      #       conflict markers
      #
      #     @option options [String] :ws_error_highlight (nil) highlight whitespace errors in the
      #       given diff line types (e.g. `'new'`, `'old,new'`, `'all'`)
      #
      #     @option options [Boolean] :no_renames (false) disable rename detection
      #
      #     @option options [Boolean] :rename_empty (false) use empty blobs as rename sources (`--rename-empty`)
      #
      #     @option options [Boolean] :no_rename_empty (false) disallow empty blobs as rename
      #       sources (`--no-rename-empty`)
      #
      #     @option options [Boolean] :full_index (false) show full blob SHA in index line
      #
      #     @option options [Boolean] :binary (false) output binary diff suitable for `git apply`
      #
      #     @option options [Boolean, String] :abbrev (nil) abbreviate blob names in raw output
      #
      #       Pass `true` for the default, or an integer string like `'10'` for a specific length.
      #
      #     @option options [Boolean, String] :break_rewrites (nil) break total rewrites into
      #       delete-and-create pairs
      #
      #       Pass `true` for defaults, or a threshold string like `'80%'` or `'50%/70%'` for custom
      #       break and rename thresholds.
      #
      #       Alias: :B
      #
      #     @option options [Boolean, String] :find_renames (nil) detect renames
      #
      #       Pass `true` for the default threshold, or a string like `'90%'` for a custom
      #       similarity threshold.
      #
      #       Alias: :M
      #
      #     @option options [Boolean, String] :find_copies (nil) detect copies as well as renames
      #
      #       Pass `true` for the default threshold, or a string like `'75%'` for a custom
      #       similarity threshold.
      #
      #       Alias: :C
      #
      #     @option options [Boolean] :find_copies_harder (false) inspect all unmodified files as copy
      #       sources (very expensive for large repos)
      #
      #     @option options [Boolean] :irreversible_delete (false) omit preimage for deleted files
      #
      #       Alias: :D
      #
      #     @option options [Integer, String] :l (nil) limit the number of rename/copy candidates
      #       considered during exhaustive detection
      #
      #     @option options [String] :diff_filter (nil) select only certain kinds of changed files
      #
      #       A string of status letters such as `'A'`, `'M'`, `'D'`, `'ACDM'`, or lowercase
      #       forms to exclude (e.g. `'ad'` excludes added and deleted).
      #
      #     @option options [String] :S (nil) find changes that alter the occurrence count of the
      #       given string (pickaxe)
      #
      #     @option options [String] :G (nil) find changes whose patch text contains lines matching
      #       the given regex (pickaxe)
      #
      #     @option options [String] :find_object (nil) find changes involving the given object id
      #
      #     @option options [Boolean] :pickaxe_all (false) show all changes in a changeset when using
      #       `-S` or `-G`
      #
      #     @option options [Boolean] :pickaxe_regex (false) treat the `-S` string as an extended POSIX
      #       regular expression
      #
      #     @option options [String] :O (nil) path to an orderfile controlling output file order
      #
      #     @option options [String] :skip_to (nil) discard files before the named file in the output
      #
      #     @option options [String] :rotate_to (nil) move files before the named file to end of output
      #
      #     @option options [Boolean] :R (false) swap the two diff inputs
      #
      #     @option options [Boolean, String] :relative (false) show paths relative to a directory (`--relative`)
      #
      #       Pass `true` to use the current directory, or a path string to name the directory explicitly.
      #
      #     @option options [Boolean] :no_relative (false) use absolute paths in output (`--no-relative`)
      #
      #     @option options [Boolean] :text (false) treat all files as text
      #
      #       Alias: :a
      #
      #     @option options [Integer, String] :inter_hunk_context (nil) show context between diff hunks
      #       up to this many lines, fusing close hunks
      #
      #     @option options [Boolean] :function_context (false) show whole function as context for each change
      #
      #       Alias: :W
      #
      #     @option options [Boolean] :exit_code (false) exit with status 1 if differences are found,
      #       0 if none
      #
      #     @option options [Boolean] :quiet (false) suppress all output
      #
      #       Implies `--exit-code`.
      #
      #     @option options [Boolean] :ext_diff (false) allow external diff helpers (`--ext-diff`)
      #
      #     @option options [Boolean] :no_ext_diff (false) disallow external diff helpers (`--no-ext-diff`)
      #
      #     @option options [Boolean] :textconv (false) allow external text-conversion filters (`--textconv`)
      #
      #     @option options [Boolean] :no_textconv (false) disallow external text-conversion filters (`--no-textconv`)
      #
      #     @option options [Boolean, String] :ignore_submodules (nil) ignore submodule changes
      #
      #       Pass `true` for `--ignore-submodules` (equivalent to `'all'`), or a string such as
      #       `'untracked'`, `'dirty'`, `'none'`, or `'all'`.
      #
      #     @option options [String] :src_prefix (nil) source prefix for diff headers (e.g. `'a/'`)
      #
      #     @option options [String] :dst_prefix (nil) destination prefix for diff headers (e.g. `'b/'`)
      #
      #     @option options [Boolean] :no_prefix (false) omit source and destination prefixes
      #
      #     @option options [Boolean] :default_prefix (false) use the default `a/` and `b/` prefixes
      #
      #     @option options [String] :line_prefix (nil) prepend this prefix to every output line
      #
      #     @option options [Boolean] :ita_invisible_in_index (false) make `git add -N` entries appear as
      #       new files in `git diff` and non-existent in `git diff --cached`
      #
      #     @option options [Integer, String] :max_depth (nil) maximum directory depth to descend for
      #       each pathspec (tree-to-tree diffs only)
      #
      #     @return [Git::CommandLineResult] the result of calling `git diff-index`
      #
      #     @raise [ArgumentError] if unsupported options are provided
      #
      #     @raise [Git::FailedError] if git exits outside the allowed range (exit code > 1)
      #
      #   @overload call(tree_ish, *paths, **options)
      #     Compare a tree to the index or working tree, limiting output to specific paths
      #
      #     @example Compare HEAD to the index for a single directory
      #       # git diff-index --cached HEAD -- lib/
      #       DiffIndex.new(ctx).call('HEAD', 'lib/', cached: true)
      #
      #     @example Compare HEAD to the working tree for multiple paths
      #       # git diff-index HEAD -- lib/ spec/
      #       DiffIndex.new(ctx).call('HEAD', 'lib/', 'spec/')
      #
      #     @param tree_ish [String] the tree object to compare against
      #
      #     @param paths [Array<String>] pathspecs limiting which files are compared
      #
      #     @param options [Hash] command options (same as the single-argument overload)
      #
      #     @return [Git::CommandLineResult] the result of calling `git diff-index`
      #
      #     @raise [ArgumentError] if unsupported options are provided
      #
      #     @raise [Git::FailedError] if git exits outside the allowed range (exit code > 1)
      #
      #   @api public
    end
  end
end
