# frozen_string_literal: true

require 'git/commands/arguments'
require 'git/commands/tag/list'
require 'git/tag_delete_result'
require 'git/tag_delete_failure'

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
          static 'tag'
          static '-d'
          positional :tag_names, variadic: true, required: true
        end.freeze

        # Regex to parse successful deletion lines from stdout
        # Matches: Deleted tag 'tagname' (was abc123)
        DELETED_TAG_REGEX = /^Deleted tag '([^']+)'/

        # Regex to parse error messages from stderr
        # Matches: error: tag 'tagname' not found.
        ERROR_TAG_REGEX = /^error: tag '([^']+)'(.*)$/

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
        def call(*tag_names, **)
          # Capture tag info BEFORE deletion for tags that exist
          existing_tags = lookup_existing_tags(tag_names)

          # Execute the delete command
          stdout, stderr = execute_delete(tag_names, **)

          # Parse results
          deleted_names = parse_deleted_tags(stdout)
          error_map = parse_error_messages(stderr)

          # Build result
          build_result(tag_names, existing_tags, deleted_names, error_map)
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
        # @param tag_names [Array<String>] tag names to delete
        # @return [Array<String, String>] [stdout, stderr]
        #
        def execute_delete(tag_names, **)
          args = ARGS.build(*tag_names, **)
          stdout = @execution_context.command(*args)
          [stdout, '']
        rescue Git::FailedError => e
          # Exit code 1 is expected when some tags don't exist; re-raise fatal errors
          raise if fatal_error?(e)

          [e.result.stdout, e.result.stderr]
        end

        # Check if this is a fatal error (not just "tag not found")
        #
        # Exit code 1 indicates some tags couldn't be deleted (e.g., not found).
        # This is git's standard behavior for partial failures in batch delete operations.
        # Other exit codes indicate fatal errors (e.g., not a git repository, invalid tag name).
        #
        # @param error [Git::FailedError] the error to check
        # @return [Boolean] true if this is a fatal error that should be re-raised
        #
        def fatal_error?(error)
          error.result.status.exitstatus != 1
        end

        # Parse deleted tag names from stdout
        #
        # @param stdout [String] command stdout
        # @return [Array<String>] names of successfully deleted tags
        #
        def parse_deleted_tags(stdout)
          stdout.scan(DELETED_TAG_REGEX).flatten
        end

        # Parse error messages from stderr into a map
        #
        # @param stderr [String] command stderr
        # @return [Hash<String, String>] map of tag name to error message
        #
        def parse_error_messages(stderr)
          stderr.each_line.with_object({}) do |line, hash|
            match = line.match(ERROR_TAG_REGEX)
            hash[match[1]] = line.strip if match
          end
        end

        # Build the TagDeleteResult from parsed data
        #
        # @param requested_names [Array<String>] originally requested tag names
        # @param existing_tags [Hash<String, Git::TagInfo>] tags that existed before delete
        # @param deleted_names [Array<String>] names confirmed deleted in stdout
        # @param error_map [Hash<String, String>] map of tag name to error message
        # @return [Git::TagDeleteResult] the result object
        #
        def build_result(requested_names, existing_tags, deleted_names, error_map)
          deleted = deleted_names.filter_map { |name| existing_tags[name] }

          not_deleted = (requested_names - deleted_names).map do |name|
            error_message = error_map[name] || "tag '#{name}' could not be deleted"
            Git::TagDeleteFailure.new(name: name, error_message: error_message)
          end

          Git::TagDeleteResult.new(deleted: deleted, not_deleted: not_deleted)
        end
      end
    end
  end
end
