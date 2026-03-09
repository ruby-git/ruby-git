# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    # Implements the `git log` command with raw output format
    #
    # Returns commit history in `--pretty=raw` format, which is machine-parseable
    # and contains the full commit metadata needed to reconstruct commit objects.
    #
    # @see https://git-scm.com/docs/git-log git-log documentation
    # @see Git::Commands
    #
    # @api private
    #
    # @example List all commits on current branch
    #   log = Git::Commands::Log.new(execution_context)
    #   result = log.call
    #
    # @example Limit to 20 commits since a given date
    #   log = Git::Commands::Log.new(execution_context)
    #   result = log.call(max_count: 20, since: '1 week ago')
    #
    # @example Show commits between two refs
    #   log = Git::Commands::Log.new(execution_context)
    #   result = log.call('v2.5..v2.6', max_count: 10)
    #
    # @example Show commits touching specific paths
    #   log = Git::Commands::Log.new(execution_context)
    #   result = log.call(path: ['lib/', 'spec/'])
    #
    class Log < Git::Commands::Base
      arguments do
        literal 'log'
        literal '--no-color'
        literal '--pretty=raw'

        # Ref inclusion
        flag_option :all
        flag_or_value_option :branches, inline: true
        flag_or_value_option :tags, inline: true
        flag_or_value_option :remotes, inline: true

        # Symmetric difference / cherry-pick filtering
        flag_option :cherry
        flag_option :cherry_mark
        flag_option :cherry_pick
        flag_option :left_right

        # Parent count filtering
        flag_option :merges, negatable: true
        flag_option :first_parent
        value_option :min_parents, inline: true
        value_option :max_parents, inline: true

        # Date filtering
        value_option :since, inline: true
        value_option :after, inline: true
        value_option :until, inline: true
        value_option :before, inline: true

        # Message / grep filtering
        value_option :grep, inline: true
        flag_option :all_match
        flag_option :invert_grep
        flag_option %i[regexp_ignore_case i]
        flag_option %i[extended_regexp E]
        flag_option %i[fixed_strings F]
        flag_option %i[perl_regexp P]

        # Author / committer filtering
        value_option :author, inline: true
        value_option :committer, inline: true

        # Output volume
        value_option :max_count, inline: true
        value_option :skip, inline: true

        # History traversal / simplification
        flag_option :follow
        flag_option :full_history

        # Commit ordering
        flag_option :date_order
        flag_option :author_date_order
        flag_option :topo_order
        flag_option :reverse

        operand :revision_range, repeatable: true
        value_option :path, as_operand: true, separator: '--', repeatable: true
        execution_option :timeout
      end

      # @overload call(*revision_range, **options)
      #
      #   Execute the `git log` command.
      #
      #   @param revision_range [Array<String>] zero or more revision specifiers,
      #     e.g. `'v1.0..v2.0'`, `'abc123'`, `'^v0.9'`, or any expression
      #     accepted by git-log(1). When multiple values are given they are
      #     passed as separate positional arguments to git. Defaults to no
      #     revision constraint (i.e. all reachable commits).
      #
      #   @param options [Hash] command options
      #
      #   @option options [Boolean] :all (nil) Pretend all refs in refs/, along
      #     with HEAD, are listed on the command line
      #
      #   @option options [Boolean, String] :branches (nil) Pretend all refs in
      #     refs/heads are listed on the command line. Pass a shell glob
      #     pattern (e.g. `'feature*'`) to restrict to matching branch names.
      #
      #   @option options [Boolean, String] :tags (nil) Pretend all refs in
      #     refs/tags are listed on the command line. Pass a shell glob
      #     pattern to restrict to matching tag names.
      #
      #   @option options [Boolean, String] :remotes (nil) Pretend all refs in
      #     refs/remotes are listed on the command line. Pass a shell glob
      #     pattern to restrict to matching remote-tracking branches.
      #
      #   @option options [Boolean] :cherry (nil) Synonym for
      #     `--right-only --cherry-mark --no-merges`; marks commits equivalent
      #     on both sides of a symmetric range
      #
      #   @option options [Boolean] :cherry_mark (nil) Like `--cherry-pick`
      #     but marks equivalent commits with `=` rather than omitting them,
      #     and inequivalent ones with `+`
      #
      #   @option options [Boolean] :cherry_pick (nil) Omit commits that
      #     introduce the same change as a commit on the other side of a
      #     symmetric difference
      #
      #   @option options [Boolean] :left_right (nil) Mark which side of a
      #     symmetric difference a commit is reachable from (`<` for left,
      #     `>` for right)
      #
      #   @option options [Boolean] :merges (nil) Filter by merge status.
      #
      #     `true` → `--merges` (only merge commits); `false` → `--no-merges`
      #     (exclude merge commits); `nil` → no filter.
      #
      #     Note: `--merges` is equivalent to `--min-parents=2` and
      #     `--no-merges` is equivalent to `--max-parents=1`. Specifying
      #     both `:merges` and a contradictory `:min_parents`/`:max_parents`
      #     value will produce inconsistent results.
      #
      #   @option options [Boolean] :first_parent (nil) Follow only the first
      #     parent commit upon seeing a merge commit
      #
      #   @option options [Integer] :min_parents (nil) Show only commits with at
      #     least this many parents
      #
      #   @option options [Integer] :max_parents (nil) Show only commits with at
      #     most this many parents
      #
      #   @option options [String] :since (nil) Show commits more recent than
      #     the given date. Examples: '2 weeks ago', '2024-01-01'
      #
      #   @option options [String] :after (nil) Alias for `:since`
      #
      #   @option options [String] :until (nil) Show commits older than the
      #     given date. Examples: '1 month ago', '2024-01-01'
      #
      #   @option options [String] :before (nil) Alias for `:until`
      #
      #   @option options [String] :grep (nil) Limit commits to those whose log
      #     message matches the given pattern
      #
      #   @option options [Boolean] :all_match (nil) Limit output to commits
      #     that match all `--grep` patterns (default: any). Requires
      #     `:grep` to be set.
      #
      #   @option options [Boolean] :invert_grep (nil) Limit output to commits
      #     whose log message does **not** match the `--grep` pattern.
      #     Requires `:grep` to be set.
      #
      #   @option options [Boolean] :regexp_ignore_case (nil) Match `--grep`,
      #     `--author`, and `--committer` patterns case-insensitively.
      #     Short alias: `:i`
      #
      #   @option options [Boolean] :extended_regexp (nil) Treat limiting
      #     patterns as extended POSIX regular expressions. Mutually
      #     exclusive with `:fixed_strings` and `:perl_regexp`.
      #     Short alias: `:E`
      #
      #   @option options [Boolean] :fixed_strings (nil) Treat limiting
      #     patterns as fixed strings instead of regular expressions.
      #     Mutually exclusive with `:extended_regexp` and `:perl_regexp`.
      #     Short alias: `:F`
      #
      #   @option options [Boolean] :perl_regexp (nil) Treat limiting patterns
      #     as Perl-compatible regular expressions. Mutually exclusive with
      #     `:extended_regexp` and `:fixed_strings`.
      #     Short alias: `:P`
      #
      #   @option options [String] :author (nil) Limit commits to those whose
      #     author line matches the given pattern (name or email)
      #
      #   @option options [String] :committer (nil) Limit commits to those
      #     whose committer line matches the given pattern (name or email)
      #
      #   @option options [Integer] :max_count (nil) Maximum number of commits
      #     to output
      #
      #   @option options [Integer] :skip (nil) Skip the given number of
      #     commits before starting to output
      #
      #   @option options [Boolean] :follow (nil) Continue listing the history
      #     of a file beyond renames. Requires `:path` to be set and
      #     `:path` must contain exactly one element.
      #
      #   @option options [Boolean] :full_history (nil) Do not prune history;
      #     show all commits that touched the given path(s)
      #
      #   @option options [Boolean] :date_order (nil) Show no parents before
      #     all of their children are shown, ordered by commit timestamp
      #
      #   @option options [Boolean] :author_date_order (nil) Like `:date_order`
      #     but ordered by author timestamp
      #
      #   @option options [Boolean] :topo_order (nil) Avoid showing commits on
      #     multiple lines of history intermixed
      #
      #   @option options [Boolean] :reverse (nil) Output selected commits in
      #     reverse order
      #
      #   @option options [Array<String>] :path (nil) Limit commits to those
      #     that affected the given paths
      #
      #   @option options [Integer, Float] :timeout (nil) Seconds before the
      #     command times out. Forwarded to the execution context; not passed
      #     to git as a CLI flag.
      #
      #   @return [Git::CommandLineResult] the result of calling `git log`
      #
      #   @raise [ArgumentError] if unsupported options are provided
      #
      #   @raise [Git::FailedError] if the command returns a non-zero exit status
    end
  end
end
