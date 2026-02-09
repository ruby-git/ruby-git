# frozen_string_literal: true

require 'git/commands/arguments'

module Git
  module Commands
    module Stash
      # Remove a stash entry from the stash list
      #
      # Removes a single stash entry from the list of stash entries.
      # If no stash reference is given, it removes the latest one.
      #
      # @see Git::Commands::Stash Git::Commands::Stash for usage examples
      #
      # @see https://git-scm.com/docs/git-stash git-stash documentation
      #
      # @api private
      #
      # @example Drop the latest stash
      #   Git::Commands::Stash::Drop.new(execution_context).call
      #
      # @example Drop a specific stash
      #   Git::Commands::Stash::Drop.new(execution_context).call('stash@\\{2}')
      #
      class Drop
        # Arguments DSL for building command-line arguments
        ARGS = Arguments.define do
          literal 'stash'
          literal 'drop'
          operand :stash
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
        # @overload call()
        #
        #   Drop the latest stash
        #
        # @overload call(stash)
        #
        #   Drop a specific stash
        #
        #   @param stash [String] stash reference (e.g., 'stash@\\{0}', '0')
        #
        # @return [Git::CommandLineResult] the result of calling `git stash drop`
        #
        # @raise [Git::FailedError] if the stash does not exist
        #
        def call(*, **)
          @execution_context.command(*ARGS.bind(*, **))
        end
      end
    end
  end
end
