# frozen_string_literal: true

module Git
  module CommandLine
    # The result of running a git command
    #
    # This object stores the Git command executed and its status, stdout, and stderr.
    #
    # @api public
    #
    class Result
      # Create a Result object
      #
      # @example
      #   git_cmd = %w[git version]
      #   status = instance_double(ProcessExecuter::Result)
      #   stdout = "git version 2.39.1\n"
      #   stderr = ""
      #   result = Git::CommandLine::Result.new(git_cmd, status, stdout, stderr)
      #
      # @param git_cmd [Array<String>] the git command that was executed
      #
      # @param status [ProcessExecuter::Result] the process result object returned
      #   by `ProcessExecuter.run` or `ProcessExecuter.run_with_capture`.
      #   Responds to `timed_out?`, `signaled?`, and `success?`.
      #
      # @param stdout [String] the processed stdout of the process
      #
      # @param stderr [String] the processed stderr of the process
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
      #   git_cmd = %w[git version]
      #   result = Git::CommandLine::Result.new(git_cmd, nil, '', '')
      #   result.git_cmd #=> ["git", "version"]
      #
      # @return [Array<String>]
      #
      attr_reader :git_cmd

      # @attribute [r] status
      #
      # The process result object returned by ProcessExecuter
      #
      # In practice this is a `ProcessExecuter::ResultWithCapture` (from
      # {Git::CommandLine::Capturing}) or a `ProcessExecuter::Result` (from
      # {Git::CommandLine::Streaming}). Both respond to `success?`, `timed_out?`,
      # and `signaled?`.
      #
      # @example
      #   status = instance_double(ProcessExecuter::Result, success?: true)
      #   result = Git::CommandLine::Result.new(%w[git version], status, '', '')
      #   result.status == status #=> true
      #
      # @return [ProcessExecuter::Result]
      #
      attr_reader :status

      # @attribute [r] stdout
      #
      # The output of the process
      #
      # @example
      #   stdout = "git version 2.39.1\n"
      #   result = Git::CommandLine::Result.new([], nil, stdout, '')
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
      #   result = Git::CommandLine::Result.new([], nil, '', stderr)
      #   result.stderr #=> "Tag not found\n"
      #
      # @return [String]
      #
      attr_reader :stderr
    end
  end
end
