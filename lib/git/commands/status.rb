# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    # Implements the `git status` command
    #
    # Shows the working tree status — the differences between the index and
    # the current HEAD commit, and between the working directory and the index.
    #
    # @example Show working tree status
    #   status = Git::Commands::Status.new(execution_context)
    #   status.call
    #
    # @example Show short-format status
    #   status = Git::Commands::Status.new(execution_context)
    #   status.call(short: true)
    #
    # @example Show status in porcelain v2 format
    #   status = Git::Commands::Status.new(execution_context)
    #   status.call(porcelain: 'v2')
    #
    # @example Show status for specific paths
    #   status = Git::Commands::Status.new(execution_context)
    #   status.call('lib/', 'spec/')
    #
    # @example Show all untracked files
    #   status = Git::Commands::Status.new(execution_context)
    #   status.call(untracked_files: 'all')
    #
    # @note `arguments` block audited against
    #   https://git-scm.com/docs/git-status/2.53.0
    #
    # @see https://git-scm.com/docs/git-status git-status
    #
    # @see Git::Commands
    #
    # @api private
    #
    class Status < Git::Commands::Base
      arguments do
        literal 'status'

        # Output format
        flag_option %i[short s]
        flag_option %i[branch b]
        flag_option :show_stash
        flag_or_value_option :porcelain, inline: true
        flag_option :long
        flag_option %i[verbose v]

        # Untracked files
        flag_or_value_option %i[untracked_files u], inline: true

        # Submodule handling
        flag_or_value_option :ignore_submodules, inline: true

        # Ignored files
        flag_or_value_option :ignored, inline: true

        # NUL-terminated output
        flag_option :z

        # Column display
        flag_or_value_option :column, inline: true, negatable: true

        # Upstream tracking
        flag_option :ahead_behind, negatable: true

        # Rename detection
        flag_option :renames, negatable: true
        flag_or_value_option :find_renames, inline: true

        end_of_options

        operand :pathspec, repeatable: true
      end

      # @!method call(*, **options)
      #
      #   @param options [Hash] command options
      #
      #   @option options [Boolean, nil] :short (nil) command option key; see overload docs
      #     for the full option list
      #
      #   @overload call(*pathspecs, **options)
      #
      #     Execute the git status command
      #
      #     @param pathspecs [Array<String>] limit output to the named paths
      #
      #     @param options [Hash] command options
      #
      #     @option options [Boolean, nil] :short (nil) give output in short format
      #
      #       Alias: :s
      #
      #     @option options [Boolean, nil] :branch (nil) show the branch and tracking info
      #       even in short-format
      #
      #       Alias: :b
      #
      #     @option options [Boolean, nil] :show_stash (nil) show the number of entries
      #       currently stashed away
      #
      #     @option options [Boolean, String, nil] :porcelain (nil) give the output in an
      #       easy-to-parse format for scripts
      #
      #       When `true`, gives porcelain format. When a string (e.g. `'v1'`, `'v2'`),
      #       gives the specified porcelain format version.
      #
      #     @option options [Boolean, nil] :long (nil) give output in long format (the default)
      #
      #     @option options [Boolean, nil] :verbose (nil) in addition to names of files that
      #       have been changed, also show the textual changes that are staged
      #
      #       Alias: :v
      #
      #     @option options [Boolean, String, nil] :untracked_files (nil) show untracked files
      #
      #       Mode can be `'no'`, `'normal'`, or `'all'`. When `true`, uses the default
      #       mode.
      #
      #       Alias: :u
      #
      #     @option options [Boolean, String, nil] :ignore_submodules (nil) ignore changes
      #       to submodules
      #
      #       Mode can be `'none'`, `'untracked'`, `'dirty'`, or `'all'`.
      #
      #     @option options [Boolean, String, nil] :ignored (nil) show ignored files as well
      #
      #       Mode can be `'traditional'`, `'no'`, or `'matching'`.
      #
      #     @option options [Boolean, nil] :z (nil) terminate entries with NUL instead of
      #       newline (`-z`)
      #
      #       Implies `--porcelain=v1`
      #
      #     @option options [Boolean, String, nil] :column (nil) display untracked files in
      #       columns (`--column`)
      #
      #       Pass `true` for `--column` or a string of options for `--column=<options>`.
      #
      #     @option options [Boolean, nil] :no_column (nil) disable column output (`--no-column`)
      #
      #     @option options [Boolean, nil] :ahead_behind (nil) show ahead/behind counts for
      #       the branch (`--ahead-behind`)
      #
      #     @option options [Boolean, nil] :no_ahead_behind (nil) suppress ahead/behind counts
      #       for the branch (`--no-ahead-behind`)
      #
      #     @option options [Boolean, nil] :renames (nil) turn on rename detection (`--renames`)
      #
      #     @option options [Boolean, nil] :no_renames (nil) turn off rename detection
      #       (`--no-renames`)
      #
      #     @option options [Boolean, String, nil] :find_renames (nil) turn on rename detection
      #       with optional similarity threshold
      #
      #       When `true`, enables rename detection without a threshold. When a string
      #       (e.g. `'50'`), adds `--find-renames=<n>`.
      #
      #     @return [Git::CommandLineResult] the result of calling `git status`
      #
      #     @raise [ArgumentError] if unsupported options are provided
      #
      #     @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      #   @api public
    end
  end
end
