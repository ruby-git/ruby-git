# frozen_string_literal: true

require 'git/commands/arguments'
require 'git/commands/stash/list'

module Git
  module Commands
    module Stash
      # Remove a stash entry from the stash list
      #
      # Removes a single stash entry from the list of stash entries.
      # If no stash reference is given, it removes the latest one.
      #
      # @see https://git-scm.com/docs/git-stash git-stash documentation
      # @api private
      #
      # @example Drop the latest stash
      #   Git::Commands::Stash::Drop.new(execution_context).call
      #
      # @example Drop a specific stash
      #   Git::Commands::Stash::Drop.new(execution_context).call('stash@{2}')
      #
      class Drop
        # Arguments DSL for building command-line arguments
        ARGS = Arguments.define do
          positional :stash
        end.freeze

        # Creates a new Drop command instance
        #
        # @param execution_context [Git::ExecutionContext] the execution context for running commands
        #
        def initialize(execution_context)
          @execution_context = execution_context
        end

        # Drop a stash entry
        #
        # @overload call(**options)
        #
        #   Drop the latest stash
        #
        # @overload call(stash, **options)
        #
        #   Drop a specific stash
        #
        #   @param stash [String] stash reference (e.g., 'stash@\\{0}', '0')
        #
        # @return [Git::StashInfo] the dropped stash info
        #
        # @raise [Git::UnexpectedResultError] if the specified stash does not exist
        #
        def call(stash = nil, **)
          # Capture stash info BEFORE dropping (it will be removed)
          info = find_stash_info(stash)

          args = ARGS.build(stash, **)
          @execution_context.command('stash', 'drop', *args)

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
        # @return [String] canonical name (e.g., 'stash@{0}')
        #
        def normalize_stash_name(stash)
          name = stash.to_s
          name.start_with?('stash@{') ? name : "stash@{#{name}}"
        end
      end
    end
  end
end
