# frozen_string_literal: true

require 'git/commands/arguments'
require 'git/parsers/stash'

module Git
  module Commands
    module Stash
      # List all stash entries
      #
      # @see Git::Commands::Stash Git::Commands::Stash for usage examples
      #
      # @see https://git-scm.com/docs/git-stash git-stash documentation
      #
      # @api private
      #
      # @example List all stashes
      #   Git::Commands::Stash::List.new(execution_context).call
      #
      class List
        # Arguments DSL for building command-line arguments
        ARGS = Arguments.define do
          literal 'stash'
          literal 'list'
          literal "--format=#{Git::Parsers::Stash::STASH_FORMAT}"
        end.freeze

        # Creates a new List command instance
        #
        # @param execution_context [Git::ExecutionContext] the execution context for running commands
        #
        def initialize(execution_context)
          @execution_context = execution_context
        end

        # List all stash entries
        #
        # @overload call()
        #
        # @return [Git::CommandLineResult] the result of calling `git stash list`
        #
        def call
          @execution_context.command(*ARGS.bind)
        end
      end
    end
  end
end
