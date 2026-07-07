# frozen_string_literal: true

module Git
  # The global configuration for this gem
  class Config
    # Returns the process-wide singleton {Git::Config} instance
    #
    # All calls to {Git.configure}, {Git.config}, and the {Git::ExecutionContext}
    # classes resolve global configuration through this method.
    #
    # @example Read the configured binary path
    #   Git::Config.instance.binary_path  #=> "git"
    #
    # @example Mutate the singleton (same as Git.configure { |c| ... })
    #   Git::Config.instance.binary_path = '/usr/local/bin/git'
    #
    # @return [Git::Config] the singleton config object
    #
    def self.instance
      @instance ||= new
    end

    # Sets the configuration options for the git executable, SSH, and timeout
    #
    # @return [String] the configured value
    #
    attr_writer :binary_path

    # Sets the SSH command to use for git operations
    #
    # @return [String] the configured SSH command
    #
    attr_writer :git_ssh

    # Sets the timeout for git operations
    #
    # @return [Integer] the configured timeout in seconds
    #
    attr_writer :timeout

    def initialize
      @binary_path = nil
      @git_ssh = nil
      @timeout = nil
    end

    # Returns the git executable path
    #
    # Uses an explicitly configured path first, then `GIT_PATH`, then `git`.
    #
    # @example Read the default executable
    #   Git::Config.instance.binary_path #=> "git"
    #
    # @return [String] the git executable path
    #
    def binary_path
      @binary_path || (ENV.fetch('GIT_PATH', nil) && File.join(ENV.fetch('GIT_PATH', nil), 'git')) || 'git'
    end

    # Returns the SSH wrapper path used by git operations
    #
    # Uses an explicitly configured wrapper path first, then `GIT_SSH`.
    #
    # @example Read the configured SSH wrapper path
    #   Git::Config.instance.git_ssh #=> "/usr/bin/ssh-wrapper"
    #
    # @return [String, nil] the configured SSH wrapper path
    #
    def git_ssh
      @git_ssh || ENV.fetch('GIT_SSH', nil)
    end

    # Returns the timeout for git operations
    #
    # Uses an explicitly configured timeout first, then `GIT_TIMEOUT`.
    #
    # @example Read the configured timeout
    #   Git::Config.instance.timeout #=> 30
    #
    # @return [Integer, nil] the timeout in seconds
    #
    def timeout
      @timeout || (ENV.fetch('GIT_TIMEOUT', nil) && ENV['GIT_TIMEOUT'].to_i)
    end
  end
end
