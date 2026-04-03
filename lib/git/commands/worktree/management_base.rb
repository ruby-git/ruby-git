# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Worktree
      # Shared base class for worktree management subcommands
      #
      # Overrides the `env` method from {Git::Commands::Base} to unconditionally
      # unset `GIT_INDEX_FILE` in the subprocess environment. Git worktrees
      # maintain their own index files; passing a `GIT_INDEX_FILE` override when
      # running management commands causes silent corruption of both the main
      # worktree and linked worktree indexes.
      #
      # All worktree management subcommands ({Add}, {Lock}, {Move}, {Prune},
      # {Remove}, {Repair}, {Unlock}) inherit from this class. The read-only
      # {List} subcommand uses {Git::Commands::Base} directly.
      #
      # @example Defining a new worktree management subcommand
      #   class Archive < Git::Commands::Worktree::ManagementBase
      #     arguments do
      #       literal 'worktree'
      #       literal 'archive'
      #       operand :path, required: true
      #     end
      #   end
      #
      # @see Git::Commands::Base
      #
      # @see Git::Commands::Worktree
      #
      # @api private
      #
      class ManagementBase < Git::Commands::Base
        private

        # Returns environment variable overrides that unset `GIT_INDEX_FILE`
        #
        # @return [Hash] the environment variable overrides, always
        #   `{ 'GIT_INDEX_FILE' => nil }`
        #
        def env
          { 'GIT_INDEX_FILE' => nil }
        end
      end
    end
  end
end
