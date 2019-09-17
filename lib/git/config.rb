module Git

  class Config

    attr_writer :binary_path, :git_ssh, :git_ssl_no_verify

    def initialize
      @binary_path = nil
      @git_ssh = nil
      @git_ssl_no_verify = nil
    end

    def binary_path
      @binary_path || 'git'
    end

    def git_ssh
      @git_ssh || ENV['GIT_SSH']
    end

    def git_ssl_no_verify
      return 'true' if @git_ssl_no_verify
      ENV['GIT_SSL_NO_VERIFY']
    end

  end

end
