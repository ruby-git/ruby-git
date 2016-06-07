require 'uri'

module Git
  module Utils
    module_function

    def is_web_url?( url )
      begin
        ['http', 'https'].include? URI(url).scheme
      rescue URI::InvalidURIError
        false
      end
    end

    def url_to_ssh( url )
      return nil unless url =~ URI::Parser.new.make_regexp
      if is_web_url? url
        uri = URI( url )
        user = uri.user || 'git'
        path = uri.path[1..-1]
        url = "#{user}@#{uri.host}:#{path}"
      end
      url_ssh_parse( url )
    end

    def url_ssh_parse(uri_string)
      host_part, path_part = uri_string.split(':', 2)
      host, userinfo = host_part.split('@', 2).reverse
      URI::Git::Generic.build(userinfo: userinfo, host: host, path: path_part)
    end
  end
end
