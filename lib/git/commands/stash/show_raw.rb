# frozen_string_literal: true

require 'git/commands/arguments'
require 'git/diff_parser'

module Git
  module Commands
    module Stash
      # Show raw diff output for a stash entry
      #
      # Uses --raw output format with rename detection (-M) enabled by default,
      # combined with --numstat for line change counts and --shortstat for totals.
      #
      # @see https://git-scm.com/docs/git-stash git-stash documentation
      # @api private
      #
      # @example Show raw diff for the latest stash
      #   Git::Commands::Stash::ShowRaw.new(execution_context).call
      #   # => #<Git::DiffResult files: [...]>
      #
      # @example Show with copy detection
      #   Git::Commands::Stash::ShowRaw.new(execution_context).call(find_copies: true)
      #
      # @example Show with directory statistics
      #   Git::Commands::Stash::ShowRaw.new(execution_context).call(dirstat: true)
      #   Git::Commands::Stash::ShowRaw.new(execution_context).call(dirstat: 'lines,cumulative')
      #
      class ShowRaw
        # Arguments DSL for building command-line arguments
        ARGS = Arguments.define do
          static 'stash'
          static 'show'
          static '--raw'
          static '--numstat'
          static '--shortstat'
          static '-M'
          negatable_flag %i[include_untracked u]
          flag :only_untracked
          flag :find_copies, args: '-C'
          flag_or_inline_value :dirstat
          positional :stash
        end.freeze

        # Creates a new ShowRaw command instance
        #
        # @param execution_context [Git::ExecutionContext] the execution context for running commands
        #
        def initialize(execution_context)
          @execution_context = execution_context
        end

        # Show stash raw diff
        #
        # @overload call(**options)
        #
        #   Show raw diff for the latest stash
        #
        #   @param options [Hash] command options
        #
        #   @option options [Boolean] :include_untracked (nil) include untracked files.
        #     Alias: :u
        #
        #   @option options [Boolean] :only_untracked (nil) show only untracked files
        #
        #   @option options [Boolean] :find_copies (nil) detect copies as well as renames
        #
        #   @option options [Boolean, String] :dirstat (nil) include directory statistics.
        #     Pass true for default, or a string like 'lines,cumulative' for options.
        #
        # @overload call(stash, **options)
        #
        #   Show raw diff for a specific stash
        #
        #   @param stash [String] stash reference (e.g., 'stash@\\{0}', '0')
        #
        #   @param options [Hash] command options
        #
        #   @option options [Boolean] :include_untracked (nil) include untracked files.
        #     Alias: :u
        #
        #   @option options [Boolean] :only_untracked (nil) show only untracked files
        #
        #   @option options [Boolean] :find_copies (nil) detect copies as well as renames
        #
        #   @option options [Boolean, String] :dirstat (nil) include directory statistics.
        #     Pass true for default, or a string like 'lines,cumulative' for options.
        #
        # @return [Git::DiffResult] diff result with per-file raw info
        #
        def call(stash = nil, dirstat: nil, **)
          output = @execution_context.command(*ARGS.build(stash, dirstat: dirstat, **)).stdout
          DiffParser::Raw.parse(output, include_dirstat: !dirstat.nil?)
        end
      end
    end
  end
end
