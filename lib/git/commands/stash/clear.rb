# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Stash
      # Remove all stash entries
      #
      # Removes all stash entries. Use with caution as this cannot be undone.
      #
      # @see Git::Commands::Stash Git::Commands::Stash for usage examples
      #
      # @see https://git-scm.com/docs/git-stash git-stash documentation
      #
      # @api private
      #
      # @example Clear all stashes
      #   Git::Commands::Stash::Clear.new(execution_context).call
      #
      class Clear < Base
        arguments do
          literal 'stash'
          literal 'clear'
        end

        # Clear all stash entries
        #
        # @return [Git::CommandLineResult] the result of calling `git stash clear`
        #
        def call(...) = super # rubocop:disable Lint/UselessMethodDefinition
      end
    end
  end
end
