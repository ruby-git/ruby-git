# frozen_string_literal: true

require 'addressable/uri'

module Git
  # Methods for parsing a Git URL
  #
  # Any URL that can be passed to `git clone` can be parsed by this class.
  #
  # @see https://git-scm.com/docs/git-clone#_git_urls GIT URLs
  # @see https://github.com/sporkmonger/addressable Addresable::URI
  #
  # @api public
  #
  class URL
    # Regexp used to match a Git URL with an alternative SSH syntax
    # such as `user@host:path`
    #
    GIT_ALTERNATIVE_SSH_SYNTAX = %r{
      ^
      (?:(?<user>[^@/]+)@)?  # user or nil
      (?<host>[^:/]+)        # host is required
      :(?!/)                 # : serparator is required, but must not be followed by /
      (?<path>.*?)           # path is required
      $
    }x.freeze

    # Parse a Git URL and return an Addressable::URI object
    #
    # The URI returned can be converted back to a string with 'to_s'. This is
    # guaranteed to return the same URL string that was parsed.
    #
    # @example
    #   uri = Git::URL.parse('https://github.com/ruby-git/ruby-git.git')
    #     #=> #<Addressable::URI:0x44c URI:https://github.com/ruby-git/ruby-git.git>
    #   uri.scheme #=> "https"
    #   uri.host #=> "github.com"
    #   uri.path #=> "/ruby-git/ruby-git.git"
    #
    #   Git::URL.parse('/Users/James/projects/ruby-git')
    #     #=> #<Addressable::URI:0x438 URI:/Users/James/projects/ruby-git>
    #
    # @param url [String] the Git URL to parse
    #
    # @return [Addressable::URI] the parsed URI
    #
    def self.parse(url)
      if !url.start_with?('file:') && (m = GIT_ALTERNATIVE_SSH_SYNTAX.match(url))
        GitAltURI.new(user: m[:user], host: m[:host], path: m[:path])
      else
        Addressable::URI.parse(url)
      end
    end

    # The directory `git clone` would use for the repository directory for the given URL
    #
    # @example
    #   Git::URL.clone_to('https://github.com/ruby-git/ruby-git.git') #=> 'ruby-git'
    #
    # @param url [String] the Git URL containing the repository directory
    #
    # @return [String] the name of the repository directory
    #
    def self.clone_to(url, bare: false, mirror: false)
      uri = parse(url)
      path_parts = uri.path.split('/')
      path_parts.pop if path_parts.last == '.git'
      directory = path_parts.last
      if bare || mirror
        directory += '.git' unless directory.end_with?('.git')
      elsif directory.end_with?('.git')
        directory = directory[0..-5]
      end
      directory
    end
  end

  # The URI for git's alternative scp-like syntax
  #
  # This class is necessary to ensure that #to_s returns the same string
  # that was passed to the initializer.
  #
  # @api public
  #
  class GitAltURI < Addressable::URI
    # Create a new GitAltURI object
    #
    # @example
    #   uri = Git::GitAltURI.new(user: 'james', host: 'github.com', path: 'james/ruby-git')
    #   uri.to_s #=> 'james@github.com/james/ruby-git'
    #
    # @param user [String, nil] the user from the URL or nil
    # @param host [String] the host from the URL
    # @param path [String] the path from the URL
    #
    def initialize(user:, host:, path:)
      super(scheme: 'git-alt', user: user, host: host, path: path)
    end

    # Convert the URI to a String
    #
    # Addressible::URI forces path to be absolute by prepending a '/' to the
    # path. This method removes the '/' when converting back to a string
    # since that is what is expected by git. The following is a valid git URL:
    #
    #  `james@github.com:ruby-git/ruby-git.git`
    #
    # and the following (with the initial '/'' in the path) is NOT a valid git URL:
    #
    #  `james@github.com:/ruby-git/ruby-git.git`
    #
    # @example
    #   uri = Git::GitAltURI.new(user: 'james', host: 'github.com', path: 'james/ruby-git')
    #   uri.path #=> '/james/ruby-git'
    #   uri.to_s #=> 'james@github.com:james/ruby-git'
    #
    # @return [String] the URI as a String
    #
    def to_s
      if user
        "#{user}@#{host}:#{path[1..-1]}"
      else
        "#{host}:#{path[1..-1]}"
      end
    end
  end
end
