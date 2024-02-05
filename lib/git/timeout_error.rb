# frozen_string_literal: true

require_relative 'signaled_error'

module Git
  # This error is raised when a git command takes longer than the configured timeout
  #
  # The git command executed, status, stdout, and stderr, and the timeout duration
  # are available from this object.
  #
  # result.status.timeout? will be `true`
  #
  # @api public
  #
  class TimeoutError < Git::SignaledError
    # Create a TimeoutError object
    #
    # @example
    #   command = %w[sleep 10]
    #   timeout_duration = 1
    #   status = ProcessExecuter.spawn(*command, timeout: timeout_duration)
    #   result = Git::CommandLineResult.new(command, status, 'stdout', 'err output')
    #   error = Git::TimeoutError.new(result, timeout_duration)
    #   error.to_s #=> '["sleep", "10"], status: pid 70144 SIGKILL (signal 9), stderr: "err output", timed out after 1s'
    #
    # @param result [Git::CommandLineResult] the result of the git command including
    #   the git command, status, stdout, and stderr
    #
    # @param timeout_duration [Numeric] the amount of time the subprocess was allowed
    #   to run before being killed
    #
    def initialize(result, timeout_duration)
      @timeout_duration = timeout_duration
      super(result)
    end

    # The human readable representation of this error
    #
    # @example
    #   error.to_s #=> '["sleep", "10"], status: pid 88811 SIGKILL (signal 9), stderr: "err output", timed out after 1s'
    #
    # @return [String]
    #
    def to_s = <<~MESSAGE.chomp
      #{super}, timed out after #{timeout_duration}s
    MESSAGE

    # The amount of time the subprocess was allowed to run before being killed
    #
    # @example
    #   `kill -9 $$` # set $? appropriately for this example
    #   result = Git::CommandLineResult.new(%w[git status], $?, '', "killed")
    #   error = Git::TimeoutError.new(result, 10)
    #   error.timeout_duration #=> 10
    #
    # @return [Numeric]
    #
    attr_reader :timeout_duration
  end
end
