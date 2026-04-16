# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    # Implements the `git diff` command
    #
    # Compares commits, the index, and the working tree.
    #
    # @example Typical usage
    #   diff = Git::Commands::Diff.new(execution_context)
    #   diff.call(numstat: true, shortstat: true, src_prefix: 'a/', dst_prefix: 'b/')
    #   diff.call(patch: true, no_index: true, path: ['/path/a', '/path/b'])
    #   diff.call(patch: true, cached: true)
    #   diff.call('abc123', 'def456', raw: true, numstat: true, shortstat: true)
    #
    # @note `arguments` block audited against
    #   https://git-scm.com/docs/git-diff/2.53.0
    #
    # @see https://git-scm.com/docs/git-diff git-diff
    #
    # @see Git::Commands
    #
    # @api private
    #
    class Diff < Git::Commands::Base # rubocop:disable Metrics/ClassLength
      arguments do
        literal 'diff'

        # Output format
        flag_option %i[patch p u]
        flag_option %i[no_patch s]
        value_option %i[unified U], inline: true
        value_option :output, inline: true
        value_option :output_indicator_new, inline: true
        value_option :output_indicator_old, inline: true
        value_option :output_indicator_context, inline: true
        flag_option :raw
        flag_option :patch_with_raw
        flag_option :indent_heuristic, negatable: true
        flag_option :minimal
        flag_option :patience
        flag_option :histogram
        value_option :anchored, inline: true, repeatable: true
        value_option :diff_algorithm, inline: true
        flag_or_value_option :stat, inline: true
        value_option :stat_width, inline: true
        value_option :stat_name_width, inline: true
        value_option :stat_count, inline: true
        value_option :stat_graph_width, inline: true
        flag_option :compact_summary
        flag_option :numstat
        flag_option :shortstat
        flag_or_value_option %i[dirstat X], inline: true
        flag_option :cumulative
        flag_or_value_option :dirstat_by_file, inline: true
        flag_option :summary
        flag_option :patch_with_stat
        flag_option :z
        flag_option :name_only
        flag_option :name_status
        flag_or_value_option :submodule, inline: true

        # Color and word diff
        flag_or_value_option :color, negatable: true, inline: true
        flag_or_value_option :color_moved, negatable: true, inline: true
        flag_or_value_option :color_moved_ws, negatable: true, inline: true
        flag_or_value_option :word_diff, inline: true
        value_option :word_diff_regex, inline: true
        flag_or_value_option :color_words, inline: true

        # Rename and copy detection
        flag_option :no_renames
        flag_option :rename_empty, negatable: true
        flag_option :check
        value_option :ws_error_highlight, inline: true
        flag_option :full_index
        flag_option :binary
        flag_or_value_option :abbrev, inline: true
        flag_or_value_option %i[break_rewrites B], inline: true
        flag_or_value_option %i[find_renames M], inline: true
        flag_or_value_option %i[find_copies C], inline: true
        flag_option :find_copies_harder
        flag_option %i[irreversible_delete D]
        value_option :l, inline: true
        value_option :diff_filter, inline: true

        # Content search (pickaxe)
        value_option :S, inline: true
        value_option :G, inline: true
        value_option :find_object, inline: true
        flag_option :pickaxe_all
        flag_option :pickaxe_regex

        # Output ordering
        value_option :O, inline: true
        value_option :skip_to, inline: true
        value_option :rotate_to, inline: true
        flag_option :R

        # Path scope and comparison
        flag_or_value_option :relative, negatable: true, inline: true
        flag_option %i[text a]

        # Whitespace handling
        flag_option :ignore_cr_at_eol
        flag_option :ignore_space_at_eol
        flag_option %i[ignore_space_change b]
        flag_option %i[ignore_all_space w]
        flag_option :ignore_blank_lines
        value_option %i[ignore_matching_lines I], inline: true, repeatable: true
        value_option :inter_hunk_context, inline: true
        flag_option %i[function_context W]

        # Behavior control
        flag_option :exit_code
        flag_option :quiet
        flag_option :ext_diff, negatable: true
        flag_option :textconv, negatable: true
        flag_or_value_option :ignore_submodules, inline: true

        # Prefix and path display
        value_option :src_prefix, inline: true
        value_option :dst_prefix, inline: true
        flag_option :no_prefix
        flag_option :default_prefix
        value_option :line_prefix, inline: true
        flag_option :ita_invisible_in_index
        flag_option :ita_visible_in_index
        value_option :max_depth, inline: true

        # Combined diff format
        flag_option :c
        flag_option :cc
        flag_option :combined_all_paths

        # git diff-specific modes
        flag_option %i[cached staged]
        flag_option :merge_base
        flag_option :no_index

        # Merge conflict stage selection
        flag_option %i[base 1]
        flag_option %i[ours 2]
        flag_option %i[theirs 3]
        flag_option :'0'

        operand :commit, repeatable: true
        end_of_options
        value_option :path, as_operand: true, repeatable: true
      end

      # git diff exit codes: 0 = no diff, 1 = diff found, 2+ = error
      allow_exit_status 0..1

      # @!method call(*, **)
      #
      #   @overload call(**options)
      #
      #     Compare the index to the working tree
      #
      #     @example
      #       Diff.new(ctx).call(numstat: true, src_prefix: 'a/', dst_prefix: 'b/')
      #
      #     @param options [Hash] command options
      #
      #     @return [Git::CommandLineResult] the result of calling `git diff`
      #
      #     @raise [ArgumentError] if unsupported options are provided
      #
      #     @raise [Git::FailedError] if git exits outside the allowed range
      #       (exit code > 1)
      #
      #     @api public
      #
      #   @overload call(no_index: true, path:, **options)
      #
      #     Compare two paths on the filesystem (outside git)
      #
      #     Always use the `path:` keyword for the two filesystem paths so
      #     that paths beginning with `-` are safely separated by `--` and
      #     cannot be mistaken for flags by git.
      #
      #     @example
      #       Diff.new(ctx).call(patch: true, no_index: true, path: ['/a', '/b'])
      #
      #     @param path [Array<String>] two filesystem paths to compare
      #       (passed after `--`)
      #
      #     @param options [Hash] command options
      #
      #     @return [Git::CommandLineResult] the result of calling `git diff`
      #
      #     @raise [ArgumentError] if unsupported options are provided
      #
      #     @raise [Git::FailedError] if git exits outside the allowed range
      #       (exit code > 1)
      #
      #     @api public
      #
      #   @overload call(commit = nil, cached:, **options)
      #
      #     Compare the index to HEAD or the named commit
      #
      #     @example
      #       Diff.new(ctx).call(patch: true, cached: true)
      #       Diff.new(ctx).call('HEAD~3', patch: true, cached: true)
      #
      #     @param commit [String, nil] commit to compare the index against
      #       (defaults to HEAD)
      #
      #     @param options [Hash] command options
      #
      #     @return [Git::CommandLineResult] the result of calling `git diff`
      #
      #     @raise [ArgumentError] if unsupported options are provided
      #
      #     @raise [Git::FailedError] if git exits outside the allowed range
      #       (exit code > 1)
      #
      #     @api public
      #
      #   @overload call(commit, **options)
      #
      #     Compare the working tree to the named commit
      #
      #     @example
      #       Diff.new(ctx).call('HEAD~3', numstat: true, shortstat: true)
      #
      #     @param commit [String] commit reference to compare the working
      #       tree against
      #
      #     @param options [Hash] command options
      #
      #     @return [Git::CommandLineResult] the result of calling `git diff`
      #
      #     @raise [ArgumentError] if unsupported options are provided
      #
      #     @raise [Git::FailedError] if git exits outside the allowed range
      #       (exit code > 1)
      #
      #     @api public
      #
      #   @overload call(commit, *commits, **options)
      #
      #     Compare two or more commits or show a combined diff
      #
      #     @example Compare two commits
      #       Diff.new(ctx).call('abc123', 'def456', raw: true, numstat: true)
      #
      #     @example Combined diff of a merge commit
      #       Diff.new(ctx).call('main', 'feature-a', 'feature-b',
      #         merge_base: true)
      #
      #     @param commit [String] first commit reference
      #
      #     @param commits [Array<String>] additional commit references
      #
      #     @param options [Hash] command options
      #
      #     @option options [Boolean] :patch (false) generate patch output
      #
      #       Alias: :p, :u
      #
      #     @option options [Boolean] :no_patch (false) suppress all diff
      #       output
      #
      #       Alias: :s
      #
      #     @option options [Integer, String] :unified (nil) generate diffs
      #       with this many lines of context
      #
      #       Alias: :U
      #
      #     @option options [String] :output (nil) write output to a file
      #       instead of stdout
      #
      #     @option options [String] :output_indicator_new (nil) character
      #       to indicate new lines in the patch
      #
      #     @option options [String] :output_indicator_old (nil) character
      #       to indicate old lines in the patch
      #
      #     @option options [String] :output_indicator_context (nil)
      #       character to indicate context lines in the patch
      #
      #     @option options [Boolean] :raw (false) generate the diff in raw
      #       format
      #
      #     @option options [Boolean] :patch_with_raw (false) synonym for
      #       `--patch --raw`
      #
      #     @option options [Boolean] :indent_heuristic (nil) enable or
      #       disable the indent heuristic for patch readability
      #
      #       Pass `true` for `--indent-heuristic`, `false` for
      #       `--no-indent-heuristic`.
      #
      #     @option options [Boolean] :minimal (false) spend extra time to
      #       produce the smallest possible diff
      #
      #     @option options [Boolean] :patience (false) use the patience
      #       diff algorithm
      #
      #     @option options [Boolean] :histogram (false) use the histogram
      #       diff algorithm
      #
      #     @option options [String, Array<String>] :anchored (nil)
      #       generate a diff using the anchored diff algorithm
      #
      #       Pass an array for multiple anchored texts. Maps to
      #       `--anchored=<text>`.
      #
      #     @option options [String] :diff_algorithm (nil) choose a diff
      #       algorithm (`patience`, `minimal`, `histogram`, or `myers`)
      #
      #     @option options [Boolean, String] :stat (nil) generate a
      #       diffstat
      #
      #       Pass `true` for `--stat`; pass a string like
      #       `'100,40,10'` for `--stat=100,40,10`.
      #
      #     @option options [Integer, String] :stat_width (nil) limit the
      #       width of `--stat` output
      #
      #     @option options [Integer, String] :stat_name_width (nil) limit
      #       the filename width of `--stat` output
      #
      #     @option options [Integer, String] :stat_count (nil) limit the
      #       number of lines in `--stat` output
      #
      #     @option options [Integer, String] :stat_graph_width (nil) limit
      #       the graph width of `--stat` output
      #
      #     @option options [Boolean] :compact_summary (false) output a
      #       condensed summary of extended header information
      #
      #     @option options [Boolean] :numstat (false) show per-file
      #       insertion/deletion counts in decimal notation
      #
      #     @option options [Boolean] :shortstat (false) output only the
      #       aggregate totals line from `--stat`
      #
      #     @option options [Boolean, String] :dirstat (nil) output the
      #       distribution of relative amount of changes per sub-directory
      #
      #       Pass `true` for `--dirstat`; pass a string like
      #       `'lines,cumulative'` for `--dirstat=lines,cumulative`.
      #
      #       Alias: :X
      #
      #     @option options [Boolean] :cumulative (false) synonym for
      #       `--dirstat=cumulative`
      #
      #     @option options [Boolean, String] :dirstat_by_file (nil)
      #       synonym for `--dirstat=files,...`
      #
      #     @option options [Boolean] :summary (false) output a condensed
      #       summary of extended header information
      #
      #     @option options [Boolean] :patch_with_stat (false) synonym for
      #       `--patch --stat`
      #
      #     @option options [Boolean] :z (false) use NUL as output field
      #       terminators
      #
      #     @option options [Boolean] :name_only (false) show only the name
      #       of each changed file
      #
      #     @option options [Boolean] :name_status (false) show only the
      #       name and status of each changed file
      #
      #     @option options [Boolean, String] :submodule (nil) specify how
      #       differences in submodules are shown
      #
      #       Pass `true` for `--submodule`; pass a string like `'log'`
      #       or `'diff'` for `--submodule=<format>`.
      #
      #     @option options [Boolean, String] :color (nil) show colored
      #       diff
      #
      #       Pass `true` for `--color`, `false` for `--no-color`, or a
      #       string like `'always'` for `--color=always`.
      #
      #     @option options [Boolean, String] :color_moved (nil) color
      #       moved lines differently
      #
      #       Pass `true` for `--color-moved`, `false` for
      #       `--no-color-moved`, or a string like `'zebra'` for
      #       `--color-moved=zebra`.
      #
      #     @option options [Boolean, String] :color_moved_ws (nil)
      #       configure how whitespace is handled for move detection
      #
      #       Pass `false` for `--no-color-moved-ws`, or a string like
      #       `'ignore-all-space'` for `--color-moved-ws=ignore-all-space`.
      #
      #     @option options [Boolean, String] :word_diff (nil) show a
      #       word diff
      #
      #       Pass `true` for `--word-diff`; pass a string like `'color'`
      #       for `--word-diff=color`.
      #
      #     @option options [String] :word_diff_regex (nil) use this regex
      #       to decide what a word is
      #
      #     @option options [Boolean, String] :color_words (nil) equivalent
      #       to `--word-diff=color` plus optional regex
      #
      #     @option options [Boolean] :no_renames (false) turn off rename
      #       detection
      #
      #     @option options [Boolean] :rename_empty (nil) whether to use
      #       empty blobs as rename source
      #
      #       Pass `true` for `--rename-empty`, `false` for
      #       `--no-rename-empty`.
      #
      #     @option options [Boolean] :check (false) warn if changes
      #       introduce conflict markers or whitespace errors
      #
      #     @option options [String] :ws_error_highlight (nil) highlight
      #       whitespace errors in `context`, `old`, or `new` lines
      #
      #     @option options [Boolean] :full_index (false) show full
      #       pre- and post-image blob object names
      #
      #     @option options [Boolean] :binary (false) output a binary diff
      #       that can be applied with `git apply`
      #
      #     @option options [Boolean, String] :abbrev (nil) show only a
      #       partial prefix of object names
      #
      #       Pass `true` for `--abbrev`; pass a string for
      #       `--abbrev=<n>`.
      #
      #     @option options [Boolean, String] :break_rewrites (nil) break
      #       complete rewrite changes into delete/create pairs
      #
      #       Alias: :B
      #
      #     @option options [Boolean, String] :find_renames (nil) detect
      #       renames, optionally specifying a similarity threshold
      #
      #       Alias: :M
      #
      #     @option options [Boolean, String] :find_copies (nil) detect
      #       copies as well as renames
      #
      #       Alias: :C
      #
      #     @option options [Boolean] :find_copies_harder (false) inspect
      #       all files as candidates for the source of copy
      #
      #     @option options [Boolean] :irreversible_delete (false) omit
      #       the preimage for deletes
      #
      #       Alias: :D
      #
      #     @option options [Integer, String] :l (nil) prevent rename/copy
      #       detection from running if the number of targets exceeds this
      #
      #     @option options [String] :diff_filter (nil) select only files
      #       matching the specified status letters
      #
      #     @option options [String] :S (nil) look for differences that
      #       change the number of occurrences of a string
      #
      #     @option options [String] :G (nil) look for differences whose
      #       patch text contains added/removed lines matching a regex
      #
      #     @option options [String] :find_object (nil) look for
      #       differences that change the number of occurrences of an
      #       object
      #
      #     @option options [Boolean] :pickaxe_all (false) when `-S` or
      #       `-G` finds a change, show all changes in that changeset
      #
      #     @option options [Boolean] :pickaxe_regex (false) treat the
      #       `-S` string as an extended POSIX regular expression
      #
      #     @option options [String] :O (nil) control the order in which
      #       files appear in the output
      #
      #     @option options [String] :skip_to (nil) discard files before
      #       the named file from the output
      #
      #     @option options [String] :rotate_to (nil) move files before
      #       the named file to the end of the output
      #
      #     @option options [Boolean] :R (false) swap two inputs (reverse
      #       diff)
      #
      #     @option options [Boolean, String] :relative (nil) show
      #       pathnames relative to a subdirectory
      #
      #       Pass `true` for `--relative`, `false` for `--no-relative`,
      #       or a string for `--relative=<path>`.
      #
      #     @option options [Boolean] :text (false) treat all files as
      #       text
      #
      #       Alias: :a
      #
      #     @option options [Boolean] :ignore_cr_at_eol (false) ignore
      #       carriage-return at end of line
      #
      #     @option options [Boolean] :ignore_space_at_eol (false) ignore
      #       changes in whitespace at end of line
      #
      #     @option options [Boolean] :ignore_space_change (false) ignore
      #       changes in amount of whitespace
      #
      #       Alias: :b
      #
      #     @option options [Boolean] :ignore_all_space (false) ignore
      #       whitespace when comparing lines
      #
      #       Alias: :w
      #
      #     @option options [Boolean] :ignore_blank_lines (false) ignore
      #       changes whose lines are all blank
      #
      #     @option options [String, Array<String>] :ignore_matching_lines
      #       (nil) ignore changes whose all lines match the given regex
      #
      #       Pass an array for multiple patterns. Maps to
      #       `--ignore-matching-lines=<regex>`.
      #
      #       Alias: :I
      #
      #     @option options [Integer, String] :inter_hunk_context (nil)
      #       show the context between diff hunks, fusing nearby hunks
      #
      #     @option options [Boolean] :function_context (false) show whole
      #       function as context lines for each change
      #
      #       Alias: :W
      #
      #     @option options [Boolean] :exit_code (false) make the program
      #       exit with codes similar to `diff(1)`
      #
      #     @option options [Boolean] :quiet (false) disable all output of
      #       the program
      #
      #     @option options [Boolean] :ext_diff (nil) allow or disallow an
      #       external diff helper
      #
      #       Pass `true` for `--ext-diff`, `false` for `--no-ext-diff`.
      #
      #     @option options [Boolean] :textconv (nil) allow or disallow
      #       external text conversion filters for binary files
      #
      #       Pass `true` for `--textconv`, `false` for `--no-textconv`.
      #
      #     @option options [Boolean, String] :ignore_submodules (nil)
      #       ignore changes to submodules in the diff
      #
      #       Pass `true` for `--ignore-submodules`; pass a string like
      #       `'all'` for `--ignore-submodules=all`.
      #
      #     @option options [String] :src_prefix (nil) source prefix for
      #       diff headers (e.g. `'a/'`)
      #
      #     @option options [String] :dst_prefix (nil) destination prefix
      #       for diff headers (e.g. `'b/'`)
      #
      #     @option options [Boolean] :no_prefix (false) do not show any
      #       source or destination prefix
      #
      #     @option options [Boolean] :default_prefix (false) use the
      #       default source and destination prefixes
      #
      #     @option options [String] :line_prefix (nil) prepend an
      #       additional prefix to every line of output
      #
      #     @option options [Boolean] :ita_invisible_in_index (false) make
      #       intent-to-add entries appear as new files in `git diff`
      #
      #     @option options [Boolean] :ita_visible_in_index (false) revert
      #       `--ita-invisible-in-index`
      #
      #     @option options [Integer, String] :max_depth (nil) descend at
      #       most this many levels of directories per pathspec
      #
      #     @option options [Boolean] :cached (false) compare the index to
      #       HEAD or a named commit
      #
      #       Alias: :staged
      #
      #     @option options [Boolean] :merge_base (false) use merge base
      #       of commits
      #
      #     @option options [Boolean] :no_index (false) compare two
      #       filesystem paths outside a repo
      #
      #     @option options [Boolean] :base (false) compare working tree
      #       with the base version (stage #1)
      #
      #       Alias: :"1"
      #
      #     @option options [Boolean] :ours (false) compare working tree
      #       with our branch (stage #2)
      #
      #       Alias: :"2"
      #
      #     @option options [Boolean] :theirs (false) compare working tree
      #       with their branch (stage #3)
      #
      #       Alias: :"3"
      #
      #     @option options [Boolean] :"0" (false) omit diff output for
      #       unmerged entries
      #
      #     @option options [Boolean] :c (false) produce a combined diff
      #       (useful when showing a merge)
      #
      #     @option options [Boolean] :cc (false) produce a dense combined
      #       diff (useful when showing a merge)
      #
      #     @option options [Boolean] :combined_all_paths (false) show
      #       paths from all parents of a combined diff
      #
      #     @option options [Array<String>] :path (nil) zero or more paths
      #       to limit diff to
      #
      #     @return [Git::CommandLineResult] the result of calling
      #       `git diff`
      #
      #     @raise [ArgumentError] if unsupported options are provided
      #
      #     @raise [Git::FailedError] if git exits outside the allowed
      #       range (exit code > 1)
      #
      #     @api public
    end
  end
end
