module Git
  class Author
    attr_accessor :name, :email, :date, :timezone
    
    def initialize(author_string)
      if m = /(.*?) <(.*?)> (\d+) ([-\+]\d+)/.match(author_string)
        @name = m[1]
        @email = m[2]
        @date = Time.at(m[3].to_i)
        @timezone = m[4].gsub(/([-\+]\d{2})(\d{2})/, '\1:\2')
      end
    end

    def local_date
      if Time.instance_method(:localtime).arity != 0
        return @date.localtime(@timezone)
      else # Time class in Ruby 1.8.7 does not have an method to change its timezone
        return @date
      end
    end

  end
end
