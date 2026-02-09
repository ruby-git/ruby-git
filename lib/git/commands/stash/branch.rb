# frozen_string_literal: true

require 'git/commands/arguments'

module Git
  module Commands
    module Stash
      # Create a branch from a stash entry
      #
      # Creates a new branch starting from the commit at which the stash was
      # originally created, applies the stashed changes, and then drops the stash
      # if the changes are applied successfully.
      #
      # This is useful if the branch on which you ran `git stash push` has changed
      # enough that `git stash apply` fails due to conflicts. The new branch will
      # be created at the commit that was HEAD when the stash was created, so
      # applying the stash should succeed.
      #
      # @see Git::Commands::Stash Git::Commands::Stash for usage examples
      #
      # @see https://git-scm.com/docs/git-stash git-stash documentation
      #
      # @api private
      #
      # @example Create branch from latest stash
      #   Git::Commands::Stash::Branch.new(execution_context).call('my-branch')
      #
      # @example Create branch from specific stash
      #   Git::Commands::Stash::Branch.new(execution_context).call('my-branch', 'stash@{2}')
      #
      class Branch
        # Arguments DSL for building command-line arguments
        ARGS = Arguments.define do
          literal 'stash'
          literal 'branch'
          operand :branchname, required: true
          operand :stash
        end.freeze

        # Creates a new Branch command instance
        #
        # @param execution_context [Git::ExecutionContext] the execution context for running commands
        #
        def initialize(execution_context)
          @execution_context = execution_context
        end

        # Create a branch from a stash entry
        #
        # @overload call(branchname)
        #
        #   Create a branch from the latest stash
        #
        #   @param branchname [String] the name of the branch to create (required)
        #
        # @overload call(branchname, stash)
        #
        #   Create a branch from a specific stash
        #
        #   @param branchname [String] the name of the branch to create (required)
        #
        #   @param stash [String] stash reference (e.g., 'stash@\\{0}', '0')
        #
        # @return [Git::CommandLineResult] the result of calling `git stash branch`
        #
        # @raise [Git::FailedError] if the branch already exists or stash doesn't exist
        #
        def call(*, **)
          @execution_context.command(*ARGS.bind(*, **))
        end
      end
    end
  end
end
