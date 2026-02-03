# frozen_string_literal: true

require 'git/commands/arguments'
require 'git/diff_parser'

module Git
  module Commands
    module Stash
      # Show numstat (line counts) for changes recorded in a stash entry
      #
      # @see https://git-scm.com/docs/git-stash git-stash documentation
      # @api private
      #
      # @example Show stats for the latest stash
      #   Git::Commands::Stash::ShowNumstat.new(execution_context).call
      #   # => #<Git::DiffResult files_changed: 2, ...>
      #
      # @example Show stats for a specific stash
      #   Git::Commands::Stash::ShowNumstat.new(execution_context).call('stash@\\{2}')
      #
      # @example Show with directory statistics
      #   Git::Commands::Stash::ShowNumstat.new(execution_context).call(dirstat: true)
      #   Git::Commands::Stash::ShowNumstat.new(execution_context).call(dirstat: 'lines,cumulative')
      #
      class ShowNumstat
        # Arguments DSL for building command-line arguments
        ARGS = Arguments.define do
          static 'stash'
          static 'show'
          static '--numstat'
          static '--shortstat'
          static '-M'
          flag %i[include_untracked u], negatable: true
          flag :only_untracked
          flag_or_value :dirstat, inline: true
          positional :stash
        end.freeze

        # Creates a new ShowNumstat command instance
        #
        # @param execution_context [Git::ExecutionContext] the execution context for running commands
        #
        def initialize(execution_context)
          @execution_context = execution_context
        end

        # Show stash numstat
        #
        # @overload call(**options)
        #
        #   Show numstat for the latest stash
        #
        #   @param options [Hash] command options
        #
        #   @option options [Boolean] :include_untracked (nil) include untracked files in diff.
        #     Alias: :u
        #
        #   @option options [Boolean] :only_untracked (nil) show only untracked files
        #
        #   @option options [Boolean, String] :dirstat (nil) include directory statistics.
        #     Pass true for default, or a string like 'lines,cumulative' for options.
        #
        # @overload call(stash, **options)
        #
        #   Show numstat for a specific stash
        #
        #   @param stash [String] stash reference (e.g., 'stash@\\{0}', '0')
        #
        #   @param options [Hash] command options
        #
        #   @option options [Boolean] :include_untracked (nil) include untracked files in diff.
        #     Alias: :u
        #
        #   @option options [Boolean] :only_untracked (nil) show only untracked files
        #
        #   @option options [Boolean, String] :dirstat (nil) include directory statistics.
        #     Pass true for default, or a string like 'lines,cumulative' for options.
        #
        # @return [Git::DiffResult] diff result with per-file and total statistics
        #
        def call(*, **)
          bound_args = ARGS.bind(*, **)
          output = @execution_context.command(*bound_args).stdout
          DiffParser::Numstat.parse(output, include_dirstat: !bound_args.dirstat.nil?)
        end
      end
    end
  end
end
