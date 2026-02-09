# frozen_string_literal: true

require 'git/commands/arguments'

module Git
  module Commands
    module Stash
      # Apply stashed changes and remove from stash list
      #
      # Like {Apply}, but removes the stash from the stash list after
      # applying, unless there are conflicts.
      #
      # @see Git::Commands::Stash Git::Commands::Stash for usage examples
      #
      # @see https://git-scm.com/docs/git-stash git-stash documentation
      #
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
          literal 'stash'
          literal 'pop'
          flag_option :index
          operand :stash
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
        # @return [Git::CommandLineResult] the result of calling `git stash pop`
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
