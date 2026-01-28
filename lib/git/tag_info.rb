# frozen_string_literal: true

require 'git/author'

module Git
  # Value object representing tag metadata from git tag output
  #
  # This is a lightweight, immutable data structure returned by tag listing
  # commands. It contains only the data parsed from git output without any
  # repository context or operations.
  #
  # @example Annotated tag
  #   info = Git::TagInfo.new(
  #     name: 'v1.0.0',
  #     oid: 'abc123def456',        # tag object's ID
  #     target_oid: 'def456abc789', # commit it points to
  #     objecttype: 'tag',
  #     tagger_name: 'John Doe',
  #     tagger_email: '<john@example.com>',
  #     tagger_date: '2024-01-15T10:30:00-08:00',
  #     message: 'Release version 1.0.0'
  #   )
  #   info.annotated?   #=> true
  #   info.tagger.name  #=> 'John Doe'
  #
  # @example Lightweight tag
  #   info = Git::TagInfo.new(
  #     name: 'v1.0.0',
  #     oid: nil,                   # no tag object exists
  #     target_oid: 'def456abc789', # commit ID
  #     objecttype: 'commit',
  #     tagger_name: nil,
  #     tagger_email: nil,
  #     tagger_date: nil,
  #     message: nil
  #   )
  #   info.lightweight?  #=> true
  #   info.tagger        #=> nil
  #
  # @see Git::Tag for the full-featured tag object with operations
  # @see Git::Commands::Tag::List for the command that produces these
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
  # @!attribute [r] tagger_name
  #   @return [String, nil] the tagger's name, or nil for lightweight tags
  #
  # @!attribute [r] tagger_email
  #   @return [String, nil] the tagger's email, or nil for lightweight tags
  #
  # @!attribute [r] tagger_date
  #   @return [String, nil] the tag date in ISO 8601 format, or nil for lightweight tags
  #
  # @!attribute [r] message
  #   @return [String, nil] the tag message, or nil for lightweight tags
  #
  TagInfo = Data.define(:name, :oid, :target_oid, :objecttype, :tagger_name, :tagger_email, :tagger_date, :message) do
    # @return [Boolean] true if this is an annotated tag (oid is present)
    def annotated?
      !oid.nil?
    end

    # @return [Boolean] true if this is a lightweight tag (oid is nil)
    def lightweight?
      oid.nil?
    end

    # Return the tagger as an Author object
    #
    # @return [Git::Author, nil] the tagger as an Author object, or nil for lightweight tags
    def tagger
      return nil unless annotated? && tagger_name && tagger_email

      # Git::Author expects format "Name <email> timestamp timezone"
      # We construct a minimal format that will parse correctly
      author = Git::Author.new('')
      author.name = tagger_name
      # Remove angle brackets if present
      author.email = tagger_email.gsub(/\A<|>\z/, '')
      author
    end
  end
end
