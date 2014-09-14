module Git
  class Author
    attr_accessor :name, :email, :date
    
    def initialize(author_string)
      if m = /(.*?) <(.*?)> (\d+) ([-\+]\d+)/.match(author_string)
        @name = m[1]
        @email = m[2]
        @date = Time.at(m[3].to_i)
        @date.localtime(m[4].gsub(/([-\+]\d{2})(\d{2})/, '\1:\2'))
      end
    end
    
  end
end
