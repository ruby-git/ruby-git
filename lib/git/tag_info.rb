# frozen_string_literal: true

require 'time'

require 'git/author_info'

module Git
  # Value object representing tag metadata from git tag output
  #
  # This is a lightweight, immutable data structure returned by tag listing
  # commands. It contains only the data parsed from git output without any
  # repository context or operations.
  #
  # The tagger identity is a nested {Git::AuthorInfo}. Its `date` is a `Time`
  # parsed from git's strict ISO 8601 output, not an ISO 8601 string.
  #
  # @example Annotated tag
  #   info = Git::TagInfo.new(
  #     name: 'v1.0.0',
  #     oid: 'abc123def456',        # tag object's ID
  #     target_oid: 'def456abc789', # commit it points to
  #     objecttype: 'tag',
  #     tagger: Git::AuthorInfo.new(
  #       name: 'John Doe',
  #       email: 'john@example.com',
  #       date: Time.iso8601('2024-01-15T10:30:00-08:00')
  #     ),
  #     message: 'Release version 1.0.0'
  #   )
  #   info.annotated?   #=> true
  #   info.tagger.name  #=> 'John Doe'
  #   info.tagger.date  #=> 2024-01-15 10:30:00 -0800
  #
  # @example Lightweight tag
  #   info = Git::TagInfo.new(
  #     name: 'v1.0.0',
  #     oid: nil,                   # no tag object exists
  #     target_oid: 'def456abc789', # commit ID
  #     objecttype: 'commit',
  #     tagger: nil,
  #     message: nil
  #   )
  #   info.lightweight?  #=> true
  #   info.tagger        #=> nil
  #
  # @see Git::Repository::ObjectOperations#tag_list for the repository method
  #   that returns these
  #
  # @see Git::Commands::Tag::List for the command that produces these
  #
  # @see Git::AuthorInfo for the nested tagger identity
  #
  # @api public
  #
  # @!attribute [r] name
  #   @return [String] the tag name (e.g., 'v1.0.0')
  #
  # @!attribute [r] oid
  #   The object ID of the tag object itself.
  #
  #   For annotated tags, this is the tag object's ID. For lightweight tags,
  #   this is nil because lightweight tags are not objects in the git database.
  #
  #   @return [String, nil] the tag object's ID, or nil for lightweight tags
  #
  # @!attribute [r] target_oid
  #   The object ID of the commit this tag ultimately points to.
  #
  #   For both annotated and lightweight tags, this is the commit ID that the
  #   tag resolves to (i.e., the dereferenced target).
  #
  #   @return [String] the commit ID this tag points to
  #
  # @!attribute [r] objecttype
  #   @return [String] 'tag' for annotated tags, 'commit' for lightweight tags
  #
  # @!attribute [r] tagger
  #   The identity of the person who created the tag object.
  #
  #   Lightweight tags have no tag object and therefore no tagger. The nested
  #   `email` has no angle brackets and the nested `date` is a `Time`.
  #
  #   @return [Git::AuthorInfo, nil] the tagger, or nil for lightweight tags
  #
  # @!attribute [r] message
  #   @return [String, nil] the tag message, or nil for lightweight tags
  #
  TagInfo = Data.define(:name, :oid, :target_oid, :objecttype, :tagger, :message) do
    # @return [Boolean] true if this is an annotated tag (oid is present)
    def annotated?
      !oid.nil?
    end

    # @return [Boolean] true if this is a lightweight tag (oid is nil)
    def lightweight?
      oid.nil?
    end
  end
end
