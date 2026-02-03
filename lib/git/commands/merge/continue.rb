# frozen_string_literal: true

require 'git/commands/arguments'

module Git
  module Commands
    module Merge
      # Implements `git merge --continue` to complete a merge after conflict resolution
      #
      # Completes the merge after conflicts have been resolved and staged.
      # The editor is suppressed via GIT_EDITOR=true set in the execution environment.
      #
      # @see https://git-scm.com/docs/git-merge git-merge
      #
      # @api private
      #
      # @example Continue after resolving conflicts
      #   continue_cmd = Git::Commands::Merge::Continue.new(execution_context)
      #   continue_cmd.call
      #
      class Continue
        # Arguments DSL for building command-line arguments
        ARGS = Arguments.define do
          static 'merge'
          static '--continue'
        end.freeze

        # Initialize the Merge::Continue command
        #
        # @param execution_context [Git::ExecutionContext, Git::Lib] the context for executing git commands
        #
        def initialize(execution_context)
          @execution_context = execution_context
        end

        # Execute the git merge --continue command
        #
        # @return [Git::CommandLineResult] the result of the command
        #
        # @raise [Git::FailedError] if no merge is in progress or conflicts remain unresolved
        #
        def call
          args = ARGS.bind
          @execution_context.command(*args)
        end
      end
    end
  end
end
