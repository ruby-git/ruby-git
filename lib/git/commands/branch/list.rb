# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Branch
      # Implements the `git branch --list` command
      #
      # @example Basic branch listing
      #   list = Git::Commands::Branch::List.new(execution_context)
      #   branches = list.call
      #
      # @example List all branches (local and remote)
      #   list = Git::Commands::Branch::List.new(execution_context)
      #   all_branches = list.call(all: true)
      #
      # @example List branches containing a commit
      #   list = Git::Commands::Branch::List.new(execution_context)
      #   branches = list.call(contains: 'abc123')
      #
      # @example List branches with patterns
      #   list = Git::Commands::Branch::List.new(execution_context)
      #   feature_branches = list.call('feature/*')
      #
      # @see Git::Commands::Branch
      #
      # @see https://git-scm.com/docs/git-branch git-branch
      #
      # @api private
      #
      class List < Git::Commands::Base
        arguments do
          literal 'branch'
          literal '--list'

          flag_or_value_option :color, inline: true, negatable: true     # --color[=<when>] / --no-color
          flag_option %i[verbose v], max_times: 2                        # --verbose (alias: :v)
          flag_or_value_option :abbrev, inline: true, negatable: true    # --abbrev[=<n>] / --no-abbrev
          flag_or_value_option :column, inline: true, negatable: true    # --column[=<options>] / --no-column
          value_option :sort, inline: true, repeatable: true             # --sort=<key>
          flag_or_value_option :merged                                   # --merged [<commit>]
          flag_or_value_option :no_merged                                # --no-merged [<commit>]
          flag_or_value_option :contains                                 # --contains [<commit>]
          flag_or_value_option :no_contains                              # --no-contains [<commit>]
          value_option :points_at                                        # --points-at <object>
          value_option :format, inline: true                             # --format=<format>
          flag_option %i[remotes r]                                      # --remotes (alias: :r)
          flag_option %i[all a]                                          # --all (alias: :a)
          flag_option %i[ignore_case i]                                  # --ignore-case (alias: :i)
          flag_option :omit_empty                                        # --omit-empty

          end_of_options

          operand :pattern, repeatable: true
        end

        # @!method call(*, **)
        #
        #   @overload call(*pattern, **options)
        #
        #     Execute the `git branch --list` command
        #
        #     @param pattern [Array<String>] shell wildcard patterns to filter branches
        #
        #       If multiple patterns are given, a branch is shown if it matches any of the patterns.
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean, String] :color (nil) color branches output
        #
        #       Pass `true` for `--color`, a string (`'always'`, `'never'`, `'auto'`) for
        #       `--color=<when>`, or `false` for `--no-color`.
        #
        #     @option options [Boolean, Integer] :verbose (nil) show sha1 and commit
        #       subject for each branch
        #
        #       Pass `true` for `--verbose` (show sha1 and subject); pass `2` for
        #       `--verbose --verbose` (also show the linked worktree path and upstream
        #       branch name).
        #
        #       Alias: :v
        #
        #     @option options [Boolean, Integer] :abbrev (nil) minimum sha1 display
        #       length when used with verbose mode
        #
        #       Pass an integer for `--abbrev=<n>`, `true` for `--abbrev` (default length),
        #       or `false` for `--no-abbrev` (full sha1s).
        #
        #     @option options [Boolean, String] :column (nil) display branch listing in
        #       columns
        #
        #       Pass `true` for `--column`, a string of options for `--column=<options>`,
        #       or `false` for `--no-column`. Only applicable in non-verbose mode.
        #
        #     @option options [String, Array<String>] :sort (nil) sort branches by the
        #       specified key(s)
        #
        #       Give an array to add multiple --sort options. Prefix each key with '-' for
        #       descending order. For example, sort: ['refname', '-committerdate'].
        #
        #     @option options [Boolean, String] :merged (nil) list only branches merged
        #       into the specified commit
        #
        #       Pass `true` to default to HEAD or a commit ref string to filter by
        #       that commit.
        #
        #     @option options [Boolean, String] :no_merged (nil) list only branches not
        #       merged into the specified commit
        #
        #       Pass `true` to default to HEAD or a commit ref string to filter by
        #       that commit.
        #
        #     @option options [Boolean, String] :contains (nil) list only branches that
        #       contain the specified commit
        #
        #       Pass `true` to default to HEAD or a commit ref string to filter by
        #       that commit.
        #
        #     @option options [Boolean, String] :no_contains (nil) list only branches
        #       that don't contain the specified commit
        #
        #       Pass `true` to default to HEAD or a commit ref string to filter by
        #       that commit.
        #
        #     @option options [String] :points_at (nil) list only branches that point
        #       at the specified object
        #
        #     @option options [String] :format (nil) output format string for each branch
        #
        #     @option options [Boolean] :remotes (nil) list only remote-tracking
        #       branches
        #
        #       Alias: :r
        #
        #     @option options [Boolean] :all (nil) list both local and remote branches
        #
        #       Alias: :a
        #
        #     @option options [Boolean] :ignore_case (nil) sort and filter branches
        #       case insensitively
        #
        #       Alias: :i
        #
        #     @option options [Boolean] :omit_empty (nil) do not print a newline after
        #       formatted refs where the format expands to the empty string
        #
        #     @return [Git::CommandLineResult] the result of calling `git branch --list`
        #
        #     @raise [ArgumentError] if unsupported options are provided
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
      end
    end
  end
end
