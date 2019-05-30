# frozen_string_literal: true

module Git
  class Author
    attr_accessor :name, :email, :date

    def initialize(author_string)
      return unless (m = /(.*?) <(.*?)> (\d+) (.*)/.match(author_string))

      @name = m[1]
      @email = m[2]
      @date = Time.at(m[3].to_i)
    end
  end
end
