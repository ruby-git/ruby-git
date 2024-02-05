# frozen_string_literal: true

require_relative 'error'

module Git
  # Raised when a git command fails or exits because of an uncaught signal
  #
  # The git command executed, status, stdout, and stderr are available from this
  # object.
  #
  # Rather than creating a CommandLineError object directly, it is recommended to use
  # one of the derived classes for the appropriate type of error:
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
      super()
    end

    # The human readable representation of this error
    #
    # @example
    #   error.to_s #=> '["git", "status"], status: pid 89784 exit 1, stderr: "stderr"'
    #
    # @return [String]
    #
    def to_s = <<~MESSAGE.chomp
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
end
