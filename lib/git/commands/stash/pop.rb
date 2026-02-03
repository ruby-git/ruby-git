# frozen_string_literal: true

require 'git/commands/arguments'
require 'git/commands/stash/list'

module Git
  module Commands
    module Stash
      # Apply stashed changes and remove from stash list
      #
      # Like {Apply}, but removes the stash from the stash list after
      # applying, unless there are conflicts.
      #
      # @see https://git-scm.com/docs/git-stash git-stash documentation
      # @api private
      #
      # @example Pop the latest stash
      #   Git::Commands::Stash::Pop.new(execution_context).call
      #
      # @example Pop a specific stash
      #   Git::Commands::Stash::Pop.new(execution_context).call('stash@\\{2}')
      #
      # @example Pop and restore index state
      #   Git::Commands::Stash::Pop.new(execution_context).call(index: true)
      #
      class Pop
        # Arguments DSL for building command-line arguments
        ARGS = Arguments.define do
          static 'stash'
          static 'pop'
          flag :index
          positional :stash
        end.freeze

        # Creates a new Pop command instance
        #
        # @param execution_context [Git::ExecutionContext] the execution context for running commands
        #
        def initialize(execution_context)
          @execution_context = execution_context
        end

        # Pop stashed changes
        #
        # @overload call(**options)
        #
        #   Pop the latest stash
        #
        #   @param options [Hash] command options
        #
        #   @option options [Boolean] :index (nil) restore the index state as well
        #
        # @overload call(stash, **options)
        #
        #   Pop a specific stash
        #
        #   @param stash [String] stash reference (e.g., 'stash@\\{0}', '0')
        #
        #   @param options [Hash] command options
        #
        #   @option options [Boolean] :index (nil) restore the index state as well
        #
        # @return [Git::StashInfo] the popped stash info
        #
        # @raise [Git::UnexpectedResultError] if the specified stash does not exist
        #
        def call(*, **)
          bound_args = ARGS.bind(*, **)

          # Capture stash info BEFORE popping (it will be removed)
          info = find_stash_info(bound_args.stash)

          @execution_context.command(*bound_args)

          info
        end

        private

        # Find StashInfo for a stash reference
        #
        # @param stash [String, Integer, nil] stash reference
        # @return [Git::StashInfo] the stash info
        #
        # @raise [Git::UnexpectedResultError] if no stashes exist or specified stash not found
        #
        def find_stash_info(stash)
          stashes = Git::Commands::Stash::List.new(@execution_context).call
          name = stash.nil? ? nil : normalize_stash_name(stash)
          result = name ? stashes.find { |s| s.name == name } : stashes.first
          result or raise Git::UnexpectedResultError, stash_not_found_message(name)
        end

        def stash_not_found_message(name)
          if name
            "Stash '#{name}' does not exist. Run `git stash list` to see available stashes."
          else
            'No stash entries found. Run `git stash` to create one.'
          end
        end

        # Normalize stash reference to canonical name format
        #
        # @param stash [String, Integer] stash reference
        # @return [String] canonical name (e.g., 'stash@\\{0}')
        #
        def normalize_stash_name(stash)
          name = stash.to_s
          name.start_with?('stash@{') ? name : "stash@{#{name}}"
        end
      end
    end
  end
end
