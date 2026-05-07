# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    # Implements the `git log` command.
    #
    # Returns commit history.
    #
    # @example Typical usage
    #   log = Git::Commands::Log.new(execution_context)
    #   log.call
    #   log.call(max_count: 20, since: '2 weeks ago')
    #   log.call('v1.0..v2.0', pretty: 'format:%H %s', path: ['lib/', 'spec/'])
    #   log.call(name_only: true, patch: true)
    #
    # @note `arguments` block audited against https://git-scm.com/docs/git-log/2.53.0
    #
    # @see https://git-scm.com/docs/git-log git-log documentation
    #
    # @see Git::Commands
    #
    # @api private
    #
    class Log < Git::Commands::Base # rubocop:disable Metrics/ClassLength
      arguments do
        literal 'log'

        # Commit Limiting
        value_option %i[max_count n], inline: true
        value_option :skip, inline: true
        value_option :since, inline: true
        value_option :after, inline: true
        value_option :since_as_filter, inline: true
        value_option :until, inline: true
        value_option :before, inline: true
        value_option :author, inline: true
        value_option :committer, inline: true
        value_option :grep_reflog, inline: true
        value_option :grep, inline: true
        flag_option :all_match
        flag_option :invert_grep
        flag_option %i[regexp_ignore_case i]
        flag_option :basic_regexp
        flag_option %i[extended_regexp E]
        flag_option %i[fixed_strings F]
        flag_option %i[perl_regexp P]
        flag_option :remove_empty
        flag_option :merges, negatable: true
        value_option :min_parents, inline: true
        value_option :max_parents, inline: true
        flag_option :first_parent
        flag_option :exclude_first_parent_only
        flag_option :all
        flag_or_value_option :branches, inline: true
        flag_or_value_option :tags, inline: true
        flag_or_value_option :remotes, inline: true
        value_option :glob, inline: true
        value_option :exclude, inline: true
        value_option :exclude_hidden, inline: true
        flag_option :reflog
        flag_option :alternate_refs
        flag_option :single_worktree
        flag_option :ignore_missing
        flag_option :bisect
        # --stdin excluded: requires stdin interaction (execution-model conflict)
        flag_option :cherry_mark
        flag_option :cherry_pick
        flag_option :left_only
        flag_option :right_only
        flag_option :cherry
        flag_option %i[walk_reflogs g]
        flag_option :merge
        flag_option :boundary

        # History Simplification
        flag_option :simplify_by_decoration
        flag_option :show_pulls
        flag_option :full_history
        flag_option :dense
        flag_option :sparse
        flag_option :simplify_merges
        flag_or_value_option :ancestry_path, inline: true

        # Commit Ordering
        flag_option :date_order
        flag_option :author_date_order
        flag_option :topo_order
        flag_option :reverse

        # Object Traversal
        flag_or_value_option :no_walk, inline: true
        flag_option :do_walk

        # Commit Formatting
        flag_or_value_option %i[pretty format], inline: true
        flag_option :abbrev_commit, negatable: true
        flag_option :oneline
        value_option :encoding, inline: true
        flag_or_value_option :expand_tabs, inline: true, negatable: true
        flag_or_value_option :notes, inline: true, negatable: true
        flag_option :show_notes_by_default
        flag_option :show_signature
        flag_option :relative_date
        value_option :date, inline: true
        flag_option :parents
        flag_option :children
        flag_option :left_right
        flag_option :graph
        flag_or_value_option :show_linear_break, inline: true
        flag_option :follow
        flag_or_value_option :decorate, inline: true, negatable: true
        value_option :decorate_refs, inline: true
        value_option :decorate_refs_exclude, inline: true
        flag_option :clear_decorations
        flag_option :source
        flag_option :use_mailmap, negatable: true
        flag_option :full_diff
        flag_option :log_size

        # Diff Formatting
        flag_option %i[patch p]
        flag_option %i[no_patch s]
        value_option :diff_merges, inline: true
        flag_option :no_diff_merges
        flag_option :combined_all_paths
        flag_option :raw
        flag_or_value_option :stat, inline: true
        flag_option :compact_summary
        flag_option :numstat
        flag_option :shortstat
        flag_or_value_option :dirstat, inline: true
        flag_option :summary
        flag_option :name_only
        flag_option :name_status
        flag_or_value_option :submodule, inline: true
        flag_or_value_option :color, inline: true, negatable: true
        flag_option :full_index
        flag_option :binary
        flag_or_value_option :abbrev, inline: true
        value_option :diff_filter, inline: true
        flag_or_value_option :find_renames, inline: true
        flag_or_value_option :find_copies, inline: true
        flag_option :find_copies_harder
        flag_or_value_option :relative, inline: true, negatable: true
        flag_option :text
        flag_option :ignore_space_at_eol
        flag_option %i[ignore_space_change b]
        flag_option %i[ignore_all_space w]
        flag_option :ignore_blank_lines
        value_option :ignore_matching_lines, inline: true
        flag_option :ext_diff, negatable: true
        flag_option :textconv, negatable: true
        flag_option :no_prefix
        value_option :src_prefix, inline: true
        value_option :dst_prefix, inline: true

        operand :revision_range, repeatable: true
        end_of_options
        value_option :path, as_operand: true, repeatable: true
        execution_option :timeout
      end

      # @!method call(*, **)
      #
      #   @overload call(*revision_range, **options)
      #
      #     Execute the `git log` command.
      #
      #     @param revision_range [Array<String>] zero or more revision specifiers
      #
      #       Examples include `'v1.0..v2.0'`, `'abc123'`, `'^v0.9'`, or any
      #       expression accepted by git-log(1). When multiple values are given they
      #       are passed as separate positional arguments to git. Defaults to no
      #       revision constraint (i.e. all reachable commits).
      #
      #     @param options [Hash] command options
      #
      #     ### Commit Limiting
      #
      #     @option options [Integer, String] :max_count (nil) maximum number of commits to output
      #
      #       Alias: `:n`
      #
      #     @option options [Integer, String] :skip (nil) skip this many commits before starting output
      #
      #     @option options [String] :since (nil) show commits more recent than the given date
      #
      #       Examples: `'2 weeks ago'`, `'2024-01-01'`
      #
      #     @option options [String] :after (nil) show commits more recent than the given date
      #       (synonym for `:since`)
      #
      #     @option options [String] :since_as_filter (nil) like `:since` but visits all commits
      #       in the range rather than stopping at the first older commit
      #
      #     @option options [String] :until (nil) show commits older than the given date
      #
      #       Examples: `'1 month ago'`, `'2024-01-01'`
      #
      #     @option options [String] :before (nil) show commits older than the given date
      #       (synonym for `:until`)
      #
      #     @option options [String] :author (nil) limit commits to those whose author line
      #       matches the given pattern (regular expression)
      #
      #     @option options [String] :committer (nil) limit commits to those whose committer
      #       line matches the given pattern (regular expression)
      #
      #     @option options [String] :grep_reflog (nil) limit commits to those with reflog entries
      #       matching the given pattern; requires `:walk_reflogs`
      #
      #     @option options [String] :grep (nil) limit commits to those whose log message matches
      #       the given pattern (regular expression)
      #
      #     @option options [Boolean, nil] :all_match (nil) limit output to commits matching all
      #       `--grep` patterns (default: any)
      #
      #     @option options [Boolean, nil] :invert_grep (nil) limit output to commits whose log
      #       message does **not** match the `:grep` pattern
      #
      #     @option options [Boolean, nil] :regexp_ignore_case (nil) match `--grep`, `--author`,
      #       and `--committer` patterns case-insensitively
      #
      #       Alias: `:i`
      #
      #     @option options [Boolean, nil] :basic_regexp (nil) treat limiting patterns as basic POSIX
      #       regular expressions (this is the default behavior)
      #
      #     @option options [Boolean, nil] :extended_regexp (nil) treat limiting patterns as extended
      #       POSIX regular expressions
      #
      #       Mutually exclusive with `:fixed_strings` and `:perl_regexp`. Alias: `:E`
      #
      #     @option options [Boolean, nil] :fixed_strings (nil) treat limiting patterns as fixed
      #       strings instead of regular expressions
      #
      #       Mutually exclusive with `:extended_regexp` and `:perl_regexp`. Alias: `:F`
      #
      #     @option options [Boolean, nil] :perl_regexp (nil) treat limiting patterns as
      #       Perl-compatible regular expressions
      #
      #       Mutually exclusive with `:extended_regexp` and `:fixed_strings`. Alias: `:P`
      #
      #     @option options [Boolean, nil] :remove_empty (nil) stop when a given path disappears
      #       from the tree
      #
      #     @option options [Boolean, nil] :merges (nil) include only merge commits (`--merges`)
      #
      #       Equivalent to `--min-parents=2`.
      #
      #     @option options [Boolean, nil] :no_merges (nil) exclude merge commits (`--no-merges`)
      #
      #       Equivalent to `--max-parents=1`.
      #
      #     @option options [Integer, String] :min_parents (nil) show only commits with at least this
      #       many parents
      #
      #     @option options [Integer, String] :max_parents (nil) show only commits with at most this
      #       many parents
      #
      #     @option options [Boolean, nil] :first_parent (nil) follow only the first parent commit
      #       upon seeing a merge commit
      #
      #     @option options [Boolean, nil] :exclude_first_parent_only (nil) when excluding commits
      #       with `^`, follow only the first parent of merge commits
      #
      #     @option options [Boolean, nil] :all (nil) pretend as if all refs in `refs/`, along
      #       with `HEAD`, are listed on the command line
      #
      #     @option options [Boolean, String, nil] :branches (nil) pretend as if all refs in
      #       `refs/heads` are listed on the command line
      #
      #       Pass a shell glob pattern (e.g. `'feature*'`) to restrict to matching branch names
      #
      #     @option options [Boolean, String, nil] :tags (nil) pretend as if all refs in
      #       `refs/tags` are listed on the command line
      #
      #       Pass a shell glob pattern to restrict to matching tag names
      #
      #     @option options [Boolean, String, nil] :remotes (nil) pretend as if all refs in
      #       `refs/remotes` are listed on the command line
      #
      #       Pass a shell glob pattern to restrict to matching remote-tracking branches
      #
      #     @option options [String] :glob (nil) pretend as if all refs matching the given shell
      #       glob pattern are listed on the command line
      #
      #     @option options [String] :exclude (nil) do not include refs matching the given glob
      #       that `--all`, `--branches`, `--tags`, `--remotes`, or `--glob` would otherwise use
      #
      #     @option options [String] :exclude_hidden (nil) do not include refs hidden by the given
      #       configuration; value is one of `fetch`, `receive`, or `uploadpack`
      #
      #     @option options [Boolean, nil] :reflog (nil) pretend as if all objects mentioned by
      #       reflogs are listed on the command line
      #
      #     @option options [Boolean, nil] :alternate_refs (nil) pretend as if all objects mentioned
      #       as ref tips of alternate repositories are listed on the command line
      #
      #     @option options [Boolean, nil] :single_worktree (nil) examine only the current working
      #       tree when `--all`, `--reflog`, or similar options are in use
      #
      #     @option options [Boolean, nil] :ignore_missing (nil) ignore invalid object names in input
      #
      #     @option options [Boolean, nil] :bisect (nil) pretend as if the bad bisect ref was listed
      #       and the good bisect refs were excluded
      #
      #     @option options [Boolean, nil] :cherry_mark (nil) like `:cherry_pick` but marks
      #       equivalent commits with `=` instead of omitting them; inequivalent ones with +++
      #
      #     @option options [Boolean, nil] :cherry_pick (nil) omit commits that introduce the same
      #       change as a commit on the other side of a symmetric difference
      #
      #     @option options [Boolean, nil] :left_only (nil) list only commits reachable from the
      #       left side of a symmetric difference
      #
      #     @option options [Boolean, nil] :right_only (nil) list only commits reachable from the
      #       right side of a symmetric difference
      #
      #     @option options [Boolean, nil] :cherry (nil) synonym for
      #       `--right-only --cherry-mark --no-merges`
      #
      #     @option options [Boolean, nil] :walk_reflogs (nil) walk reflog entries from most recent
      #       to oldest instead of the commit ancestry chain
      #
      #       Alias: `:g`
      #
      #     @option options [Boolean, nil] :merge (nil) show commits touching conflicted paths in
      #       the range `HEAD...MERGE_HEAD`; only useful with unmerged index entries
      #
      #     @option options [Boolean, nil] :boundary (nil) output excluded boundary commits,
      #       prefixed with `-`
      #
      #     ### History Simplification
      #
      #     @option options [Boolean, nil] :simplify_by_decoration (nil) show only commits referenced
      #       by some branch or tag
      #
      #     @option options [Boolean, nil] :show_pulls (nil) include merge commits that are not
      #       TREESAME to their first parent but are TREESAME to a later parent
      #
      #     @option options [Boolean, nil] :full_history (nil) do not prune history; show all commits
      #       that touched the given path(s)
      #
      #     @option options [Boolean, nil] :dense (nil) show only commits not TREESAME to any parent
      #
      #     @option options [Boolean, nil] :sparse (nil) show all commits in the simplified history
      #
      #     @option options [Boolean, nil] :simplify_merges (nil) remove needless merges from the
      #       result of `:full_history` with parent rewriting
      #
      #     @option options [Boolean, String, nil] :ancestry_path (nil) limit to commits on the
      #       ancestry chain between the range endpoints
      #
      #       Pass `true` for `--ancestry-path`; pass a commit SHA for `--ancestry-path=<commit>`
      #
      #     ### Commit Ordering
      #
      #     @option options [Boolean, nil] :date_order (nil) show commits in commit timestamp order,
      #       no parents before all children
      #
      #     @option options [Boolean, nil] :author_date_order (nil) like `:date_order` but ordered
      #       by author timestamp
      #
      #     @option options [Boolean, nil] :topo_order (nil) avoid showing commits on multiple lines
      #       of history intermixed
      #
      #     @option options [Boolean, nil] :reverse (nil) output selected commits in reverse order;
      #       cannot be combined with `:walk_reflogs`
      #
      #     ### Object Traversal
      #
      #     @option options [Boolean, String, nil] :no_walk (nil) show only the given commits without
      #       traversing ancestors
      #
      #       Pass `true` for `--no-walk` (sorted); pass `"unsorted"` for `--no-walk=unsorted`
      #
      #     @option options [Boolean, nil] :do_walk (nil) override a previous `--no-walk`
      #
      #     ### Commit Formatting
      #
      #     @option options [Boolean, String, nil] :pretty (nil) pretty-print commit log in a format
      #
      #       Pass `true` for `--pretty` (`medium` format); pass a format name such as `"oneline"`,
      #       `"short"`, `"full"`, `"fuller"`, `"email"`, `"raw"`, or a `format:<string>`
      #       expression for `--pretty=<format>`.
      #
      #       Alias: `:format`
      #
      #     @option options [Boolean, nil] :abbrev_commit (nil) abbreviate commit hash (`--abbrev-commit`)
      #
      #     @option options [Boolean, nil] :no_abbrev_commit (nil) do not abbreviate commit hash (`--no-abbrev-commit`)
      #
      #     @option options [Boolean, nil] :oneline (nil) shorthand for
      #       `--pretty=oneline --abbrev-commit`
      #
      #     @option options [String] :encoding (nil) re-encode the commit log message in the
      #       given character encoding before output
      #
      #     @option options [Boolean, String, nil] :expand_tabs (nil) expand tabs in log messages (`--expand-tabs`)
      #
      #       Pass `true` for `--expand-tabs` (width 8); pass an integer string like `"4"` for
      #       `--expand-tabs=<n>`
      #
      #     @option options [Boolean, nil] :no_expand_tabs (nil) do not expand tabs in log messages (`--no-expand-tabs`)
      #
      #     @option options [Boolean, String, nil] :notes (nil) show notes annotating the commit (`--notes`)
      #
      #       Pass `true` for `--notes`; pass a ref string for `--notes=<ref>`
      #
      #     @option options [Boolean, nil] :no_notes (nil) suppress notes output (`--no-notes`)
      #
      #     @option options [Boolean, nil] :show_notes_by_default (nil) show the default notes unless
      #       options for displaying specific notes are given
      #
      #     @option options [Boolean, nil] :show_signature (nil) verify a signed commit with
      #       `gpg --verify`
      #
      #     @option options [Boolean, nil] :relative_date (nil) show dates relative to the current
      #       time (synonym for `--date=relative`)
      #
      #     @option options [String] :date (nil) format for dates in human-readable output
      #
      #       Examples: `'relative'`, `'iso'`, `'short'`, `'format:%Y-%m-%d'`
      #
      #     @option options [Boolean, nil] :parents (nil) print the parents of each commit and
      #       enable parent rewriting
      #
      #     @option options [Boolean, nil] :children (nil) print the children of each commit and
      #       enable parent rewriting
      #
      #     @option options [Boolean, nil] :left_right (nil) mark which side of a symmetric
      #       difference a commit is reachable from (`<` for left, `>` for right)
      #
      #     @option options [Boolean, nil] :graph (nil) draw a text-based graphical representation
      #       of the commit history on the left side of output; implies `--topo-order`
      #
      #     @option options [Boolean, String, nil] :show_linear_break (nil) put a barrier between
      #       non-linear consecutive commits when `--graph` is not used
      #
      #       Pass `true` for `--show-linear-break`; pass a string for a custom barrier text
      #
      #     @option options [Boolean, nil] :follow (nil) continue listing the history of a file
      #       beyond renames; requires `:path` to be set to exactly one path element
      #
      #     @option options [Boolean, String, nil] :decorate (nil) print ref names of commits shown (`--decorate`)
      #
      #       Pass `true` for `--decorate` (short format); pass a string such as `"full"` for
      #       `--decorate=<format>`
      #
      #     @option options [Boolean, nil] :no_decorate (nil) do not print ref names (`--no-decorate`)
      #
      #     @option options [String] :decorate_refs (nil) use only refs matching this pattern
      #       for decorations
      #
      #     @option options [String] :decorate_refs_exclude (nil) do not use refs matching this
      #       pattern for decorations
      #
      #     @option options [Boolean, nil] :clear_decorations (nil) clear all previous
      #       `--decorate-refs` / `--decorate-refs-exclude` options
      #
      #     @option options [Boolean, nil] :source (nil) print the ref name by which each commit
      #       was reached
      #
      #     @option options [Boolean, nil] :use_mailmap (nil) use the mailmap file to map author/
      #       committer names and addresses to canonical real names (`--use-mailmap`)
      #
      #     @option options [Boolean, nil] :no_use_mailmap (nil) disable mailmap substitution (`--no-use-mailmap`)
      #
      #     @option options [Boolean, nil] :full_diff (nil) show full diff for commits touching the
      #       specified paths, not just the diff for those paths
      #
      #     @option options [Boolean, nil] :log_size (nil) include a `log size <n>` line for each
      #       commit indicating the length of the commit message in bytes
      #
      #     ### Diff Formatting
      #
      #     @option options [Boolean, nil] :patch (nil) generate patch output
      #
      #       Alias: `:p`
      #
      #     @option options [Boolean, nil] :no_patch (nil) suppress all diff output
      #
      #       Alias: `:s`
      #
      #     @option options [String] :diff_merges (nil) diff format for merge commits
      #
      #       Values: `"off"`, `"on"`, `"first-parent"`, `"separate"`, `"combined"`,
      #       `"dense-combined"`, `"remerge"`
      #
      #     @option options [Boolean, nil] :no_diff_merges (nil) disable diff output for merge
      #       commits (synonym for `--diff-merges=off`)
      #
      #     @option options [Boolean, nil] :combined_all_paths (nil) in combined diffs, list the
      #       file name from all parents; only meaningful with `-c` or `--cc`
      #
      #     @option options [Boolean, nil] :raw (nil) show a summary of changes using the raw diff
      #       format for each commit
      #
      #     @option options [Boolean, String, nil] :stat (nil) generate a diffstat
      #
      #       Pass `true` for `--stat`; pass a string such as `"80,40"` for
      #       `--stat=<width>[,<name-width>[,<count>]]`
      #
      #     @option options [Boolean, nil] :compact_summary (nil) output a condensed summary of
      #       extended header information in diffstat; implies `--stat`
      #
      #     @option options [Boolean, nil] :numstat (nil) like `--stat` but shows numbers of added
      #       and deleted lines in decimal notation without abbreviation
      #
      #     @option options [Boolean, nil] :shortstat (nil) output only the last line of the
      #       `--stat` format
      #
      #     @option options [Boolean, String, nil] :dirstat (nil) output distribution of relative
      #       amount of changes per sub-directory
      #
      #       Pass `true` for `--dirstat`; pass a parameter string such as `"files,10"` for
      #       `--dirstat=<params>`
      #
      #     @option options [Boolean, nil] :summary (nil) output a condensed summary of extended
      #       header information such as creations, renames, and mode changes
      #
      #     @option options [Boolean, nil] :name_only (nil) show only the names of changed files
      #
      #     @option options [Boolean, nil] :name_status (nil) show only the names and status of
      #       changed files
      #
      #     @option options [Boolean, String, nil] :submodule (nil) specify how differences in
      #       submodules are shown
      #
      #       Pass `true` for `--submodule` (log format); pass `"short"`, `"log"`, or `"diff"`
      #       for `--submodule=<format>`
      #
      #     @option options [Boolean, String, nil] :color (nil) show colored diff output (`--color`)
      #
      #       Pass `true` for `--color`; pass a string such as `"always"` for `--color=<when>`
      #
      #     @option options [Boolean, nil] :no_color (nil) suppress colored diff output (`--no-color`)
      #
      #     @option options [Boolean, nil] :full_index (nil) show the full pre- and post-image blob
      #       object names on the index line of patch output
      #
      #     @option options [Boolean, nil] :binary (nil) output a binary diff that can be applied
      #       with `git apply`; implies `--patch`
      #
      #     @option options [Boolean, String, nil] :abbrev (nil) show the shortest unique object
      #       name prefix in diff-raw output
      #
      #       Pass `true` for `--abbrev`; pass an integer string for `--abbrev=<n>`
      #
      #     @option options [String] :diff_filter (nil) select files by status letter
      #       (e.g. `"AD"` for Added and Deleted)
      #
      #     @option options [Boolean, String, nil] :find_renames (nil) detect renames
      #
      #       Pass `true` for `--find-renames`; pass a percentage threshold string such as
      #       `"90"` for `--find-renames=<n>`
      #
      #     @option options [Boolean, String, nil] :find_copies (nil) detect copies as well as
      #       renames
      #
      #       Pass `true` for `--find-copies`; pass a threshold string for `--find-copies=<n>`
      #
      #     @option options [Boolean, nil] :find_copies_harder (nil) inspect unmodified files as
      #       candidates for copy source; expensive for large projects
      #
      #     @option options [Boolean, String, nil] :relative (nil) show pathnames relative to the
      #       given subdirectory, or the current directory when run from a subdirectory (`--relative`)
      #
      #       Pass `true` for `--relative`; pass a path string for `--relative=<path>`
      #
      #     @option options [Boolean, nil] :no_relative (nil) show absolute pathnames (`--no-relative`)
      #
      #     @option options [Boolean, nil] :text (nil) treat all files as text; alias `-a`
      #
      #     @option options [Boolean, nil] :ignore_space_at_eol (nil) ignore changes in whitespace
      #       at end of line
      #
      #     @option options [Boolean, nil] :ignore_space_change (nil) ignore changes in amount of
      #       whitespace; alias `-b`
      #
      #     @option options [Boolean, nil] :ignore_all_space (nil) ignore whitespace when comparing
      #       lines; alias `-w`
      #
      #     @option options [Boolean, nil] :ignore_blank_lines (nil) ignore changes whose lines are
      #       all blank
      #
      #     @option options [String] :ignore_matching_lines (nil) ignore changes whose all lines
      #       match the given regular expression
      #
      #     @option options [Boolean, nil] :ext_diff (nil) allow external diff helpers (`--ext-diff`)
      #
      #     @option options [Boolean, nil] :no_ext_diff (nil) disallow external diff helpers (`--no-ext-diff`)
      #
      #     @option options [Boolean, nil] :textconv (nil) allow external text conversion filters
      #       when comparing binary files (`--textconv`)
      #
      #     @option options [Boolean, nil] :no_textconv (nil) disallow external text conversion filters
      #       (`--no-textconv`)
      #
      #     @option options [Boolean, nil] :no_prefix (nil) do not show any source or destination
      #       prefix
      #
      #     @option options [String] :src_prefix (nil) show the given source prefix instead of
      #       `a/`
      #
      #     @option options [String] :dst_prefix (nil) show the given destination prefix instead
      #       of `b/`
      #
      #     ### Paths
      #
      #     @option options [Array<String>] :path (nil) limit commits to those that affected the
      #       given paths
      #
      #     ### Execution
      #
      #     @option options [Integer, Float] :timeout (nil) number of seconds to wait before the
      #       command is aborted with a timeout error
      #
      #     @return [Git::CommandLineResult] the result of calling `git log`
      #
      #     @raise [ArgumentError] if unsupported options are provided
      #
      #     @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      #   @api public
      #
    end
  end
end
