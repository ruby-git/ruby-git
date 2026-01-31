# frozen_string_literal: true

require 'git/commands/arguments'

module Git
  module Commands
    module Stash
      # Create a stash commit without storing it in refs/stash
      #
      # This is a plumbing command used to create a stash commit object without
      # actually storing it in the stash reflog. It's useful for scripts that
      # need to create stash commits programmatically.
      #
      # The command creates a stash commit and outputs its SHA, but does not
      # update refs/stash. Use {Store} to store the commit in the stash reflog.
      #
      # @see https://git-scm.com/docs/git-stash git-stash documentation
      # @api private
      #
      # @example Create a stash commit
      #   sha = Git::Commands::Stash::Create.new(execution_context).call
      #   # => "abc123def456..."
      #
      # @example Create a stash commit with a message
      #   sha = Git::Commands::Stash::Create.new(execution_context).call('WIP: my changes')
      #
      class Create
        # Arguments DSL for building command-line arguments
        ARGS = Arguments.define do
          static 'stash'
          static 'create'
          positional :message
        end.freeze

        # Creates a new Create command instance
        #
        # @param execution_context [Git::ExecutionContext] the execution context for running commands
        #
        def initialize(execution_context)
          @execution_context = execution_context
        end

        # Create a stash commit
        #
        # @overload call()
        #
        #   Create a stash commit without a message
        #
        # @overload call(message)
        #
        #   Create a stash commit with a message
        #
        #   @param message [String] optional message for the stash commit
        #
        # @return [String, nil] the SHA of the created stash commit, or nil if
        #   there were no local changes to stash
        #
        def call(message = nil)
          result = @execution_context.command(*ARGS.build(message))

          # Returns empty output if there were no local changes
          sha = result.stdout.strip
          sha.empty? ? nil : sha
        end
      end
    end
  end
end
