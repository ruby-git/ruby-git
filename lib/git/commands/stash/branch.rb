# frozen_string_literal: true

require 'git/commands/base'

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
      class Branch < Base
        arguments do
          literal 'stash'
          literal 'branch'
          operand :branchname, required: true
          operand :stash
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
        def call(...) = super # rubocop:disable Lint/UselessMethodDefinition
      end
    end
  end
end
