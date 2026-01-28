# frozen_string_literal: true

module Git
  # Represents a tag that failed to be deleted
  #
  # This is an immutable data object returned as part of {Git::TagDeleteResult}
  # when one or more tags could not be deleted.
  #
  # @example
  #   failure = Git::TagDeleteFailure.new(
  #     name: 'nonexistent',
  #     error_message: "tag 'nonexistent' not found."
  #   )
  #   failure.name          #=> 'nonexistent'
  #   failure.error_message #=> "tag 'nonexistent' not found."
  #
  # @see Git::TagDeleteResult
  # @see Git::Commands::Tag::Delete
  #
  # @api public
  #
  # @!attribute [r] name
  #   The name of the tag that failed to be deleted
  #   @return [String]
  #
  # @!attribute [r] error_message
  #   The error message from git explaining why the tag could not be deleted
  #   @return [String]
  #
  TagDeleteFailure = Data.define(:name, :error_message)
end
