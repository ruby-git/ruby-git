module Git

  class Config

    attr_writer :binary_path, :git_ssh

    def initialize
      @binary_path = nil
      @git_ssh = nil
    end

    def binary_path
      @binary_path || 'git'
    end

    def git_ssh
      @git_ssh || ENV['GIT_SSH']
    end

  end

end
