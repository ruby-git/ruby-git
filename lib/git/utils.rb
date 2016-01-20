require 'uri'

module Git
  class Utils
    def self.url_to_ssh( url )
      uri = URI( url )
      "git@#{uri.host}:#{uri.path[1..-1]}"
    end
  end
end
