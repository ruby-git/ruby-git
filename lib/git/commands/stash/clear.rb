# frozen_string_literal: true

module Git
  module Commands
    module Stash
      # Remove all stash entries
      #
      # Removes all stash entries. Use with caution as this cannot be undone.
      #
      # @see https://git-scm.com/docs/git-stash git-stash documentation
      # @api private
      #
      # @example Clear all stashes
      #   Git::Commands::Stash::Clear.new(execution_context).call
      #
      class Clear
        # Creates a new Clear command instance
        #
        # @param execution_context [Git::ExecutionContext] the execution context for running commands
        #
        def initialize(execution_context)
          @execution_context = execution_context
        end

        # Clear all stash entries
        #
        # @return [String] the command output (empty on success)
        #
        def call
          @execution_context.command('stash', 'clear')
        end
      end
    end
  end
end
