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
    def run(*args, out: nil, err: nil, normalize:, chomp:, merge:, chdir: nil, timeout: nil)
      git_cmd = build_git_cmd(args)
      begin
        result = ProcessExecuter.run(env, *git_cmd, out: out, err: err, merge:, chdir: (chdir || :not_set), timeout: timeout, raise_errors: false)
      rescue ProcessExecuter::Command::ProcessIOError => e
        raise Git::ProcessIOError.new(e.message), cause: e.exception.cause
      end
      process_result(result, normalize, chomp, timeout)
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

    # Process the result of the command and return a Git::CommandLineResult
    #
    # Post process output, log the command and result, and raise an error if the
    # command failed.
    #
    # @param result [ProcessExecuter::Command::Result] the result it is a Process::Status and include command, stdout, and stderr
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
    def process_result(result, normalize, chomp, timeout)
      command = result.command
      processed_out, processed_err = post_process_all([result.stdout, result.stderr], normalize, chomp)
      logger.info { "#{command} exited with status #{result}" }
      logger.debug { "stdout:\n#{processed_out.inspect}\nstderr:\n#{processed_err.inspect}" }
      Git::CommandLineResult.new(command, result, processed_out, processed_err).tap do |processed_result|
        raise Git::TimeoutError.new(processed_result, timeout) if result.timeout?
        raise Git::SignaledError.new(processed_result) if result.signaled?
        raise Git::FailedError.new(processed_result) unless result.success?
      end
    end

    # Post-process command output and return an array of the results
    #
    # @param raw_outputs [Array] the output to post-process
    # @param normalize [Boolean] whether to normalize the output of each writer
    # @param chomp [Boolean] whether to chomp the output of each writer
    #
    # @return [Array<String, nil>] the processed output of each command output object that supports `#string`
    #
    # @api private
    #
    def post_process_all(raw_outputs, normalize, chomp)
      Array.new.tap do |result|
        raw_outputs.each { |raw_output| result << post_process(raw_output, normalize, chomp) }
      end
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
    # @param raw_output [#string] the output to post-process
    # @return [String, nil]
    #
    # @api private
    #
    def post_process(raw_output, normalize, chomp)
      if raw_output.respond_to?(:string)
        output = raw_output.string.dup
        output = output.lines.map { |l| Git::EncodingUtils.normalize_encoding(l) }.join if normalize
        output.chomp! if chomp
        output
      else
        nil
      end
    end
  end
end
