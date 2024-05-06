# frozen_string_literal: true

require 'git/base'
require 'git/command_line_result'
require 'git/errors'
require 'stringio'

module Git
  # Runs a git command and returns the result
  #
  # @api public
  #
  class CommandLine
    # Create a Git::CommandLine object
    #
    # @example
    #   env = { 'GIT_DIR' => '/path/to/git/dir' }
    #   binary_path = '/usr/bin/git'
    #   global_opts = %w[--git-dir /path/to/git/dir]
    #   logger = Logger.new(STDOUT)
    #   cli = CommandLine.new(env, binary_path, global_opts, logger)
    #   cli.run('version') #=> #<Git::CommandLineResult:0x00007f9b0c0b0e00
    #
    # @param env [Hash<String, String>] environment variables to set
    # @param global_opts [Array<String>] global options to pass to git
    # @param logger [Logger] the logger to use
    #
    def initialize(env, binary_path, global_opts, logger)
      @env = env
      @binary_path = binary_path
      @global_opts = global_opts
      @logger = logger
    end

    # @attribute [r] env
    #
    # Variables to set (or unset) in the git command's environment
    #
    # @example
    #   env = { 'GIT_DIR' => '/path/to/git/dir' }
    #   command_line = Git::CommandLine.new(env, '/usr/bin/git', [], Logger.new(STDOUT))
    #   command_line.env #=> { 'GIT_DIR' => '/path/to/git/dir' }
    #
    # @return [Hash<String, String>]
    #
    # @see https://ruby-doc.org/3.2.1/Process.html#method-c-spawn Process.spawn
    #   for details on how to set environment variables using the `env` parameter
    #
    attr_reader :env

    # @attribute [r] binary_path
    #
    # The path to the command line binary to run
    #
    # @example
    #   binary_path = '/usr/bin/git'
    #   command_line = Git::CommandLine.new({}, binary_path, ['version'], Logger.new(STDOUT))
    #   command_line.binary_path #=> '/usr/bin/git'
    #
    # @return [String]
    #
    attr_reader :binary_path

    # @attribute [r] global_opts
    #
    # The global options to pass to git
    #
    # These are options that are passed to git before the command name and
    # arguments. For example, in `git --git-dir /path/to/git/dir version`, the
    # global options are %w[--git-dir /path/to/git/dir].
    #
    # @example
    #   env = {}
    #   global_opts = %w[--git-dir /path/to/git/dir]
    #   logger = Logger.new(nil)
    #   cli = CommandLine.new(env, '/usr/bin/git', global_opts, logger)
    #   cli.global_opts #=> %w[--git-dir /path/to/git/dir]
    #
    # @return [Array<String>]
    #
    attr_reader :global_opts

    # @attribute [r] logger
    #
    # The logger to use for logging git commands and results
    #
    # @example
    #   env = {}
    #   global_opts = %w[]
    #   logger = Logger.new(STDOUT)
    #   cli = CommandLine.new(env, '/usr/bin/git', global_opts, logger)
    #   cli.logger == logger #=> true
    #
    # @return [Logger]
    #
    attr_reader :logger

    # Execute a git command, wait for it to finish, and return the result
    #
    # NORMALIZATION
    #
    # The command output is returned as a Unicde string containing the binary output
    # from the command. If the binary output is not valid UTF-8, the output will
    # cause problems because the encoding will be invalid.
    #
    # Normalization is a process that trys to convert the binary output to a valid
    # UTF-8 string. It uses the `rchardet` gem to detect the encoding of the binary
    # output and then converts it to UTF-8.
    #
    # Normalization is not enabled by default. Pass `normalize: true` to Git::CommandLine#run
    # to enable it. Normalization will only be performed on stdout and only if the `out:`` option
    # is nil or is a StringIO object. If the out: option is set to a file or other IO object,
    # the normalize option will be ignored.
    #
    # @example Run a command and return the output
    #   cli.run('version') #=> "git version 2.39.1\n"
    #
    # @example The args array should be splatted into the parameter list
    #   args = %w[log -n 1 --oneline]
    #   cli.run(*args) #=> "f5baa11 beginning of Ruby/Git project\n"
    #
    # @example Run a command and return the chomped output
    #   cli.run('version', chomp: true) #=> "git version 2.39.1"
    #
    # @example Run a command and without normalizing the output
    #   cli.run('version', normalize: false) #=> "git version 2.39.1\n"
    #
    # @example Capture stdout in a temporary file
    #   require 'tempfile'
    #   tempfile = Tempfile.create('git') do |file|
    #     cli.run('version', out: file)
    #     file.rewind
    #     file.read #=> "git version 2.39.1\n"
    #   end
    #
    # @example Capture stderr in a StringIO object
    #   require 'stringio'
    #   stderr = StringIO.new
    #   begin
    #     cli.run('log', 'nonexistent-branch', err: stderr)
    #   rescue Git::FailedError => e
    #     stderr.string #=> "unknown revision or path not in the working tree.\n"
    #   end
    #
    # @param args [Array<String>] the command line arguements to pass to git
    #
    #   This array should be splatted into the parameter list.
    #
    # @param out [#write, nil] the object to write stdout to or nil to ignore stdout
    #
    #   If this is a 'StringIO' object, then `stdout_writer.string` will be returned.
    #
    #   In general, only specify a `stdout_writer` object when you want to redirect
    #   stdout to a file or some other object that responds to `#write`. The default
    #   behavior will return the output of the command.
    #
    # @param err [#write] the object to write stderr to or nil to ignore stderr
    #
    #   If this is a 'StringIO' object and `merged_output` is `true`, then
    #   `stderr_writer.string` will be merged into the output returned by this method.
    #
    # @param normalize [Boolean] whether to normalize the output to a valid encoding
    #
    # @param chomp [Boolean] whether to chomp the output
    #
    # @param merge [Boolean] whether to merge stdout and stderr in the string returned
    #
    # @param chdir [String] the directory to run the command in
    #
    # @param timeout [Numeric, nil] the maximum seconds to wait for the command to complete
    #
    #   If timeout is zero, the timeout will not be enforced.
    #
    #   If the command times out, it is killed via a `SIGKILL` signal and `Git::TimeoutError` is raised.
    #
    #   If the command does not respond to SIGKILL, it will hang this method.
    #
    # @return [Git::CommandLineResult] the output of the command
    #
    #   This result of running the command.
    #
    # @raise [ArgumentError] if `args` is not an array of strings
    #
    # @raise [Git::SignaledError] if the command was terminated because of an uncaught signal
    #
    # @raise [Git::FailedError] if the command returned a non-zero exitstatus
    #
    # @raise [Git::ProcessIOError] if an exception was raised while collecting subprocess output
    #
    # @raise [Git::TimeoutError] if the command times out
    #
    def run(*args, out:, err:, normalize:, chomp:, merge:, chdir: nil, timeout: nil)
      git_cmd = build_git_cmd(args)
      out ||= StringIO.new
      err ||= (merge ? out : StringIO.new)
      status = execute(git_cmd, out, err, chdir: (chdir || :not_set), timeout: timeout)

      process_result(git_cmd, status, out, err, normalize, chomp, timeout)
    end

    private

    # Build the git command line from the available sources to send to `Process.spawn`
    # @return [Array<String>]
    # @api private
    #
    def build_git_cmd(args)
      raise ArgumentError.new('The args array can not contain an array') if args.any? { |a| a.is_a?(Array) }

      [binary_path, *global_opts, *args].map { |e| e.to_s }
    end

    # Determine the output to return in the `CommandLineResult`
    #
    # If the writer can return the output by calling `#string` (such as a StringIO),
    # then return the result of normalizing the encoding and chomping the output
    # as requested.
    #
    # If the writer does not support `#string`, then return nil. The output is
    # assumed to be collected by the writer itself such as when the  writer
    # is a file instead of a StringIO.
    #
    # @param writer [#string] the writer to post-process
    #
    # @return [String, nil]
    #
    # @api private
    #
    def post_process(writer, normalize, chomp)
      if writer.respond_to?(:string)
        output = writer.string.dup
        output = output.lines.map { |l| Git::EncodingUtils.normalize_encoding(l) }.join if normalize
        output.chomp! if chomp
        output
      else
        nil
      end
    end

    # Post-process all writers and return an array of the results
    #
    # @param writers [Array<#write>] the writers to post-process
    # @param normalize [Boolean] whether to normalize the output of each writer
    # @param chomp [Boolean] whether to chomp the output of each writer
    #
    # @return [Array<String, nil>] the output of each writer that supports `#string`
    #
    # @api private
    #
    def post_process_all(writers, normalize, chomp)
      Array.new.tap do |result|
        writers.each { |writer| result << post_process(writer, normalize, chomp) }
      end
    end

    # Raise an error when there was exception while collecting the subprocess output
    #
    # @param git_cmd [Array<String>] the git command that was executed
    # @param pipe_name [Symbol] the name of the pipe that raised the exception
    # @param pipe [ProcessExecuter::MonitoredPipe] the pipe that raised the exception
    #
    # @raise [Git::ProcessIOError]
    #
    # @return [void] this method always raises an error
    #
    # @api private
    #
    def raise_pipe_error(git_cmd, pipe_name, pipe)
      raise Git::ProcessIOError.new("Pipe Exception for #{git_cmd}: #{pipe_name}"), cause: pipe.exception
    end

    # Execute the git command and collect the output
    #
    # @param cmd [Array<String>] the git command to execute
    # @param chdir [String] the directory to run the command in
    # @param timeout [Numeric, nil] the maximum seconds to wait for the command to complete
    #
    #   If timeout is zero of nil, the command will not time out. If the command
    #   times out, it is killed via a SIGKILL signal and `Git::TimeoutError` is raised.
    #
    #   If the command does not respond to SIGKILL, it will hang this method.
    #
    # @raise [Git::ProcessIOError] if an exception was raised while collecting subprocess output
    # @raise [Git::TimeoutError] if the command times out
    #
    # @return [ProcessExecuter::Status] the status of the completed subprocess
    #
    # @api private
    #
    def spawn(cmd, out_writers, err_writers, chdir:, timeout:)
      out_pipe = ProcessExecuter::MonitoredPipe.new(*out_writers, chunk_size: 10_000)
      err_pipe = ProcessExecuter::MonitoredPipe.new(*err_writers, chunk_size: 10_000)
      ProcessExecuter.spawn(env, *cmd, out: out_pipe, err: err_pipe, chdir: chdir, timeout: timeout)
    ensure
      out_pipe.close
      err_pipe.close
      raise_pipe_error(cmd, :stdout, out_pipe) if out_pipe.exception
      raise_pipe_error(cmd, :stderr, err_pipe) if err_pipe.exception
    end

    # The writers that will be used to collect stdout and stderr
    #
    # Additional writers could be added here if you wanted to tee output
    # or send output to the terminal.
    #
    # @param out [#write] the object to write stdout to
    # @param err [#write] the object to write stderr to
    #
    # @return [Array<Array<#write>, Array<#write>>] the writers for stdout and stderr
    #
    # @api private
    #
    def writers(out, err)
      out_writers = [out]
      err_writers = [err]
      [out_writers, err_writers]
    end

    # Process the result of the command and return a Git::CommandLineResult
    #
    # Post process output, log the command and result, and raise an error if the
    # command failed.
    #
    # @param git_cmd [Array<String>] the git command that was executed
    # @param status [Process::Status] the status of the completed subprocess
    # @param out [#write] the object that stdout was written to
    # @param err [#write] the object that stderr was written to
    # @param normalize [Boolean] whether to normalize the output of each writer
    # @param chomp [Boolean] whether to chomp the output of each writer
    # @param timeout [Numeric, nil] the maximum seconds to wait for the command to complete
    #
    # @return [Git::CommandLineResult] the result of the command to return to the caller
    #
    # @raise [Git::FailedError] if the command failed
    # @raise [Git::SignaledError] if the command was signaled
    # @raise [Git::TimeoutError] if the command times out
    # @raise [Git::ProcessIOError] if an exception was raised while collecting subprocess output
    #
    # @api private
    #
    def process_result(git_cmd, status, out, err, normalize, chomp, timeout)
      out_str, err_str = post_process_all([out, err], normalize, chomp)
      logger.info { "#{git_cmd} exited with status #{status}" }
      logger.debug { "stdout:\n#{out_str.inspect}\nstderr:\n#{err_str.inspect}" }
      Git::CommandLineResult.new(git_cmd, status, out_str, err_str).tap do |result|
        raise Git::TimeoutError.new(result, timeout) if status.timeout?
        raise Git::SignaledError.new(result) if status.signaled?
        raise Git::FailedError.new(result) unless status.success?
      end
    end

    # Execute the git command and write the command output to out and err
    #
    # @param git_cmd [Array<String>] the git command to execute
    # @param out [#write] the object to write stdout to
    # @param err [#write] the object to write stderr to
    # @param chdir [String] the directory to run the command in
    # @param timeout [Numeric, nil] the maximum seconds to wait for the command to complete
    #
    #   If timeout is zero of nil, the command will not time out. If the command
    #   times out, it is killed via a SIGKILL signal and `Git::TimeoutError` is raised.
    #
    #   If the command does not respond to SIGKILL, it will hang this method.
    #
    # @raise [Git::ProcessIOError] if an exception was raised while collecting subprocess output
    # @raise [Git::TimeoutError] if the command times out
    #
    # @return [Git::CommandLineResult] the result of the command to return to the caller
    #
    # @api private
    #
    def execute(git_cmd, out, err, chdir:, timeout:)
      out_writers, err_writers = writers(out, err)
      spawn(git_cmd, out_writers, err_writers, chdir: chdir, timeout: timeout)
    end
  end
end
