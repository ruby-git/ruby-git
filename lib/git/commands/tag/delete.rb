# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Tag
      # Implements the `git tag --delete` command for deleting tags
      #
      # This command deletes one or more tag references.
      #
      # @example Delete a single tag
      #   delete = Git::Commands::Tag::Delete.new(execution_context)
      #   delete.call('v1.0.0')
      #
      # @example Delete multiple tags
      #   delete = Git::Commands::Tag::Delete.new(execution_context)
      #   delete.call('v1.0.0', 'v2.0.0')
      #
      # @note `arguments` block audited against https://git-scm.com/docs/git-tag/2.53.0
      #
      # @see Git::Commands::Tag
      #
      # @see https://git-scm.com/docs/git-tag git-tag
      #
      # @api private
      #
      class Delete < Git::Commands::Base
        arguments do
          literal 'tag'
          literal '--delete'
          operand :tagname, repeatable: true, required: true
        end

        # git tag --delete exits with status 1 when a tag does not exist, which is acceptable
        allow_exit_status 0..1

        # @!method call(*, **)
        #
        #   @overload call(*tagname)
        #
        #     Execute the `git tag --delete` command to delete one or more tags.
        #
        #     @param tagname [Array<String>] one or more tag names to delete
        #
        #     @return [Git::CommandLineResult] the result of calling `git tag --delete`
        #
        #     @raise [ArgumentError] if no tag names are provided or unsupported options are provided
        #
        #     @raise [Git::FailedError] if git exits outside the allowed range (exit code > 1)
        #
      end
    end
  end
end
