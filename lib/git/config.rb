# frozen_string_literal: true

module Git
  # The global configuration for this gem
  class Config
    # Returns the process-wide singleton {Git::Config} instance
    #
    # All calls to {Git.configure}, {Git.config}, and the {Git::ExecutionContext}
    # classes resolve global configuration through this method. Owning the
    # singleton here (rather than on {Git::Base}) means these call sites are
    # independent of `Git::Base` and will continue to work when `Git::Base` is
    # removed in a future version.
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
