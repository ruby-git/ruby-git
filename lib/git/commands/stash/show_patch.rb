# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Stash
      # Show full patch output for changes recorded in a stash entry
      #
      # @see Git::Commands::Stash Git::Commands::Stash for usage examples
      #
      # @see https://git-scm.com/docs/git-stash git-stash documentation
      #
      # @api private
      #
      # @example Show patch for the latest stash
      #   Git::Commands::Stash::ShowPatch.new(execution_context).call
      #
      # @example Show patch for a specific stash
      #   Git::Commands::Stash::ShowPatch.new(execution_context).call('stash@\\{2}')
      #
      # @example Show with directory statistics
      #   Git::Commands::Stash::ShowPatch.new(execution_context).call(dirstat: true)
      #   Git::Commands::Stash::ShowPatch.new(execution_context).call(dirstat: 'lines,cumulative')
      #
      class ShowPatch < Git::Commands::Base
        arguments do
          literal 'stash'
          literal 'show'
          # These three format literals are always emitted together. The stash diff parser
          # expects all three sections to be present in every stash show command's output:
          # --patch for per-file unified diffs, --numstat for per-file line counts, and
          # --shortstat for aggregate totals. Fixing them here keeps the parser contract
          # simple and unconditional.
          literal '--patch'
          literal '--numstat'    # always present alongside --patch: parser requires per-file counts
          literal '--shortstat'  # always present alongside --patch: parser requires aggregate totals
          flag_option %i[include_untracked u], negatable: true
          flag_option :only_untracked
          flag_or_value_option %i[find_renames M], inline: true
          flag_or_value_option %i[find_copies C], inline: true
          flag_option :find_copies_harder
          flag_or_value_option :dirstat, inline: true
          operand :stash
          conflicts :include_untracked, :only_untracked
        end

        # @!method call(*, **)
        #
        #   Show stash patch
        #
        #   @overload call(**options)
        #
        #     Show patch for the latest stash
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean] :include_untracked (nil) include untracked files.
        #
        #       Alias: :u
        #
        #     @option options [Boolean] :only_untracked (nil) show only untracked files
        #
        #     @option options [Boolean, Integer] :find_renames (nil) detect renames; optionally pass a
        #       similarity threshold (e.g., 50 for 50%). Alias: :M
        #
        #     @option options [Boolean, Integer] :find_copies (nil) detect copies as well as renames;
        #       optionally pass a threshold. Alias: :C
        #
        #     @option options [Boolean] :find_copies_harder (nil) inspect all files as copy sources; expensive
        #
        #     @option options [Boolean, String] :dirstat (nil) include directory statistics.
        #       Pass true for default, or a string like 'lines,cumulative' for options.
        #
        #   @overload call(stash, **options)
        #
        #     Show patch for a specific stash
        #
        #     @param stash [String] stash reference (e.g., 'stash@\\{0}', '0')
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean] :include_untracked (nil) include untracked files.
        #
        #       Alias: :u
        #
        #     @option options [Boolean] :only_untracked (nil) show only untracked files
        #
        #     @option options [Boolean, Integer] :find_renames (nil) detect renames; optionally pass a
        #       similarity threshold (e.g., 50 for 50%). Alias: :M
        #
        #     @option options [Boolean, Integer] :find_copies (nil) detect copies as well as renames;
        #       optionally pass a threshold. Alias: :C
        #
        #     @option options [Boolean] :find_copies_harder (nil) inspect all files as copy sources; expensive
        #
        #     @option options [Boolean, String] :dirstat (nil) include directory statistics.
        #       Pass true for default, or a string like 'lines,cumulative' for options.
        #
        #   @return [Git::CommandLineResult] the result of calling `git stash show --patch`
      end
    end
  end
end
