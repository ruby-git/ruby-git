# frozen_string_literal: true

require 'git/commands/base'

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
      class Delete < Base
        arguments do
          literal 'tag'
          literal '--delete'
          operand :tagname, repeatable: true, required: true
        end

        # git tag --delete exits with status 1 when a tag does not exist, which is acceptable
        allow_exit_status 0..1

        # Execute the git tag -d command to delete tags
        #
        # @overload call(*tagname)
        #
        #   @param tagname [Array<String>] One or more tag names to delete.
        #
        # @return [Git::CommandLineResult] the result of calling `git tag --delete`
        #
        # @raise [ArgumentError] if no tag names are provided
        #
        # @raise [Git::FailedError] for fatal errors (exit code > 1)
        #
        def call(...) = super # rubocop:disable Lint/UselessMethodDefinition
      end
    end
  end
end
