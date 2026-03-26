# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    # Implements the `git diff-files` command
    #
    # Compares the index (staging area) to the working tree, showing files that
    # have been modified but not yet staged. This is the plumbing equivalent of
    # checking for unstaged changes.
    #
    # @see https://git-scm.com/docs/git-diff-files git-diff-files documentation
    #
    # @see Git::Commands
    #
    # @api private
    #
    # @example Show all unstaged changes (raw output)
    #   # git diff-files
    #   Git::Commands::DiffFiles.new(ctx).call
    #
    # @example Show unstaged changes as a patch
    #   # git diff-files --patch
    #   Git::Commands::DiffFiles.new(ctx).call(patch: true)
    #
    # @example Limit comparison to specific paths
    #   # git diff-files -- lib/ spec/
    #   Git::Commands::DiffFiles.new(ctx).call('lib/', 'spec/')
    #
    # @example Check quietly — only exit status (0 = clean, 1 = changes)
    #   # git diff-files -q
    #   Git::Commands::DiffFiles.new(ctx).call(q: true)
    #
    class DiffFiles < Git::Commands::Base
      arguments do
        literal 'diff-files'

        # diff-files-specific options
        flag_option :q                                   # -q (do not complain about nonexistent files)
        flag_option :unmerged, as: '-0'                  # -0 (unmerged: suppress diff output)
        flag_option :base                                # --base (-1: unmerged, diff against stage 1)
        flag_option :ours                                # --ours (-2: unmerged, diff against stage 2)
        flag_option :theirs                              # --theirs (-3: unmerged, diff against stage 3)
        flag_option :c                                   # -c (combined diff: stage 2, stage 3, working tree)
        flag_option :cc                                  # --cc (synonym for -c)

        # Output format selection
        flag_option %i[patch p u]                        # --patch / -p / -u
        flag_option %i[no_patch s]                       # --no-patch / -s
        flag_option :raw                                 # --raw
        flag_option :patch_with_raw                      # --patch-with-raw
        value_option %i[unified U], inline: true         # --unified=<n> / -U<n>
        value_option :output, inline: true               # --output=<file>
        value_option :output_indicator_new, inline: true    # --output-indicator-new=<char>
        value_option :output_indicator_old, inline: true    # --output-indicator-old=<char>
        value_option :output_indicator_context, inline: true # --output-indicator-context=<char>

        # Diff algorithm
        flag_option :indent_heuristic, negatable: true   # --[no-]indent-heuristic
        flag_option :minimal                             # --minimal
        flag_option :patience                            # --patience
        flag_option :histogram                           # --histogram
        value_option :anchored, inline: true, repeatable: true # --anchored=<text> (repeatable)
        value_option :diff_algorithm, inline: true # --diff-algorithm=<algo>

        # Statistics output formats
        flag_or_value_option :stat, inline: true         # --stat[=<width>[,<name-width>[,<count>]]]
        value_option :stat_width, inline: true           # --stat-width=<width>
        value_option :stat_name_width, inline: true      # --stat-name-width=<name-width>
        value_option :stat_graph_width, inline: true     # --stat-graph-width=<graph-width>
        value_option :stat_count, inline: true           # --stat-count=<count>
        flag_option :compact_summary                     # --compact-summary
        flag_option :numstat                             # --numstat
        flag_option :shortstat                           # --shortstat
        flag_or_value_option %i[dirstat X], inline: true # --dirstat[=<param>...] / -X[<param>...]
        flag_option :cumulative                          # --cumulative
        flag_or_value_option :dirstat_by_file, inline: true # --dirstat-by-file[=<param>...]
        flag_option :summary                             # --summary
        flag_option :patch_with_stat                     # --patch-with-stat

        # Name and path display
        flag_option :z                                   # -z
        flag_option :name_only                           # --name-only
        flag_option :name_status                         # --name-status
        flag_or_value_option :submodule, inline: true    # --submodule[=<format>]

        # Color output
        flag_or_value_option :color, inline: true, negatable: true # --color[=<when>] / --no-color
        flag_or_value_option :color_moved, inline: true, negatable: true # --color-moved[=<mode>] / --no-color-moved
        value_option :color_moved_ws, inline: true       # --color-moved-ws=<mode>,...
        flag_option :no_color_moved_ws                   # --no-color-moved-ws

        # Word diff
        flag_or_value_option :word_diff, inline: true    # --word-diff[=<mode>]
        value_option :word_diff_regex, inline: true      # --word-diff-regex=<regex>
        flag_or_value_option :color_words, inline: true  # --color-words[=<regex>]

        # Whitespace handling
        flag_option :ignore_cr_at_eol                    # --ignore-cr-at-eol
        flag_option :ignore_space_at_eol                 # --ignore-space-at-eol
        flag_option %i[ignore_space_change b]            # --ignore-space-change / -b
        flag_option %i[ignore_all_space w]               # --ignore-all-space / -w
        flag_option :ignore_blank_lines                  # --ignore-blank-lines
        value_option %i[ignore_matching_lines I], inline: true, repeatable: true # --ignore-matching-lines / -I
        flag_option :check                               # --check
        value_option :ws_error_highlight, inline: true   # --ws-error-highlight=<kind>

        # Rename/copy detection
        flag_option :no_renames                          # --no-renames
        flag_option :rename_empty, negatable: true       # --[no-]rename-empty
        flag_option :full_index                          # --full-index
        flag_option :binary                              # --binary
        flag_or_value_option :abbrev, inline: true       # --abbrev[=<n>]
        flag_or_value_option %i[break_rewrites B], inline: true  # --break-rewrites[=[<n>][/<m>]] / -B[<n>][/<m>]
        flag_or_value_option %i[find_renames M], inline: true    # --find-renames[=<n>] / -M[<n>]
        flag_or_value_option %i[find_copies C], inline: true     # --find-copies[=<n>] / -C[<n>]
        flag_option :find_copies_harder                  # --find-copies-harder
        flag_option %i[irreversible_delete D]            # --irreversible-delete / -D

        # Pickaxe / filtering
        value_option :l, inline: true                    # -l<num>
        value_option :diff_filter, inline: true          # --diff-filter=[ACDMRTUXB*...]
        value_option :S, inline: true                    # -S<string>
        value_option :G, inline: true                    # -G<regex>
        value_option :find_object, inline: true          # --find-object=<object-id>
        flag_option :pickaxe_all                         # --pickaxe-all
        flag_option :pickaxe_regex                       # --pickaxe-regex
        value_option :O, inline: true                    # -O<orderfile>
        value_option :skip_to, inline: true              # --skip-to=<file>
        value_option :rotate_to, inline: true            # --rotate-to=<file>

        # Miscellaneous diff options
        flag_option :R # -R (swap inputs)
        flag_or_value_option :relative, inline: true, negatable: true # --relative[=<path>] / --no-relative
        flag_option %i[text a]                           # --text / -a
        value_option :inter_hunk_context, inline: true   # --inter-hunk-context=<number>
        flag_option %i[function_context W]               # --function-context / -W
        flag_option :exit_code                           # --exit-code
        flag_option :quiet                               # --quiet
        flag_option :ext_diff, negatable: true           # --[no-]ext-diff
        flag_option :textconv, negatable: true           # --[no-]textconv
        flag_or_value_option :ignore_submodules, inline: true # --ignore-submodules[=<when>]
        value_option :src_prefix, inline: true           # --src-prefix=<prefix>
        value_option :dst_prefix, inline: true           # --dst-prefix=<prefix>
        flag_option :no_prefix                           # --no-prefix
        flag_option :default_prefix                      # --default-prefix
        value_option :line_prefix, inline: true          # --line-prefix=<prefix>
        flag_option :ita_invisible_in_index              # --ita-invisible-in-index
        value_option :max_depth, inline: true            # --max-depth=<depth>

        # Operands: git diff-files has no required <tree-ish>; options precede end_of_options.
        # end_of_options emits -- only when path arguments are present, protecting paths
        # that start with '-' from being misinterpreted as flags.
        end_of_options                      # -- emitted only when paths follow
        operand :path, repeatable: true     # [<path>...] (optional)
      end

      # git diff-files exits 1 when differences are found (not an error)
      allow_exit_status 0..1

      # @!method call(*, **)
      #
      #   @api public
      #
      #   @overload call(**options)
      #     Compare the index to the working tree with no path restriction
      #
      #     @example Show all unstaged changes in raw format
      #       # git diff-files
      #       DiffFiles.new(ctx).call
      #
      #     @example Show unstaged changes as a unified diff patch
      #       # git diff-files --patch
      #       DiffFiles.new(ctx).call(patch: true)
      #
      #     @param options [Hash] command options
      #
      #     @option options [Boolean] :q (nil) Do not complain about nonexistent files; only
      #       report exit status
      #
      #     @option options [Boolean] :unmerged (nil) For unmerged entries, suppress diff output
      #       and show only "Unmerged"
      #
      #     @option options [Boolean] :base (nil) For unmerged entries, diff against stage 1
      #       (common ancestor)
      #
      #       Short form: `-1`
      #
      #     @option options [Boolean] :ours (nil) For unmerged entries, diff against stage 2
      #       (our changes)
      #
      #       Short form: `-2`
      #
      #     @option options [Boolean] :theirs (nil) For unmerged entries, diff against stage 3
      #       (their changes)
      #
      #       Short form: `-3`
      #
      #     @option options [Boolean] :c (nil) For unmerged entries, show a combined diff of
      #       stage 2, stage 3, and the working tree
      #
      #     @option options [Boolean] :cc (nil) Synonym for `c: true`
      #
      #     @option options [Boolean] :patch (nil) Generate unified diff patch output
      #
      #       Alias: :p, :u
      #
      #     @option options [Boolean] :no_patch (nil) Suppress all diff output
      #
      #       Alias: :s
      #
      #     @option options [Boolean] :raw (nil) Generate diff in raw format (default output)
      #
      #     @option options [Boolean] :patch_with_raw (nil) Synonym for `patch: true, raw: true`
      #
      #     @option options [Integer, String] :unified (nil) Number of context lines around diff
      #       hunks
      #
      #       Alias: :U
      #
      #     @option options [String] :output (nil) Write diff output to a file instead of stdout
      #
      #     @option options [String] :output_indicator_new (nil) Character for new lines in patch output
      #
      #     @option options [String] :output_indicator_old (nil) Character for old lines in patch output
      #
      #     @option options [String] :output_indicator_context (nil) Character for context lines in patch output
      #
      #     @option options [Boolean] :indent_heuristic (nil) Shift hunk boundaries for readability
      #
      #       Pass `false` to emit `--no-indent-heuristic`.
      #
      #     @option options [Boolean] :minimal (nil) Spend extra time to minimize diff size
      #
      #     @option options [Boolean] :patience (nil) Use patience diff algorithm
      #
      #     @option options [Boolean] :histogram (nil) Use histogram diff algorithm
      #
      #     @option options [String, Array<String>] :anchored (nil) Anchor lines matching the
      #       given text (repeatable)
      #
      #     @option options [String] :diff_algorithm (nil) Diff algorithm to use
      #
      #       Accepted values: `'default'`, `'myers'`, `'minimal'`, `'patience'`, `'histogram'`.
      #
      #     @option options [Boolean, String] :stat (nil) Show a diffstat
      #
      #       Pass `true` for the default format, or a string like `'80,40,5'` for custom limits.
      #
      #     @option options [Integer, String] :stat_width (nil) Override diffstat total width
      #
      #     @option options [Integer, String] :stat_name_width (nil) Override diffstat filename column width
      #
      #     @option options [Integer, String] :stat_graph_width (nil) Override diffstat graph column width
      #
      #     @option options [Integer, String] :stat_count (nil) Limit diffstat to this many lines
      #
      #     @option options [Boolean] :compact_summary (nil) Include creation/deletion mode changes in stat
      #
      #     @option options [Boolean] :numstat (nil) Show per-file insertion/deletion counts (machine-friendly)
      #
      #     @option options [Boolean] :shortstat (nil) Show aggregate totals line only
      #
      #     @option options [Boolean, String] :dirstat (nil) Show distribution of changes per directory
      #
      #       Pass `true` for the default, or a string like `'lines,cumulative,10'` for params.
      #
      #       Alias: :X
      #
      #     @option options [Boolean] :cumulative (nil) Synonym for `dirstat: 'cumulative'`
      #
      #     @option options [Boolean, String] :dirstat_by_file (nil) Synonym for `dirstat: 'files,...'`
      #
      #     @option options [Boolean] :summary (nil) Show condensed extended header information
      #
      #     @option options [Boolean] :patch_with_stat (nil) Synonym for `patch: true, stat: true`
      #
      #     @option options [Boolean] :z (nil) Use NUL as output field terminator instead of newline
      #
      #     @option options [Boolean] :name_only (nil) Show only changed file names
      #
      #     @option options [Boolean] :name_status (nil) Show changed file names with status letters
      #
      #     @option options [Boolean, String] :submodule (nil) How to show submodule differences
      #
      #       Pass `true` for the default, or a string like `'log'` or `'diff'` for a format name.
      #
      #     @option options [Boolean, String] :color (nil) Control diff colorization
      #
      #       Pass `true` for `--color`, `false` for `--no-color`, or a string like `'always'` or
      #       `'auto'` for a specific mode.
      #
      #     @option options [Boolean, String] :color_moved (nil) Color moved lines differently
      #
      #       Pass `true` for default, `false` for `--no-color-moved`, or a mode string such as
      #       `'zebra'` or `'dimmed-zebra'`.
      #
      #     @option options [String] :color_moved_ws (nil) Whitespace handling for moved-line color detection
      #
      #       Comma-separated list of modes, e.g. `'ignore-space-at-eol,ignore-space-change'`.
      #
      #     @option options [Boolean] :no_color_moved_ws (nil) Synonym for `color_moved_ws: 'no'`
      #
      #     @option options [Boolean, String] :word_diff (nil) Show a word-level diff
      #
      #       Pass `true` for the default `plain` mode, or a string like `'color'`, `'porcelain'`,
      #       or `'none'` for a specific mode.
      #
      #     @option options [String] :word_diff_regex (nil) Regular expression defining word boundaries
      #       for word diff
      #
      #     @option options [Boolean, String] :color_words (nil) Equivalent to `word_diff: 'color'`
      #       plus an optional word regex
      #
      #     @option options [Boolean] :ignore_cr_at_eol (nil) Ignore carriage-return at end of line
      #
      #     @option options [Boolean] :ignore_space_at_eol (nil) Ignore whitespace changes at end of line
      #
      #     @option options [Boolean] :ignore_space_change (nil) Ignore changes in amount of whitespace
      #
      #       Alias: :b
      #
      #     @option options [Boolean] :ignore_all_space (nil) Ignore all whitespace when comparing lines
      #
      #       Alias: :w
      #
      #     @option options [Boolean] :ignore_blank_lines (nil) Ignore changes whose lines are all blank
      #
      #     @option options [String, Array<String>] :ignore_matching_lines (nil) Ignore changes whose
      #       lines all match the given regex (repeatable)
      #
      #       Alias: :I
      #
      #     @option options [Boolean] :check (nil) Warn if changes introduce whitespace errors or
      #       conflict markers
      #
      #     @option options [String] :ws_error_highlight (nil) Highlight whitespace errors in the
      #       given diff line types (e.g. `'new'`, `'old,new'`, `'all'`)
      #
      #     @option options [Boolean] :no_renames (nil) Disable rename detection
      #
      #     @option options [Boolean] :rename_empty (nil) Use empty blobs as rename sources
      #
      #       Pass `false` to emit `--no-rename-empty`.
      #
      #     @option options [Boolean] :full_index (nil) Show full blob SHA in index line
      #
      #     @option options [Boolean] :binary (nil) Output binary diff suitable for `git apply`
      #
      #     @option options [Boolean, String] :abbrev (nil) Abbreviate blob names in raw output
      #
      #       Pass `true` for the default, or an integer string like `'10'` for a specific length.
      #
      #     @option options [Boolean, String] :break_rewrites (nil) Break total rewrites into
      #       delete-and-create pairs
      #
      #       Alias: :B
      #
      #     @option options [Boolean, String] :find_renames (nil) Detect renames
      #
      #       Pass `true` for the default threshold, or a string like `'90%'` for a custom
      #       similarity threshold.
      #
      #       Alias: :M
      #
      #     @option options [Boolean, String] :find_copies (nil) Detect copies as well as renames
      #
      #       Pass `true` for the default threshold, or a string like `'75%'` for a custom
      #       similarity threshold.
      #
      #       Alias: :C
      #
      #     @option options [Boolean] :find_copies_harder (nil) Inspect all unmodified files as
      #       copy sources (very expensive for large repos)
      #
      #     @option options [Boolean] :irreversible_delete (nil) Omit preimage for deleted files
      #
      #       Alias: :D
      #
      #     @option options [Integer, String] :l (nil) Limit the number of rename/copy candidates
      #       considered during exhaustive detection
      #
      #     @option options [String] :diff_filter (nil) Select only certain kinds of changed files
      #
      #       A string of status letters such as `'A'`, `'M'`, `'D'`, `'ACDM'`, or lowercase
      #       to exclude.
      #
      #     @option options [String] :S (nil) Find changes that alter the occurrence count of the
      #       given string (pickaxe)
      #
      #     @option options [String] :G (nil) Find changes whose patch text contains lines matching
      #       the given regex (pickaxe)
      #
      #     @option options [String] :find_object (nil) Find changes involving the given object id
      #
      #     @option options [Boolean] :pickaxe_all (nil) Show all changes in a changeset when using
      #       `-S` or `-G`
      #
      #     @option options [Boolean] :pickaxe_regex (nil) Treat the `-S` string as an extended POSIX
      #       regular expression
      #
      #     @option options [String] :O (nil) Path to an orderfile controlling output file order
      #
      #     @option options [String] :skip_to (nil) Discard files before the named file in the output
      #
      #     @option options [String] :rotate_to (nil) Move files before the named file to end of output
      #
      #     @option options [Boolean] :R (nil) Swap the two diff inputs
      #
      #     @option options [Boolean, String] :relative (nil) Show paths relative to a directory
      #
      #       Pass `true` to use the current directory, `false` for `--no-relative`, or a path
      #       string to name the directory explicitly.
      #
      #     @option options [Boolean] :text (nil) Treat all files as text
      #
      #       Alias: :a
      #
      #     @option options [Integer, String] :inter_hunk_context (nil) Show context between diff hunks
      #       up to this many lines, fusing close hunks
      #
      #     @option options [Boolean] :function_context (nil) Show whole function as context for each change
      #
      #       Alias: :W
      #
      #     @option options [Boolean] :exit_code (nil) Exit with status 1 if differences are found,
      #       0 if none
      #
      #     @option options [Boolean] :quiet (nil) Suppress all output
      #
      #       Implies `--exit-code`.
      #
      #     @option options [Boolean] :ext_diff (nil) Allow external diff helpers
      #
      #       Pass `false` to emit `--no-ext-diff`.
      #
      #     @option options [Boolean] :textconv (nil) Allow external text-conversion filters
      #
      #       Pass `false` to emit `--no-textconv`.
      #
      #     @option options [Boolean, String] :ignore_submodules (nil) Ignore submodule changes
      #
      #       Pass `true` for `--ignore-submodules` (equivalent to `'all'`), or a string such as
      #       `'untracked'`, `'dirty'`, `'none'`, or `'all'`.
      #
      #     @option options [String] :src_prefix (nil) Source prefix for diff headers (e.g. `'a/'`)
      #
      #     @option options [String] :dst_prefix (nil) Destination prefix for diff headers (e.g. `'b/'`)
      #
      #     @option options [Boolean] :no_prefix (nil) Omit source and destination prefixes
      #
      #     @option options [Boolean] :default_prefix (nil) Use the default `a/` and `b/` prefixes
      #
      #     @option options [String] :line_prefix (nil) Prepend this prefix to every output line
      #
      #     @option options [Boolean] :ita_invisible_in_index (nil) Make `git add -N` entries appear as
      #       new files in `git diff` and non-existent in `git diff --cached`
      #
      #     @option options [Integer, String] :max_depth (nil) Maximum directory depth to descend for
      #       pathspecs
      #
      #     @return [Git::CommandLineResult] the result of calling `git diff-files`
      #
      #     @raise [Git::FailedError] if git exits with code >= 2
      #
      #   @overload call(*paths, **options)
      #     Compare the index to the working tree, limiting output to specific paths
      #
      #     @example Show unstaged changes in a specific directory
      #       # git diff-files -- lib/
      #       DiffFiles.new(ctx).call('lib/')
      #
      #     @example Show unstaged changes for multiple paths
      #       # git diff-files -- lib/ spec/
      #       DiffFiles.new(ctx).call('lib/', 'spec/')
      #
      #     @param paths [Array<String>] pathspecs limiting which files are compared
      #
      #     @param options [Hash] command options (same as the no-path overload)
      #
      #     @return [Git::CommandLineResult] the result of calling `git diff-files`
      #
      #     @raise [Git::FailedError] if git exits with code >= 2
    end
  end
end
