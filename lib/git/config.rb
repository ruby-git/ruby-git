module Git

  class Config

    attr_writer :binary_path, :git_ssh, :timeout

    def initialize
      @binary_path = nil
      @git_ssh = nil
      @timeout = nil
    end

    def binary_path
      @binary_path || ENV['GIT_PATH'] && File.join(ENV['GIT_PATH'], 'git') || 'git'
    end

    def git_ssh
      @git_ssh || ENV['GIT_SSH']
    end

    def timeout
      @timeout || (ENV['GIT_TIMEOUT'] && ENV['GIT_TIMEOUT'].to_i)
    end
  end

end
