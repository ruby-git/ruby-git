# frozen_string_literal: true

require 'git/commands/arguments'
require 'git/diff_parser'

module Git
  module Commands
    module Stash
      # Show full patch output for changes recorded in a stash entry
      #
      # Uses --patch combined with --numstat to include line change counts
      # and --shortstat for totals.
      #
      # @see https://git-scm.com/docs/git-stash git-stash documentation
      # @api private
      #
      # @example Show patch for the latest stash
      #   Git::Commands::Stash::ShowPatch.new(execution_context).call
      #   # => #<Git::DiffResult files: [...]>
      #
      # @example Show patch for a specific stash
      #   Git::Commands::Stash::ShowPatch.new(execution_context).call('stash@\\{2}')
      #
      # @example Show with directory statistics
      #   Git::Commands::Stash::ShowPatch.new(execution_context).call(dirstat: true)
      #   Git::Commands::Stash::ShowPatch.new(execution_context).call(dirstat: 'lines,cumulative')
      #
      class ShowPatch
        # Arguments DSL for building command-line arguments
        ARGS = Arguments.define do
          static 'stash'
          static 'show'
          static '--patch'
          static '--numstat'
          static '--shortstat'
          flag %i[include_untracked u], negatable: true
          flag :only_untracked
          flag_or_value :dirstat, inline: true
          positional :stash
        end.freeze

        # Creates a new ShowPatch command instance
        #
        # @param execution_context [Git::ExecutionContext] the execution context for running commands
        #
        def initialize(execution_context)
          @execution_context = execution_context
        end

        # Show stash patch
        #
        # @overload call(**options)
        #
        #   Show patch for the latest stash
        #
        #   @param options [Hash] command options
        #
        #   @option options [Boolean] :include_untracked (nil) include untracked files.
        #     Alias: :u
        #
        #   @option options [Boolean] :only_untracked (nil) show only untracked files
        #
        #   @option options [Boolean, String] :dirstat (nil) include directory statistics.
        #     Pass true for default, or a string like 'lines,cumulative' for options.
        #
        # @overload call(stash, **options)
        #
        #   Show patch for a specific stash
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
        #   @option options [Boolean, String] :dirstat (nil) include directory statistics.
        #     Pass true for default, or a string like 'lines,cumulative' for options.
        #
        # @return [Git::DiffResult] diff result with per-file patch information
        #
        def call(stash = nil, dirstat: nil, **)
          output = @execution_context.command(*ARGS.build(stash, dirstat: dirstat, **)).stdout
          DiffParser::Patch.parse(output, include_dirstat: !dirstat.nil?)
        end
      end
    end
  end
end
