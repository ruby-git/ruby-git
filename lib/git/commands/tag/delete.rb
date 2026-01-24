# frozen_string_literal: true

require 'git/commands/arguments'

module Git
  module Commands
    module Tag
      # Implements the `git tag -d` command for deleting tags
      #
      # This command deletes one or more tag references.
      #
      # @see https://git-scm.com/docs/git-tag git-tag
      #
      # @api private
      #
      # @example Delete a single tag
      #   delete = Git::Commands::Tag::Delete.new(execution_context)
      #   delete.call('v1.0.0')
      #
      # @example Delete multiple tags
      #   delete = Git::Commands::Tag::Delete.new(execution_context)
      #   delete.call('v1.0.0', 'v1.1.0', 'v2.0.0')
      #
      class Delete
        # Arguments DSL for building command-line arguments
        #
        # NOTE: Static flags are always output first regardless of definition order.
        #
        ARGS = Arguments.define do
          static '-d'
          positional :tag_names, variadic: true, required: true
        end.freeze

        # Initialize the Delete command
        #
        # @param execution_context [Git::ExecutionContext, Git::Lib] the context for executing git commands
        #
        def initialize(execution_context)
          @execution_context = execution_context
        end

        # Execute the git tag -d command to delete tags
        #
        # @overload call(*tag_names)
        #
        #   @param tag_names [Array<String>] One or more tag names to delete.
        #
        # @return [String] the command output
        #
        # @raise [ArgumentError] if no tag names are provided
        # @raise [Git::FailedError] if a tag does not exist
        #
        def call(*, **)
          args = ARGS.build(*, **)
          @execution_context.command('tag', *args)
        end
      end
    end
  end
end
