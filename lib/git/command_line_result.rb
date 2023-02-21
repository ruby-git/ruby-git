# frozen_string_literal: true

module Git
  # The result of running a git command
  #
  # This object stores the Git command executed and its status, stdout, and stderr.
  #
  # @api public
  #
  class CommandLineResult
    # Create a CommandLineResult object
    #
    # @example
    #   `true`
    #   git_cmd = %w[git version]
    #   status = $?
    #   stdout = "git version 2.39.1\n"
    #   stderr = ""
    #   result = Git::CommandLineResult.new(git_cmd, status, stdout, stderr)
    #
    # @param git_cmd [Array<String>] the git command that was executed
    # @param status [Process::Status] the status of the process
    # @param stdout [String] the output of the process
    # @param stderr [String] the error output of the process
    #
    def initialize(git_cmd, status, stdout, stderr)
      @git_cmd = git_cmd
      @status = status
      @stdout = stdout
      @stderr = stderr
    end

    # @attribute [r] git_cmd
    #
    # The git command that was executed
    #
    # @example
    #  git_cmd = %w[git version]
    #  result = Git::CommandLineResult.new(git_cmd, $?, "", "")
    #  result.git_cmd #=> ["git", "version"]
    #
    # @return [Array<String>]
    #
    attr_reader :git_cmd

    # @attribute [r] status
    #
    # The status of the process
    #
    # @example
    #   `true`
    #   status = $?
    #   result = Git::CommandLineResult.new(status, "", "")
    #   result.status #=> #<Process::Status: pid 87859 exit 0>
    #
    # @return [Process::Status]
    #
    attr_reader :status

    # @attribute [r] stdout
    #
    # The output of the process
    #
    # @example
    #   stdout = "git version 2.39.1\n"
    #   result = Git::CommandLineResult.new($?, stdout, "")
    #   result.stdout #=> "git version 2.39.1\n"
    #
    # @return [String]
    #
    attr_reader :stdout

    # @attribute [r] stderr
    #
    # The error output of the process
    #
    # @example
    #   stderr = "Tag not found\n"
    #   result = Git::CommandLineResult.new($?, "", stderr)
    #   result.stderr #=> "Tag not found\n"
    #
    # @return [String]
    #
    attr_reader :stderr
  end
end
