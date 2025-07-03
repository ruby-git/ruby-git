# frozen_string_literal: true

module Git
  # The global configuration for this gem
  class Config
    attr_writer :binary_path, :git_ssh, :timeout

    def initialize
      @binary_path = nil
      @git_ssh = nil
      @timeout = nil
    end

    def binary_path
      @binary_path || (ENV.fetch('GIT_PATH', nil) && File.join(ENV.fetch('GIT_PATH', nil), 'git')) || 'git'
    end

    def git_ssh
      @git_ssh || ENV.fetch('GIT_SSH', nil)
    end

    def timeout
      @timeout || (ENV.fetch('GIT_TIMEOUT', nil) && ENV['GIT_TIMEOUT'].to_i)
    end
  end
end
