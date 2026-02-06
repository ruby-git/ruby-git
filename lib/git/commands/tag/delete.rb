# frozen_string_literal: true

require 'git/commands/arguments'
require 'git/commands/tag/list'
require 'git/tag_delete_result'
require 'git/tag_delete_failure'
require 'git/parsers/tag'

module Git
  module Commands
    module Tag
      # Implements the `git tag -d` command for deleting tags
      #
      # This command deletes one or more tag references. It uses "best effort"
      # semantics - it deletes as many tags as possible and reports which tags
      # were deleted and which failed.
      #
      # @see https://git-scm.com/docs/git-tag git-tag
      #
      # @api private
      #
      # @example Delete a single tag
      #   delete = Git::Commands::Tag::Delete.new(execution_context)
      #   result = delete.call('v1.0.0')
      #   result.success?            #=> true
      #   result.deleted.first.name  #=> 'v1.0.0'
      #
      # @example Delete multiple tags with partial failure
      #   delete = Git::Commands::Tag::Delete.new(execution_context)
      #   result = delete.call('v1.0.0', 'nonexistent', 'v2.0.0')
      #   result.success?                    #=> false
      #   result.deleted.map(&:name)         #=> ['v1.0.0', 'v2.0.0']
      #   result.not_deleted.first.name      #=> 'nonexistent'
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
        # This method captures tag information before deletion and returns a
        # structured result showing which tags were deleted and which failed.
        # It does not raise an error for partial failures (when some tags don't
        # exist or can't be deleted), but will re-raise unexpected errors.
        #
        # @overload call(*tag_names)
        #
        #   @param tag_names [Array<String>] One or more tag names to delete.
        #
        # @return [Git::TagDeleteResult] result containing deleted tags and failures
        #
        # @raise [ArgumentError] if no tag names are provided
        # @raise [Git::FailedError] for unexpected errors (not partial deletion failures)
        #
        def call(*, **)
          bound_args = ARGS.bind(*, **)
          tag_names = bound_args.tag_names

          # Capture tag info BEFORE deletion for tags that exist
          existing_tags = lookup_existing_tags(tag_names)

          # Execute the delete command
          stdout, stderr = execute_delete(bound_args)

          # Parse results using TagParser
          deleted_names = Git::Parsers::Tag.parse_deleted_tags(stdout)
          error_map = Git::Parsers::Tag.parse_error_messages(stderr)

          # Build result
          Git::Parsers::Tag.build_delete_result(tag_names, existing_tags, deleted_names, error_map)
        end

        private

        # Look up TagInfo for tags that exist
        #
        # @param tag_names [Array<String>] tag names to look up
        # @return [Hash<String, Git::TagInfo>] map of tag name to TagInfo
        #
        def lookup_existing_tags(tag_names)
          existing_tags = Git::Commands::Tag::List.new(@execution_context).call(*tag_names)
          existing_tags.to_h { |tag| [tag.name, tag] }
        end

        # Execute git tag -d and capture output
        #
        # Exit code 1 indicates some tags couldn't be deleted (e.g., not found).
        # This is git's standard behavior for partial failures in batch delete operations.
        # Other exit codes indicate fatal errors (e.g., not a git repository).
        #
        # @param bound_args [Arguments::Bound] bound arguments
        # @return [Array<String, String>] [stdout, stderr]
        # @raise [Git::FailedError] for fatal errors (exit code > 1)
        #
        def execute_delete(bound_args)
          result = @execution_context.command(*bound_args, raise_on_failure: false)

          # Exit code > 1 indicates fatal error; exit 1 is partial failure (expected)
          raise Git::FailedError, result if result.status.exitstatus > 1

          [result.stdout, result.stderr]
        end
      end
    end
  end
end
