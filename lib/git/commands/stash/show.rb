# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Stash
      # Show the changes recorded in a stash entry as a diff
      #
      # Shows the changes recorded in the stash entry as a diff between the
      # stashed contents and the commit back when the stash entry was first
      # created.
      #
      # @note `arguments` block audited against https://git-scm.com/docs/git-stash/2.53.0
      #
      # @see Git::Commands::Stash Git::Commands::Stash for usage examples
      #
      # @see https://git-scm.com/docs/git-stash git-stash documentation
      #
      # @api private
      #
      # @example Show numstat for the latest stash
      #   Git::Commands::Stash::Show.new(ctx).call(numstat: true, shortstat: true)
      #
      # @example Show patch for a specific stash
      #   Git::Commands::Stash::Show.new(ctx).call('stash@{2}', patch: true, numstat: true, shortstat: true)
      #
      # @example Show with directory statistics
      #   Git::Commands::Stash::Show.new(ctx).call(numstat: true, shortstat: true, dirstat: true)
      #   Git::Commands::Stash::Show.new(ctx).call(numstat: true, shortstat: true, dirstat: 'lines,cumulative')
      #
      class Show < Git::Commands::Base
        arguments do
          literal 'stash'
          literal 'show'

          flag_option :patch
          flag_option :numstat
          flag_option :raw
          flag_option :shortstat
          value_option %i[unified U], inline: true

          flag_option %i[include_untracked u], negatable: true
          flag_option :only_untracked
          flag_or_value_option %i[find_renames M], inline: true
          flag_or_value_option %i[find_copies C], inline: true
          flag_option :find_copies_harder
          value_option :inter_hunk_context, inline: true
          flag_or_value_option :dirstat, inline: true
          operand :stash
        end

        # @!method call(*, **)
        #
        #   Show stash diff
        #
        #   @overload call(**options)
        #
        #     Show diff for the latest stash
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean] :patch (false) include unified diff patches per file
        #
        #     @option options [Boolean] :numstat (false) include per-file insertion/deletion counts
        #
        #     @option options [Boolean] :raw (false) include per-file mode/SHA/status metadata
        #
        #     @option options [Boolean] :shortstat (false) include aggregate totals line
        #
        #     @option options [Integer, String] :unified (nil) generate diff with <n> lines of context
        #
        #       Alias: :U
        #
        #     @option options [Boolean] :include_untracked (false) include untracked files (`--include-untracked`)
        #
        #       Alias: :u
        #
        #     @option options [Boolean] :no_include_untracked (false) exclude untracked files
        #       (`--no-include-untracked`)
        #
        #     @option options [Boolean] :only_untracked (false) show only untracked files
        #
        #     @option options [Boolean, Integer] :find_renames (nil) detect renames; optionally pass a
        #       similarity threshold (e.g., 50 for 50%). Alias: :M
        #
        #     @option options [Boolean, Integer] :find_copies (nil) detect copies as well as renames;
        #       optionally pass a threshold. Alias: :C
        #
        #     @option options [Boolean] :find_copies_harder (false) inspect all files as copy sources; expensive
        #
        #     @option options [Integer, String] :inter_hunk_context (nil) show context between diff hunks, up to
        #       <n> lines, fusing hunks that are close to each other
        #
        #     @option options [Boolean, String] :dirstat (nil) include directory statistics
        #
        #       Pass `true` for default, or a string like `'lines,cumulative'` for options.
        #
        #   @overload call(stash, **options)
        #
        #     Show diff for a specific stash
        #
        #     @param stash [String] stash reference (e.g., 'stash@\\{0}', '0')
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean] :patch (false) include unified diff patches per file
        #
        #     @option options [Boolean] :numstat (false) include per-file insertion/deletion counts
        #
        #     @option options [Boolean] :raw (false) include per-file mode/SHA/status metadata
        #
        #     @option options [Boolean] :shortstat (false) include aggregate totals line
        #
        #     @option options [Integer, String] :unified (nil) generate diff with <n> lines of context
        #
        #       Alias: :U
        #
        #     @option options [Boolean] :include_untracked (false) include untracked files (`--include-untracked`)
        #
        #       Alias: :u
        #
        #     @option options [Boolean] :no_include_untracked (false) exclude untracked files
        #       (`--no-include-untracked`)
        #
        #     @option options [Boolean] :only_untracked (false) show only untracked files
        #
        #     @option options [Boolean, Integer] :find_renames (nil) detect renames; optionally pass a
        #       similarity threshold (e.g., 50 for 50%). Alias: :M
        #
        #     @option options [Boolean, Integer] :find_copies (nil) detect copies as well as renames;
        #       optionally pass a threshold. Alias: :C
        #
        #     @option options [Boolean] :find_copies_harder (false) inspect all files as copy sources; expensive
        #
        #     @option options [Integer, String] :inter_hunk_context (nil) show context between diff hunks, up to
        #       <n> lines, fusing hunks that are close to each other
        #
        #     @option options [Boolean, String] :dirstat (nil) include directory statistics
        #
        #       Pass `true` for default, or a string like `'lines,cumulative'` for options.
        #
        #   @return [Git::CommandLineResult] the result of calling `git stash show`
        #
        #   @raise [Git::FailedError] if git returns a non-zero exit status
      end
    end
  end
end
