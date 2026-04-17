# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    # Wrapper for the `git show` command
    #
    # Displays information about git objects (commits, annotated tags, trees,
    # or blobs). Output format varies by object type and is intended for human
    # consumption rather than machine parsing.
    #
    # @example Show the HEAD commit
    #   show = Git::Commands::Show.new(execution_context)
    #   result = show.call
    #
    # @example Show a specific commit
    #   show = Git::Commands::Show.new(execution_context)
    #   result = show.call('HEAD')
    #
    # @example Show the contents of a file at a given revision
    #   show = Git::Commands::Show.new(execution_context)
    #   result = show.call('abc123:README.md')
    #
    # @example Show multiple objects
    #   show = Git::Commands::Show.new(execution_context)
    #   result = show.call('v1.0', 'v2.0')
    #
    # @note `arguments` block audited against
    #   https://git-scm.com/docs/git-show/2.53.0
    #
    # @see https://git-scm.com/docs/git-show git-show documentation
    #
    # @see Git::Commands
    #
    # @api private
    #
    class Show < Git::Commands::Base # rubocop:disable Metrics/ClassLength
      arguments do
        literal 'show'

        # Commit formatting
        flag_or_value_option :pretty, inline: true
        value_option :format, inline: true
        flag_option :abbrev_commit, negatable: true
        flag_option :oneline
        value_option :encoding, inline: true
        flag_or_value_option :expand_tabs, negatable: true, inline: true
        flag_or_value_option :notes, negatable: true, inline: true
        flag_option :show_notes_by_default
        flag_or_value_option :show_notes, inline: true
        flag_option :standard_notes, negatable: true
        flag_option :show_signature

        # Merge diff format
        flag_option :m
        flag_option :c
        flag_option :cc
        flag_option :dd
        flag_option :remerge_diff
        flag_option :no_diff_merges
        value_option :diff_merges, inline: true
        flag_option :combined_all_paths

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
        flag_option :t
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

        # Path scope
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

        execution_option :out

        operand :object, repeatable: true

        # `end_of_options` must be called after `:object` because `git show` treats
        # every operand before `--` as an object reference, and every operand after
        # `--` as a pathspec
        #
        end_of_options

        value_option :pathspec, as_operand: true, repeatable: true
      end

      # @!method call(*, **)
      #
      #   @overload call(*object, **options)
      #
      #     Trailing newlines in `result.stdout` are preserved so that blob content
      #     is returned unchanged. Pass `out:` to stream output directly to an IO
      #     object instead of capturing it.
      #
      #     @param object [Array<String>] zero or more object specifiers (refs, SHAs,
      #       `objectish:path` expressions, etc.)
      #
      #       When empty, defaults to `HEAD`
      #
      #       To access the contents of a specific file at a revision, use
      #       `objectish:path` notation (e.g. `HEAD:README.md`) as the object
      #       specifier. To filter entries within a tree object, pass the
      #       `:pathspec` option.
      #
      #     @param options [Hash] command options
      #
      #     @option options [Boolean, String] :pretty (nil) pretty-print commit
      #       log messages in the given format
      #
      #       Pass `true` for `--pretty` (defaults to `medium`); pass a string like
      #       `'oneline'` or `'format:%H %s'` for `--pretty=<format>`.
      #
      #     @option options [String] :format (nil) format string passed as
      #       `--format=<format>` (equivalent to `--pretty=tformat:<format>`)
      #
      #     @option options [Boolean] :abbrev_commit (nil) show an abbreviated
      #       commit hash prefix
      #
      #       Pass `true` for `--abbrev-commit`, `false` for `--no-abbrev-commit`.
      #
      #     @option options [Boolean] :oneline (false) shorthand for
      #       `--pretty=oneline --abbrev-commit`
      #
      #     @option options [String] :encoding (nil) re-encode the commit log
      #       message in the specified encoding
      #
      #     @option options [Boolean, Integer] :expand_tabs (nil) expand tabs in
      #       the log message before showing it
      #
      #       Pass `true` for `--expand-tabs` (tab stop every 8 columns), an integer
      #       for `--expand-tabs=<n>`, or `false` for `--no-expand-tabs`.
      #
      #     @option options [Boolean, String] :notes (nil) show notes that annotate
      #       the commit
      #
      #       Pass `true` for `--notes`, `false` for `--no-notes`, or a string like
      #       `'refs/notes/review'` for `--notes=<ref>`.
      #
      #     @option options [Boolean] :show_notes_by_default (false) show the
      #       default notes unless options for displaying specific notes are given
      #
      #     @option options [Boolean, String] :show_notes (nil) deprecated; use
      #       `:notes` instead
      #
      #     @option options [Boolean] :standard_notes (nil) deprecated; use `:notes`
      #       instead
      #
      #       Pass `true` for `--standard-notes`, `false` for `--no-standard-notes`.
      #
      #     @option options [Boolean] :show_signature (false) check the validity
      #       of a signed commit by passing the signature to `gpg --verify`
      #
      #     @option options [Boolean] :m (false) show diffs for merge commits in
      #       the default format (no output unless `-p` is also given)
      #
      #     @option options [Boolean] :c (false) produce combined diff output for
      #       merge commits; shortcut for `--diff-merges=combined -p`
      #
      #     @option options [Boolean] :cc (false) produce dense combined diff
      #       output for merge commits; shortcut for `--diff-merges=dense-combined -p`
      #
      #     @option options [Boolean] :dd (false) produce diff with respect to
      #       first parent; shortcut for `--diff-merges=first-parent -p`
      #
      #     @option options [Boolean] :remerge_diff (false) produce remerge-diff
      #       output for merge commits; shortcut for `--diff-merges=remerge -p`
      #
      #     @option options [Boolean] :no_diff_merges (false) disable diff output
      #       for merge commits; synonym for `--diff-merges=off`
      #
      #     @option options [String] :diff_merges (nil) specify the diff format for
      #       merge commits (`off`, `on`, `first-parent`, `separate`, `combined`,
      #       `dense-combined`, or `remerge`)
      #
      #     @option options [Boolean] :combined_all_paths (false) show paths from
      #       all parents when generating a combined diff
      #
      #     @option options [Boolean] :patch (false) generate patch output
      #
      #       Alias: :p, :u
      #
      #     @option options [Boolean] :no_patch (false) suppress all diff output
      #
      #       Alias: :s
      #
      #     @option options [Integer, String] :unified (nil) generate diffs with
      #       this many lines of context
      #
      #       Alias: :U
      #
      #     @option options [String] :output (nil) write output to a file instead
      #       of stdout
      #
      #     @option options [String] :output_indicator_new (nil) character to
      #       indicate new lines in the patch
      #
      #     @option options [String] :output_indicator_old (nil) character to
      #       indicate old lines in the patch
      #
      #     @option options [String] :output_indicator_context (nil) character to
      #       indicate context lines in the patch
      #
      #     @option options [Boolean] :raw (false) show a summary of changes in
      #       raw diff format
      #
      #     @option options [Boolean] :patch_with_raw (false) synonym for
      #       `--patch --raw`
      #
      #     @option options [Boolean] :t (false) show tree objects in the diff
      #       output
      #
      #     @option options [Boolean] :indent_heuristic (nil) enable or disable
      #       the indent heuristic for patch readability
      #
      #       Pass `true` for `--indent-heuristic`, `false` for
      #       `--no-indent-heuristic`.
      #
      #     @option options [Boolean] :minimal (false) spend extra time to produce
      #       the smallest possible diff
      #
      #     @option options [Boolean] :patience (false) use the patience diff
      #       algorithm
      #
      #     @option options [Boolean] :histogram (false) use the histogram diff
      #       algorithm
      #
      #     @option options [String, Array<String>] :anchored (nil) generate a diff
      #       using the anchored diff algorithm
      #
      #       Pass an array for multiple anchored texts. Maps to
      #       `--anchored=<text>`.
      #
      #     @option options [String] :diff_algorithm (nil) choose a diff algorithm
      #       (`patience`, `minimal`, `histogram`, or `myers`)
      #
      #     @option options [Boolean, String] :stat (nil) generate a diffstat
      #
      #       Pass `true` for `--stat`; pass a string like `'100,40,10'` for
      #       `--stat=100,40,10`.
      #
      #     @option options [Integer, String] :stat_width (nil) limit the width of
      #       `--stat` output
      #
      #     @option options [Integer, String] :stat_name_width (nil) limit the
      #       filename width of `--stat` output
      #
      #     @option options [Integer, String] :stat_count (nil) limit the number of
      #       lines in `--stat` output
      #
      #     @option options [Integer, String] :stat_graph_width (nil) limit the
      #       graph width of `--stat` output
      #
      #     @option options [Boolean] :compact_summary (false) output a condensed
      #       summary of extended header information
      #
      #     @option options [Boolean] :numstat (false) show per-file
      #       insertion/deletion counts in decimal notation
      #
      #     @option options [Boolean] :shortstat (false) output only the aggregate
      #       totals line from `--stat`
      #
      #     @option options [Boolean, String] :dirstat (nil) output the distribution
      #       of relative amount of changes per sub-directory
      #
      #       Pass `true` for `--dirstat`; pass a string like
      #       `'lines,cumulative'` for `--dirstat=lines,cumulative`.
      #
      #       Alias: :X
      #
      #     @option options [Boolean] :cumulative (false) synonym for
      #       `--dirstat=cumulative`
      #
      #     @option options [Boolean, String] :dirstat_by_file (nil) synonym for
      #       `--dirstat=files,...`
      #
      #     @option options [Boolean] :summary (false) output a condensed summary
      #       of extended header information
      #
      #     @option options [Boolean] :patch_with_stat (false) synonym for
      #       `--patch --stat`
      #
      #     @option options [Boolean] :z (false) use NUL as output field terminators
      #
      #     @option options [Boolean] :name_only (false) show only the name of each
      #       changed file
      #
      #     @option options [Boolean] :name_status (false) show only the name and
      #       status of each changed file
      #
      #     @option options [Boolean, String] :submodule (nil) specify how
      #       differences in submodules are shown
      #
      #       Pass `true` for `--submodule`; pass a string like `'log'` or `'diff'`
      #       for `--submodule=<format>`.
      #
      #     @option options [Boolean, String] :color (nil) show colored diff
      #
      #       Pass `true` for `--color`, `false` for `--no-color`, or a string like
      #       `'always'` for `--color=always`.
      #
      #     @option options [Boolean, String] :color_moved (nil) color moved lines
      #       differently
      #
      #       Pass `true` for `--color-moved`, `false` for `--no-color-moved`, or a
      #       string like `'zebra'` for `--color-moved=zebra`.
      #
      #     @option options [Boolean, String] :color_moved_ws (nil) configure how
      #       whitespace is handled during move detection
      #
      #       Pass `true` for `--color-moved-ws`, `false` for
      #       `--no-color-moved-ws`, or a string like `'ignore-all-space'` for
      #       `--color-moved-ws=ignore-all-space`.
      #
      #     @option options [Boolean, String] :word_diff (nil) show a word diff
      #
      #       Pass `true` for `--word-diff`; pass a string like `'color'` for
      #       `--word-diff=color`.
      #
      #     @option options [String] :word_diff_regex (nil) use this regex to
      #       decide what a word is
      #
      #     @option options [Boolean, String] :color_words (nil) equivalent to
      #       `--word-diff=color` plus optional regex
      #
      #     @option options [Boolean] :no_renames (false) turn off rename detection
      #
      #     @option options [Boolean] :rename_empty (nil) whether to use empty blobs
      #       as rename source
      #
      #       Pass `true` for `--rename-empty`, `false` for `--no-rename-empty`.
      #
      #     @option options [Boolean] :check (false) warn if changes introduce
      #       conflict markers or whitespace errors
      #
      #     @option options [String] :ws_error_highlight (nil) highlight whitespace
      #       errors in `context`, `old`, or `new` lines
      #
      #     @option options [Boolean] :full_index (false) show full pre- and
      #       post-image blob object names
      #
      #     @option options [Boolean] :binary (false) output a binary diff that can
      #       be applied with `git apply`
      #
      #     @option options [Boolean, Integer] :abbrev (nil) show only a partial
      #       prefix of object names
      #
      #       Pass `true` for `--abbrev`; pass an integer for `--abbrev=<n>`.
      #
      #     @option options [Boolean, String] :break_rewrites (nil) break complete
      #       rewrite changes into delete/create pairs
      #
      #       Alias: :B
      #
      #     @option options [Boolean, String] :find_renames (nil) detect renames,
      #       optionally specifying a similarity threshold
      #
      #       Alias: :M
      #
      #     @option options [Boolean, String] :find_copies (nil) detect copies as
      #       well as renames
      #
      #       Alias: :C
      #
      #     @option options [Boolean] :find_copies_harder (false) inspect all files
      #       as candidates for the source of copy
      #
      #     @option options [Boolean] :irreversible_delete (false) omit the
      #       preimage for deletes
      #
      #       Alias: :D
      #
      #     @option options [Integer, String] :l (nil) prevent rename/copy
      #       detection from running if the number of targets exceeds this
      #
      #     @option options [String] :diff_filter (nil) select only files matching
      #       the specified status letters
      #
      #     @option options [String] :S (nil) look for differences that change the
      #       number of occurrences of a string
      #
      #     @option options [String] :G (nil) look for differences whose patch text
      #       contains added/removed lines matching a regex
      #
      #     @option options [String] :find_object (nil) look for differences that
      #       change the number of occurrences of an object
      #
      #     @option options [Boolean] :pickaxe_all (false) when `-S` or `-G` finds
      #       a change, show all changes in that changeset
      #
      #     @option options [Boolean] :pickaxe_regex (false) treat the `-S` string
      #       as an extended POSIX regular expression
      #
      #     @option options [String] :O (nil) control the order in which files
      #       appear in the output
      #
      #     @option options [String] :skip_to (nil) discard files before the named
      #       file from the output
      #
      #     @option options [String] :rotate_to (nil) move files before the named
      #       file to the end of the output
      #
      #     @option options [Boolean] :R (false) swap two inputs (reverse diff)
      #
      #     @option options [Boolean, String] :relative (nil) show pathnames
      #       relative to a subdirectory
      #
      #       Pass `true` for `--relative`, `false` for `--no-relative`, or a
      #       string for `--relative=<path>`.
      #
      #     @option options [Boolean] :text (false) treat all files as text
      #
      #       Alias: :a
      #
      #     @option options [Boolean] :ignore_cr_at_eol (false) ignore
      #       carriage-return at end of line
      #
      #     @option options [Boolean] :ignore_space_at_eol (false) ignore changes
      #       in whitespace at end of line
      #
      #     @option options [Boolean] :ignore_space_change (false) ignore changes
      #       in amount of whitespace
      #
      #       Alias: :b
      #
      #     @option options [Boolean] :ignore_all_space (false) ignore whitespace
      #       when comparing lines
      #
      #       Alias: :w
      #
      #     @option options [Boolean] :ignore_blank_lines (false) ignore changes
      #       whose lines are all blank
      #
      #     @option options [String, Array<String>] :ignore_matching_lines (nil)
      #       ignore changes whose all lines match the given regex
      #
      #       Pass an array for multiple patterns. Maps to
      #       `--ignore-matching-lines=<regex>`.
      #
      #       Alias: :I
      #
      #     @option options [Integer, String] :inter_hunk_context (nil) show the
      #       context between diff hunks, fusing nearby hunks
      #
      #     @option options [Boolean] :function_context (false) show whole function
      #       as context lines for each change
      #
      #       Alias: :W
      #
      #     @option options [Boolean] :ext_diff (nil) allow or disallow an external
      #       diff helper
      #
      #       Pass `true` for `--ext-diff`, `false` for `--no-ext-diff`.
      #
      #     @option options [Boolean] :textconv (nil) allow or disallow external
      #       text conversion filters for binary files
      #
      #       Pass `true` for `--textconv`, `false` for `--no-textconv`.
      #
      #     @option options [Boolean, String] :ignore_submodules (nil) ignore
      #       changes to submodules in the diff
      #
      #       Pass `true` for `--ignore-submodules`; pass a string like `'all'`
      #       for `--ignore-submodules=all`.
      #
      #     @option options [String] :src_prefix (nil) source prefix for diff
      #       headers (e.g. `'a/'`)
      #
      #     @option options [String] :dst_prefix (nil) destination prefix for diff
      #       headers (e.g. `'b/'`)
      #
      #     @option options [Boolean] :no_prefix (false) do not show any source or
      #       destination prefix
      #
      #     @option options [Boolean] :default_prefix (false) use the default source
      #       and destination prefixes
      #
      #     @option options [String] :line_prefix (nil) prepend an additional prefix
      #       to every line of output
      #
      #     @option options [Boolean] :ita_invisible_in_index (false) make
      #       intent-to-add entries appear as new files in `git diff`
      #
      #     @option options [Boolean] :ita_visible_in_index (false) revert
      #       `--ita-invisible-in-index`
      #
      #     @option options [Integer, String] :max_depth (nil) descend at most this
      #       many levels of directories per pathspec
      #
      #     @option options [String, Array<String>] :pathspec (nil) limit which
      #       entries are shown within a tree object
      #
      #       Only meaningful when `object` is a tree reference (e.g.
      #       `'HEAD^{tree}'`). Pass a string or an array of strings; each is
      #       emitted after `--`. Has no effect for commits, blobs, or annotated
      #       tags — those object types silently produce no output when pathspecs
      #       are supplied.
      #
      #     @option options [IO, #write] :out (nil) stream output to this IO object
      #       instead of capturing it; `result.stdout` will be `''`
      #
      #     @return [Git::CommandLineResult] the result of calling `git show`
      #
      #        If `out:` is given, output is streamed directly to the provided IO
      #        object and `result.stdout` is `''`.
      #
      #     @raise [ArgumentError] if unsupported options are provided
      #
      #     @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      #     @api public

      private

      # @return [false] show output preserves trailing newlines, which are significant
      #   for blob content
      def chomp_captured_stdout? = false
    end
  end
end
