# frozen_string_literal: true

require 'git/commands/arguments'

module Git
  module Commands
    module Merge
      # Implements `git merge --quit` to quit an in-progress merge
      #
      # Forgets about the current merge in progress. Leaves the index and
      # working tree as-is. If an autostash entry is present, saves it to
      # the stash list.
      #
      # @see https://git-scm.com/docs/git-merge git-merge
      #
      # @api private
      #
      # @example Quit the merge, leaving working tree as-is
      #   quit_cmd = Git::Commands::Merge::Quit.new(execution_context)
      #   quit_cmd.call
      #
      class Quit
        # Arguments DSL for building command-line arguments
        ARGS = Arguments.define do
          static 'merge'
          static '--quit'
        end.freeze

        # Initialize the Merge::Quit command
        #
        # @param execution_context [Git::ExecutionContext, Git::Lib] the context for executing git commands
        #
        def initialize(execution_context)
          @execution_context = execution_context
        end

        # Execute the git merge --quit command
        #
        # @return [Git::CommandLineResult] the result of the command
        #
        # @raise [Git::FailedError] if the underlying git command exits non-zero
        #   (for example, on Git versions before 2.35 when no merge is in progress)
        #
        def call
          args = ARGS.build
          @execution_context.command(*args)
        end
      end
    end
  end
end
