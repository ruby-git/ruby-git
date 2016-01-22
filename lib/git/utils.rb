require 'uri'

module Git
  module Utils
    module_function

    def is_web_url?( url)
      return true if url =~ /\A#{URI::regexp(['http', 'https'])}\z/
    end

    def url_to_ssh( url )
      if is_web_url? url
        uri = URI( url )
        org,repo = uri.path[1..-1].split('/')
        "git@#{uri.host}:#{org}/#{repo}"
      else
        url
      end
    end
  end
end
