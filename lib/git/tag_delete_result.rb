# frozen_string_literal: true

require 'git/tag_info'
require 'git/tag_delete_failure'

module Git
  # Represents the result of a tag delete operation
  #
  # This is an immutable data object returned by {Git::Commands::Tag::Delete#call}.
  # It contains information about which tags were successfully deleted and which
  # failed to be deleted, along with the reason for each failure.
  #
  # Git's `git tag -d` command uses "best effort" semantics - it deletes as many
  # tags as possible and reports errors for those that couldn't be deleted. This
  # result object reflects that behavior, allowing callers to inspect both
  # successes and failures.
  #
  # @example Successful deletion of all tags
  #   result = tag_delete.call('v1.0.0', 'v2.0.0')
  #   result.success?            #=> true
  #   result.deleted.map(&:name) #=> ['v1.0.0', 'v2.0.0']
  #   result.not_deleted         #=> []
  #
  # @example Partial failure (some tags deleted, some not found)
  #   result = tag_delete.call('v1.0.0', 'nonexistent', 'v2.0.0')
  #   result.success?                    #=> false
  #   result.deleted.map(&:name)         #=> ['v1.0.0', 'v2.0.0']
  #   result.not_deleted.first.name          #=> 'nonexistent'
  #   result.not_deleted.first.error_message #=> "tag 'nonexistent' not found."
  #
  # @see Git::TagInfo
  # @see Git::TagDeleteFailure
  # @see Git::Commands::Tag::Delete
  #
  # @api public
  #
  # @!attribute [r] deleted
  #   Tags that were successfully deleted
  #   @return [Array<Git::TagInfo>]
  #
  # @!attribute [r] not_deleted
  #   Tags that could not be deleted, with the reason for each failure
  #   @return [Array<Git::TagDeleteFailure>]
  #
  TagDeleteResult = Data.define(:deleted, :not_deleted) do
    # Returns true if all requested tags were successfully deleted
    #
    # @return [Boolean] true if no tags failed to delete, false otherwise
    #
    # @example
    #   result = tag_delete.call('v1.0.0')
    #   if result.success?
    #     puts "All tags deleted successfully"
    #   else
    #     puts "Some tags could not be deleted:"
    #     result.not_deleted.each { |f| puts "  #{f.name}: #{f.error_message}" }
    #   end
    #
    def success?
      not_deleted.empty?
    end
  end
end
