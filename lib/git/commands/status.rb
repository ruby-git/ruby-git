# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    # Implements the `git status` command
    #
    # Shows the working tree status — the differences between the index and
    # the current HEAD commit, and between the working directory and the index.
    #
    # @see https://git-scm.com/docs/git-status git-status documentation
    #
    # @see Git::Commands
    #
    # @api private
    #
    # @example Show working tree status
    #   Git::Commands::Status.new(ctx).call
    #
    # @example Show short-format status
    #   Git::Commands::Status.new(ctx).call(short: true)
    #
    # @example Show status in porcelain v2 format
    #   Git::Commands::Status.new(ctx).call(porcelain: 'v2')
    #
    # @example Show status for specific paths
    #   Git::Commands::Status.new(ctx).call('lib/', 'spec/')
    #
    # @example Show all untracked files
    #   Git::Commands::Status.new(ctx).call(untracked_files: 'all')
    #
    class Status < Git::Commands::Base
      arguments do
        literal 'status'

        flag_option %i[short s]
        flag_option %i[branch b]
        flag_option :show_stash
        flag_option :long
        flag_option %i[verbose v]
        flag_or_value_option :porcelain, inline: true
        flag_or_value_option %i[untracked_files u], inline: true
        flag_or_value_option :ignore_submodules, inline: true
        flag_or_value_option :ignored, inline: true
        flag_or_value_option :column, inline: true, negatable: true
        flag_option :ahead_behind, negatable: true
        flag_option :renames, negatable: true
        flag_or_value_option :find_renames, inline: true
        flag_option :z

        end_of_options

        operand :pathspec, repeatable: true
      end

      # @!method call(*, **)
      #
      #   @overload call(*pathspecs, **options)
      #
      #     Execute the git status command
      #
      #     @param pathspecs [Array<String>] Limit output to the named paths
      #
      #     @param options [Hash] command options
      #
      #     @option options [Boolean] :short (nil) Give output in short format
      #
      #       Alias: :s
      #
      #     @option options [Boolean] :branch (nil) Show the branch and tracking info
      #       even in short-format
      #
      #       Alias: :b
      #
      #     @option options [Boolean] :show_stash (nil) Show the number of entries
      #       currently stashed away
      #
      #     @option options [Boolean] :long (nil) Give output in long format (the default)
      #
      #     @option options [Boolean] :verbose (nil) In addition to names of files that
      #       have been changed, also show the textual changes that are staged
      #
      #       Alias: :v
      #
      #     @option options [Boolean, String] :porcelain (nil) Give the output in an
      #       easy-to-parse format for scripts
      #
      #       When `true`, gives porcelain format. When a string (e.g. `'v1'`, `'v2'`),
      #       gives the specified porcelain format version.
      #
      #     @option options [Boolean, String] :untracked_files (nil) Show untracked files
      #
      #       Mode can be `'no'`, `'normal'`, or `'all'`. When `true`, uses the default
      #       mode.
      #
      #       Alias: :u
      #
      #     @option options [Boolean, String] :ignore_submodules (nil) Ignore changes
      #       to submodules
      #
      #       Mode can be `'none'`, `'untracked'`, `'dirty'`, or `'all'`.
      #
      #     @option options [Boolean, String] :ignored (nil) Show ignored files as well
      #
      #       Mode can be `'traditional'`, `'no'`, or `'matching'`.
      #
      #     @option options [Boolean, String] :column (nil) Display untracked files in
      #       columns
      #
      #       When `false`, adds `--no-column`. When a string, adds `--column=<options>`.
      #
      #     @option options [Boolean] :ahead_behind (nil) Show or suppress ahead/behind
      #       counts for the branch
      #
      #       When `false`, adds `--no-ahead-behind`.
      #
      #     @option options [Boolean] :renames (nil) Turn on/off rename detection
      #
      #       When `false`, adds `--no-renames`.
      #
      #     @option options [Boolean, String] :find_renames (nil) Turn on rename detection
      #       with optional similarity threshold
      #
      #       When `true`, enables rename detection without a threshold. When a string
      #       (e.g. `'50'`), adds `--find-renames=<n>`.
      #
      #     @option options [Boolean] :z (nil) Terminate entries with NUL instead of
      #       newline (`-z`)
      #
      #       Implies `--porcelain=v1`
      #
      #     @return [Git::CommandLineResult] the result of calling `git status`
      #
      #     @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      #   @api public
    end
  end
end
