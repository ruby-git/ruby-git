# frozen_string_literal: true

module Git
  # Immutable value object representing an author or committer identity
  #
  # This is a lightweight, immutable data structure holding the identity data
  # git records for commit authors, committers, and taggers. It replaces the
  # mutable {Git::Author}, which is deprecated.
  #
  # @example Construct from individual values
  #   info = Git::AuthorInfo.new(
  #     name: 'John Doe',
  #     email: 'john.doe@example.com',
  #     date: Time.at(1627849923)
  #   )
  #   info.name  #=> 'John Doe'
  #
  # @example Parse from a raw git author string
  #   info = Git::AuthorInfo.parse('John Doe <john.doe@example.com> 1627849923 +0200')
  #   info.email     #=> 'john.doe@example.com'
  #   info.date.to_i #=> 1627849923
  #
  # @see Git::Object::Commit#author
  #
  # @see Git::Object::Commit#committer
  #
  # @api public
  #
  # @!attribute [r] name
  #   @return [String, nil] the person's name, or `nil` if not available
  #
  # @!attribute [r] email
  #   @return [String, nil] the person's email address, or `nil` if not available
  #
  # @!attribute [r] date
  #   @return [Time, nil] the timestamp of the change, or `nil` if not available
  #
  AuthorInfo = Data.define(:name, :email, :date) do
    # Parses a raw git identity string into a Git::AuthorInfo
    #
    # The expected format is `"Name <email> timestamp offset"` as emitted by
    # `git cat-file` for the `author`, `committer`, and `tagger` headers. The
    # timestamp is interpreted as seconds since the Unix epoch; the timezone
    # offset is not preserved in the resulting `date`.
    #
    # @example Parse a well-formed identity string
    #   Git::AuthorInfo.parse('John Doe <john.doe@example.com> 1627849923 +0200')
    #   #=> #<data Git::AuthorInfo name="John Doe", email="john.doe@example.com", ...>
    #
    # @example A string that does not match the expected format
    #   Git::AuthorInfo.parse('garbage')
    #   #=> #<data Git::AuthorInfo name=nil, email=nil, date=nil>
    #
    # @param author_string [String] the raw identity string to parse
    #
    # @return [Git::AuthorInfo] the parsed identity; all attributes are `nil`
    #   when the string does not match the expected format
    #
    def self.parse(author_string)
      match = /(.*?) <(.*?)> (\d+) (.*)/.match(author_string)
      return new(name: nil, email: nil, date: nil) unless match

      new(name: match[1], email: match[2], date: Time.at(match[3].to_i))
    end
  end
end
