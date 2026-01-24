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
  #     sha: 'abc123def456',
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
  #     sha: 'abc123def456',
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
  TagInfo = Data.define(:name, :sha, :objecttype, :tagger_name, :tagger_email, :tagger_date, :message) do
    # @return [Boolean] true if this is an annotated tag (objecttype is 'tag')
    def annotated?
      objecttype == 'tag'
    end

    # @return [Boolean] true if this is a lightweight tag (objecttype is 'commit')
    def lightweight?
      objecttype == 'commit'
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
