# frozen_string_literal: true

module Git
  # Base class for all custom git module errors
  #
  # The git gem will only raise an `ArgumentError` or an error that is a subclass of
  # `Git::Error`. It does not explicitly raise any other types of errors.
  #
  # It is recommended to rescue `Git::Error` to catch any runtime error raised by
  # this gem unless you need more specific error handling.
  #
  # Git's custom errors are arranged in the following class heirarchy:
  #
  # ```text
  # StandardError
  # └─> Git::Error
  #     ├─> Git::CommandLineError
  #     │   ├─> Git::FailedError
  #     │   └─> Git::SignaledError
  #     │       └─> Git::TimeoutError
  #     ├─> Git::ProcessIOError
  #     └─> Git::UnexpectedResultError
  # ```
  #
  # | Error Class | Description |
  # | --- | --- |
  # | `Error` | This catch-all error serves as the base class for other custom errors raised by the git gem. |
  # | `CommandLineError` | A subclass of this error is raised when there is a problem executing the git command line. |
  # | `FailedError` | This error is raised when the git command line exits with a non-zero status code that is not expected by the git gem. |
  # | `SignaledError` | This error is raised when the git command line is terminated as a result of receiving a signal. This could happen if the process is forcibly terminated or if there is a serious system error. |
  # | `TimeoutError` | This is a specific type of `SignaledError` that is raised when the git command line operation times out and is killed via the SIGKILL signal. This happens if the operation takes longer than the timeout duration configured in `Git.config.timeout` or via the `:timeout` parameter given in git methods that support timeouts. |
  # | `ProcessIOError` | An error was encountered reading or writing to a subprocess. |
  # | `UnexpectedResultError` | The command line ran without error but did not return the expected results. |
  #
  # @example Rescuing a generic error
  #   begin
  #     # some git operation
  #   rescue Git::Error => e
  #     puts "An error occurred: #{e.message}"
  #   end
  #
  # @example Rescuing a timeout error
  #   begin
  #     timeout_duration = 0.001 # seconds
  #     repo = Git.clone('https://github.com/ruby-git/ruby-git', 'ruby-git-temp', timeout: timeout_duration)
  #   rescue Git::TimeoutError => e # Catch the more specific error first!
  #     puts "Git clone took too long and timed out #{e}"
  #   rescue Git::Error => e
  #     puts "Received the following error: #{e}"
  #   end
  #
  # @see Git::CommandLineError
  # @see Git::FailedError
  # @see Git::SignaledError
  # @see Git::TimeoutError
  # @see Git::ProcessIOError
  # @see Git::UnexpectedResultError
  #
  # @api public
  #
  class Error < StandardError; end

  # An alias for Git::Error
  #
  # Git::GitExecuteError error class is an alias for Git::Error for backwards
  # compatibility. It is recommended to use Git::Error directly.
  #
  # @deprecated Use Git::Error instead
  #
  GitExecuteError = ActiveSupport::Deprecation::DeprecatedConstantProxy.new('Git::GitExecuteError', 'Git::Error', Git::Deprecation)

  # Raised when a git command fails or exits because of an uncaught signal
  #
  # The git command executed, status, stdout, and stderr are available from this
  # object.
  #
  # The Gem will raise a more specific error for each type of failure:
  #
  # * {Git::FailedError}: when the git command exits with a non-zero status
  # * {Git::SignaledError}: when the git command exits because of an uncaught signal
  # * {Git::TimeoutError}: when the git command times out
  #
  # @api public
  #
  class CommandLineError < Git::Error
    # Create a CommandLineError object
    #
    # @example
    #   `exit 1` # set $? appropriately for this example
    #   result = Git::CommandLineResult.new(%w[git status], $?, 'stdout', 'stderr')
    #   error = Git::CommandLineError.new(result)
    #   error.to_s #=> '["git", "status"], status: pid 89784 exit 1, stderr: "stderr"'
    #
    # @param result [Git::CommandLineResult] the result of the git command including
    #   the git command, status, stdout, and stderr
    #
    def initialize(result)
      @result = result
      super(error_message)
    end

    # The human readable representation of this error
    #
    # @example
    #   error.error_message #=> '["git", "status"], status: pid 89784 exit 1, stderr: "stderr"'
    #
    # @return [String]
    #
    def error_message = <<~MESSAGE.chomp
      #{result.git_cmd}, status: #{result.status}, stderr: #{result.stderr.inspect}
    MESSAGE

    # @attribute [r] result
    #
    # The result of the git command including the git command and its status and output
    #
    # @example
    #   error.result #=> #<Git::CommandLineResult:0x00000001046bd488 ...>
    #
    # @return [Git::CommandLineResult]
    #
    attr_reader :result
  end

  # This error is raised when a git command returns a non-zero exitstatus
  #
  # The git command executed, status, stdout, and stderr are available from this
  # object.
  #
  # @api public
  #
  class FailedError < Git::CommandLineError; end

  # This error is raised when a git command exits because of an uncaught signal
  #
  # @api public
  #
  class SignaledError < Git::CommandLineError; end

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
    #   error.error_message #=> '["sleep", "10"], status: pid 70144 SIGKILL (signal 9), stderr: "err output", timed out after 1s'
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
    #   error.error_message #=> '["sleep", "10"], status: pid 88811 SIGKILL (signal 9), stderr: "err output", timed out after 1s'
    #
    # @return [String]
    #
    def error_message = <<~MESSAGE.chomp
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

  # Raised when the output of a git command can not be read
  #
  # @api public
  #
  class ProcessIOError < Git::Error; end

  # Raised when the git command result was not as expected
  #
  # @api public
  #
  class UnexpectedResultError < Git::Error; end
end
