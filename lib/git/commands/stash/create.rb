# frozen_string_literal: true

require 'git/commands/base'

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
      # @see Git::Commands::Stash Git::Commands::Stash for usage examples
      #
      # @see https://git-scm.com/docs/git-stash git-stash documentation
      #
      # @api private
      #
      # @example Create a stash commit
      #   Git::Commands::Stash::Create.new(execution_context).call
      #
      # @example Create a stash commit with a message
      #   Git::Commands::Stash::Create.new(execution_context).call('WIP: my changes')
      #
      class Create < Git::Commands::Base
        arguments do
          literal 'stash'
          literal 'create'
          operand :message
        end

        # @!method call(*, **)
        #
        #   Create a stash commit
        #
        #   @overload call()
        #
        #     Create a stash commit without a message
        #
        #   @overload call(message)
        #
        #     Create a stash commit with a message
        #
        #     @param message [String] optional message for the stash commit
        #
        #   @return [Git::CommandLineResult] the result of calling `git stash create`
      end
    end
  end
end
