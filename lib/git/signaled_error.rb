# frozen_string_literal: true

require 'git/git_execute_error'

module Git
  # This error is raised when a git command exits because of an uncaught signal
  #
  # The git command executed, status, stdout, and stderr are available from this
  # object. The #message includes the git command, the status of the process, and
  # the stderr of the process.
  #
  # @api public
  #
  class SignaledError < Git::GitExecuteError
    # Create a SignaledError object
    #
    # @example
    #   `kill -9 $$` # set $? appropriately for this example
    #   result = Git::CommandLineResult.new(%w[git status], $?, '', "killed")
    #   error = Git::SignaledError.new(result)
    #   error.message #=>
    #     "[\"git\", \"status\"]\nstatus: pid 88811 SIGKILL (signal 9)\nstderr: \"killed\""
    #
    # @param result [Git::CommandLineResult] the result of the git command including the git command, status, stdout, and stderr
    #
    def initialize(result)
      super("#{result.git_cmd}\nstatus: #{result.status}\nstderr: #{result.stderr.inspect}")
      @result = result
    end

    # @attribute [r] result
    #
    # The result of the git command including the git command, status, and output
    #
    # @example
    #   `kill -9 $$` # set $? appropriately for this example
    #   result = Git::CommandLineResult.new(%w[git status], $?, '', "killed")
    #   error = Git::SignaledError.new(result)
    #   error.result #=>
    #     #<Git::CommandLineResult:0x000000010470f6e8
    #       @git_cmd=["git", "status"],
    #       @status=#<Process::Status: pid 88811 SIGKILL (signal 9)>,
    #       @stderr="killed",
    #       @stdout="">
    #
    # @return [Git::CommandLineResult]
    #
    attr_reader :result
  end
end
