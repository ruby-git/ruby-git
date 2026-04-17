# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    # Implements the `git reset` command
    #
    # Resets the current HEAD to a specified state, or updates the staged
    # version of specified files to match the state from a given commit or tree.
    #
    # @example Reset to HEAD (unstage all changes)
    #   reset = Git::Commands::Reset.new(execution_context)
    #   reset.call
    #
    # @example Hard reset to a specific commit
    #   reset = Git::Commands::Reset.new(execution_context)
    #   reset.call('HEAD~1', hard: true)
    #
    # @example Soft reset (preserve staged changes)
    #   reset = Git::Commands::Reset.new(execution_context)
    #   reset.call('HEAD~1', soft: true)
    #
    # @example Reset specific files to HEAD (unstage)
    #   reset = Git::Commands::Reset.new(execution_context)
    #   reset.call(pathspec: ['file.rb'])
    #
    # @example Reset specific files to a commit's version
    #   reset = Git::Commands::Reset.new(execution_context)
    #   reset.call('HEAD~1', pathspec: ['file.rb'])
    #
    # @note `arguments` block audited against
    #   https://git-scm.com/docs/git-reset/2.53.0
    #
    # @see https://git-scm.com/docs/git-reset git-reset
    #
    # @see Git::Commands
    #
    # @api private
    #
    class Reset < Git::Commands::Base
      arguments do
        literal 'reset'

        # Reset mode
        flag_option :soft
        flag_option :mixed
        flag_option :N
        flag_option :hard
        flag_option :merge
        flag_option :keep

        # Output
        flag_option %i[quiet q], negatable: true

        # Index refresh
        flag_option :refresh, negatable: true

        # Diff context
        value_option %i[unified U], inline: true
        value_option :inter_hunk_context, inline: true

        # Pathspec from file
        value_option :pathspec_from_file, inline: true
        flag_option :pathspec_file_nul

        # Submodule handling
        flag_option :recurse_submodules, negatable: true

        operand :commit, required: false
        end_of_options
        value_option :pathspec, as_operand: true, repeatable: true
      end

      # @!method call(*, **)
      #
      #   Execute the git reset command.
      #
      #   @overload call(commit = nil, **options)
      #
      #     @param commit [String, nil] (nil) commit or tree-ish to reset to;
      #       defaults to HEAD when not given
      #
      #     @param options [Hash] command options
      #
      #     @option options [Boolean] :soft (false) leave working tree and index unchanged;
      #       reset HEAD to the specified commit
      #
      #     @option options [Boolean] :mixed (false) reset the index but not the working tree;
      #       default mode when no mode flag is given
      #
      #     @option options [Boolean] :N (false) mark removed paths as intent-to-add;
      #       only meaningful alongside `:mixed`
      #
      #     @option options [Boolean] :hard (false) reset the index and working tree to the
      #       specified commit; discards all tracked changes since that commit
      #
      #     @option options [Boolean] :merge (false) reset the index and update files that
      #       differ between the commit and HEAD, while preserving uncommitted changes
      #
      #     @option options [Boolean] :keep (false) reset index entries and update files that
      #       differ between the commit and HEAD; aborts if any such file has local changes
      #
      #     @option options [Boolean] :quiet (nil) suppress all output; report errors only
      #
      #       Pass `true` to emit `--quiet`; pass `false` to emit `--no-quiet`.
      #
      #       Alias: :q
      #
      #     @option options [Boolean] :refresh (nil) refresh the index after a mixed reset;
      #       enabled by default when omitted
      #
      #       Pass `true` to emit `--refresh`; pass `false` to emit `--no-refresh`.
      #
      #     @option options [Integer, String] :unified (nil) number of context lines around each diff hunk
      #
      #       Alias: :U
      #
      #     @option options [Integer, String] :inter_hunk_context (nil) number of context lines to show
      #       between diff hunks
      #
      #     @option options [String] :pathspec_from_file (nil) read pathspec from the given file;
      #       pass `"-"` to read from standard input
      #
      #     @option options [Boolean] :pathspec_file_nul (false) delimit pathspec elements with NUL
      #       when reading from `:pathspec_from_file`; only meaningful alongside `:pathspec_from_file`
      #
      #     @option options [Boolean] :recurse_submodules (nil) also reset the working tree of
      #       all active submodules to the commit recorded in the superproject
      #
      #     @option options [Array<String>] :pathspec (nil) path(s) to reset in the index;
      #       when given, only the index entries for the matching paths are updated
      #
      #     @return [Git::CommandLineResult] the result of calling `git reset`
      #
      #     @raise [ArgumentError] if unsupported options are provided
      #
      #     @raise [Git::FailedError] if git exits with a non-zero exit status
    end
  end
end
