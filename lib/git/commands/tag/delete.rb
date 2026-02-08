# frozen_string_literal: true

require 'git/commands/arguments'

module Git
  module Commands
    module Tag
      # Implements the `git tag -d` command for deleting tags
      #
      # This command deletes one or more tag references.
      #
      # @see Git::Commands::Tag
      #
      # @see https://git-scm.com/docs/git-tag git-tag
      #
      # @api private
      #
      # @example Delete a single tag
      #   delete = Git::Commands::Tag::Delete.new(execution_context)
      #   result = delete.call('v1.0.0')
      #   result.stdout  #=> "Deleted tag 'v1.0.0' (was abc123)\n"
      #
      # @example Delete multiple tags
      #   delete = Git::Commands::Tag::Delete.new(execution_context)
      #   result = delete.call('v1.0.0', 'v2.0.0')
      #
      class Delete
        # Arguments DSL for building command-line arguments
        ARGS = Arguments.define do
          literal 'tag'
          literal '--delete'
          operand :tag_names, repeatable: true, required: true
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
        # @return [Git::CommandLineResult] the result of calling `git tag --delete`
        #
        # @raise [ArgumentError] if no tag names are provided
        #
        # @raise [Git::FailedError] for fatal errors (exit code > 1)
        #
        def call(*, **)
          bound_args = ARGS.bind(*, **)

          @execution_context.command(*bound_args, raise_on_failure: false).tap do |result|
            raise Git::FailedError, result if result.status.exitstatus > 1
          end
        end
      end
    end
  end
end
