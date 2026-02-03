# frozen_string_literal: true

require 'git/commands/arguments'

module Git
  module Commands
    module Merge
      # Implements `git merge --abort` to abort an in-progress merge
      #
      # Aborts the current merge and reconstructs the pre-merge state.
      # If an autostash entry is present, applies it to the worktree.
      #
      # @see https://git-scm.com/docs/git-merge git-merge
      #
      # @api private
      #
      # @example Abort a merge
      #   abort_cmd = Git::Commands::Merge::Abort.new(execution_context)
      #   abort_cmd.call
      #
      class Abort
        # Arguments DSL for building command-line arguments
        ARGS = Arguments.define do
          static 'merge'
          static '--abort'
        end.freeze

        # Initialize the Merge::Abort command
        #
        # @param execution_context [Git::ExecutionContext, Git::Lib] the context for executing git commands
        #
        def initialize(execution_context)
          @execution_context = execution_context
        end

        # Execute the git merge --abort command
        #
        # @return [Git::CommandLineResult] the result of the command
        #
        # @raise [Git::FailedError] if no merge is in progress
        #
        def call
          args = ARGS.bind
          @execution_context.command(*args)
        end
      end
    end
  end
end
