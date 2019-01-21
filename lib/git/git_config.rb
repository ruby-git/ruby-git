module Git
  module GitConfig
    extend self

    #g.config('user.name', 'Scott Chacon') # sets value
    #g.config('user.email', 'email@email.com')  # sets value
    #g.config('user.name')  # returns 'Scott Chacon'
    #g.config # returns whole config hash
    def config(name = nil, value = nil)
      if(name && value)
        # set value
        lib.config_set(name, value)
      elsif (name)
        # return value
        lib.config_get(name)
      else
        # return hash
        lib.config_list
      end
    end

    def global_config(name = nil, value = nil)
      Git.global_config(name, value)
    end

    class << self
      private

      def lib
        @lib ||= Git::Lib.new
      end
    end
  end
end

# Git::GitConfig.config