# frozen_string_literal: true

module Git
  # An author in a Git commit
  #
  class Author
    # @return [String, nil] the author's name
    attr_accessor :name

    # @return [String, nil] the author's email
    attr_accessor :email

    # @return [Time, nil] the date the change was authored (author date, not committer date)
    attr_accessor :date

    # Initializes a new Author object from a string
    #
    # @example
    #   Git::Author.new("John Doe <john.doe@example.com> 1627849923 +0200")
    #
    # @param author_string [String] the author string
    #
    # @return [void]
    #
    def initialize(author_string)
      return unless (m = /(.*?) <(.*?)> (\d+) (.*)/.match(author_string))

      @name = m[1]
      @email = m[2]
      @date = Time.at(m[3].to_i)
    end
  end
end
