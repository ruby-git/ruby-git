# frozen_string_literal: true

require 'test_helper'
require 'tempfile'

class TestCommamndLine < Test::Unit::TestCase
  test "initialize" do
    global_opts = %q[--opt1=test --opt2]

    command_line = Git::CommandLine.new(env, binary_path, global_opts, logger)

    assert_equal(env, command_line.env)
    assert_equal(global_opts, command_line.global_opts)
    assert_equal(logger, command_line.logger)
  end

  # DEFAULT VALUES
  #
  # These are used by tests so the test can just change the value it wants to test.
  #
  def env
    {}
  end

  def binary_path
    @binary_path ||= 'ruby'
  end

  def global_opts
    @global_opts ||= ['bin/command_line_test']
  end

  def logger
    @logger ||= Logger.new(nil)
  end

  def out_writer
    nil
  end

  def err_writer
    nil
  end

  def normalize
    false
  end

  def chomp
    false
  end

  def merge
    false
  end

  # END DEFAULT VALUES

  sub_test_case "when a timeout is given" do
    test 'it should raise an ArgumentError if the timeout is not an Integer, Float, or nil' do
      command_line = Git::CommandLine.new(env, binary_path, global_opts, logger)
      args = []
      error = assert_raise ArgumentError do
        command_line.run(*args, out: out_writer, err: err_writer, normalize: normalize, chomp: chomp, merge: merge, timeout: 'not a number')
      end
    end

    test 'it should raise a Git::TimeoutError if the command takes too long' do
      command_line = Git::CommandLine.new(env, binary_path, global_opts, logger)
      args = ['--duration=5']

      error = assert_raise Git::TimeoutError do
        command_line.run(*args, out: out_writer, err: err_writer, normalize: normalize, chomp: chomp, merge: merge, timeout: 0.01)
      end
    end

    test 'the error raised should indicate the command timed out' do
      command_line = Git::CommandLine.new(env, binary_path, global_opts, logger)
      args = ['--duration=5']

      # Git::TimeoutError (alone with Git::FailedError and Git::SignaledError) is a
      # subclass of Git::Error

      begin
        command_line.run(*args, out: out_writer, err: err_writer, normalize: normalize, chomp: chomp, merge: merge, timeout: 0.01)
      rescue Git::Error => e
        assert_equal(true, e.result.status.timeout?)
      end
    end
  end

  test "run should return a result that includes the command ran, its output, and resulting status" do
    command_line = Git::CommandLine.new(env, binary_path, global_opts, logger)
    args = ['--stdout=stdout output', '--stderr=stderr output']
    result = command_line.run(*args, out: out_writer, err: err_writer, normalize: normalize, chomp: chomp, merge: merge)

    assert_equal(['ruby', 'bin/command_line_test', '--stdout=stdout output', '--stderr=stderr output'], result.git_cmd)
    assert_equal('stdout output', result.stdout.chomp)
    assert_equal('stderr output', result.stderr.chomp)
    assert(result.status.is_a? ProcessExecuter::Status)
    assert_equal(0, result.status.exitstatus)
  end

  test "run should raise FailedError if command fails" do
    command_line = Git::CommandLine.new(env, binary_path, global_opts, logger)
    args = ['--exitstatus=1', '--stdout=O1', '--stderr=O2']
    error = assert_raise Git::FailedError do
      command_line.run(*args, out: out_writer, err: err_writer, normalize: normalize, chomp: chomp, merge: merge)
    end

    # The error raised should include the result of the command
    result = error.result

    assert_equal(['ruby', 'bin/command_line_test', '--exitstatus=1', '--stdout=O1', '--stderr=O2'], result.git_cmd)
    assert_equal('O1', result.stdout.chomp)
    assert_equal('O2', result.stderr.chomp)
    assert_equal(1, result.status.exitstatus)
  end

  unless Gem.win_platform?
    # Ruby on Windows doesn't support signals fully (at all?)
    # See https://blog.simplificator.com/2016/01/18/how-to-kill-processes-on-windows-using-ruby/
    test "run should raise SignaledError if command exits because of an uncaught signal" do
      command_line = Git::CommandLine.new(env, binary_path, global_opts, logger)
      args = ['--signal=9', '--stdout=O1', '--stderr=O2']
      error = assert_raise Git::SignaledError do
        command_line.run(*args, out: out_writer, err: err_writer, normalize: normalize, chomp: chomp, merge: merge)
      end

      # The error raised should include the result of the command
      result = error.result

      assert_equal(['ruby', 'bin/command_line_test', '--signal=9', '--stdout=O1', '--stderr=O2'], result.git_cmd)
      # If stdout is buffered, it may not be flushed when the process is killed
      # assert_equal('O1', result.stdout.chomp)
      assert_equal('O2', result.stderr.chomp)
      assert_equal(9, result.status.termsig)
    end
  end

  test "run should chomp output if chomp is true" do
    command_line = Git::CommandLine.new(env, binary_path, global_opts, logger)
    args = ['--stdout=stdout output']
    chomp = true
    result = command_line.run(*args, out: out_writer, err: err_writer, normalize: normalize, chomp: chomp, merge: merge)

    assert_equal('stdout output', result.stdout)
  end

  test "run should normalize output if normalize is true" do
    command_line = Git::CommandLine.new(env, binary_path, global_opts, logger)
    args = ['--stdout=stdout output']

    def command_line.spawn(cmd, out_writers, err_writers, chdir: nil, timeout: nil)
      out_writers.each { |w| w.write(File.read('tests/files/encoding/test1.txt')) }
      `true`
      ProcessExecuter::Status.new($?, false) # return status
    end

    normalize = true
    result = command_line.run(*args, out: out_writer, err: err_writer, normalize: normalize, chomp: chomp, merge: merge)

    expected_output = <<~OUTPUT
      Λορεμ ιπσθμ δολορ σιτ
      Ηισ εξ τοτα σθαvιτατε
      Νο θρβανιτασ
      Φεθγιατ θρβανιτασ ρεπριμιqθε
    OUTPUT

    assert_equal(expected_output, result.stdout)
  end

  test "run should NOT normalize output if normalize is false" do
    command_line = Git::CommandLine.new(env, binary_path, global_opts, logger)
    args = ['--stdout=stdout output']

    def command_line.spawn(cmd, out_writers, err_writers, chdir: nil, timeout: nil)
      out_writers.each { |w| w.write(File.read('tests/files/encoding/test1.txt')) }
      `true`
      ProcessExecuter::Status.new($?, false) # return status
    end

    normalize = false
    result = command_line.run(*args, out: out_writer, err: err_writer, normalize: normalize, chomp: chomp, merge: merge)

    expected_output = <<~OUTPUT
      \xCB\xEF\xF1\xE5\xEC \xE9\xF0\xF3\xE8\xEC \xE4\xEF\xEB\xEF\xF1 \xF3\xE9\xF4
      \xC7\xE9\xF3 \xE5\xEE \xF4\xEF\xF4\xE1 \xF3\xE8\xE1v\xE9\xF4\xE1\xF4\xE5
      \xCD\xEF \xE8\xF1\xE2\xE1\xED\xE9\xF4\xE1\xF3
      \xD6\xE5\xE8\xE3\xE9\xE1\xF4 \xE8\xF1\xE2\xE1\xED\xE9\xF4\xE1\xF3 \xF1\xE5\xF0\xF1\xE9\xEC\xE9q\xE8\xE5
    OUTPUT

    assert_equal(expected_output, result.stdout)
  end

  test "run should redirect stderr to stdout if merge is true" do
    command_line = Git::CommandLine.new(env, binary_path, global_opts, logger)
    args = ['--stdout=stdout output', '--stderr=stderr output']
    merge = true
    result = command_line.run(*args, out: out_writer, err: err_writer, normalize: normalize, chomp: chomp, merge: merge)

    # The output should be merged, but the order depends on a number of
    # external factors
    assert_include(result.stdout, 'stdout output')
    assert_include(result.stdout, 'stderr output')
  end

  test "run should log command and output if logger is given" do
    log_output = StringIO.new
    logger = Logger.new(log_output, level: Logger::DEBUG)
    command_line = Git::CommandLine.new(env, binary_path, global_opts, logger)
    args = ['--stdout=stdout output']
    result = command_line.run(*args, out: out_writer, err: err_writer, normalize: normalize, chomp: chomp, merge: merge)

    # The command and its exitstatus should be logged on INFO level
    assert_match(/^I, .*exited with status pid \d+ exit \d+$/, log_output.string)

    # The command's stdout and stderr should be logged on DEBUG level
    assert_match(/^D, .*stdout:\n.*\nstderr:\n.*$/, log_output.string)
  end

  test "run should be able to redirect stdout to a file" do
    command_line = Git::CommandLine.new(env, binary_path, global_opts, logger)
    args = ['--stdout=stdout output']
    Tempfile.create do |f|
      out_writer = f
      result = command_line.run(*args, out: out_writer, err: err_writer, normalize: normalize, chomp: chomp, merge: merge)
      f.rewind
      assert_equal('stdout output', f.read.chomp)
    end
  end

  test "run should raise a Git::ProcessIOError if there was an error raised writing stdout" do
    command_line = Git::CommandLine.new(env, binary_path, global_opts, logger)
    args = ['--stdout=stdout output']
    out_writer = Class.new do
      def write(*args)
        raise IOError, 'error writing to file'
      end
    end.new

    error = assert_raise Git::ProcessIOError do
      command_line.run(*args, out: out_writer, err: err_writer, normalize: normalize, chomp: chomp, merge: merge)
    end

    assert_kind_of(Git::ProcessIOError, error)
    assert_kind_of(IOError, error.cause)
    assert_equal('error writing to file', error.cause.message)
  end

  test "run should be able to redirect stderr to a file" do
    command_line = Git::CommandLine.new(env, binary_path, global_opts, logger)
    args = ['--stderr=ERROR: fatal error', '--stdout=STARTING PROCESS']
    Tempfile.create do |f|
      err_writer = f
      result = command_line.run(*args, out: out_writer, err: err_writer, normalize: normalize, chomp: chomp, merge: merge)
      f.rewind
      assert_equal('ERROR: fatal error', f.read.chomp)
    end
  end

  test "run should raise a Git::ProcessIOError if there was an error raised writing stderr" do
    command_line = Git::CommandLine.new(env, binary_path, global_opts, logger)
    args = ['--stderr=ERROR: fatal error']
    err_writer = Class.new do
      def write(*args)
        raise IOError, 'error writing to stderr file'
      end
    end.new

    error = assert_raise Git::ProcessIOError do
      command_line.run(*args, out: out_writer, err: err_writer, normalize: normalize, chomp: chomp, merge: merge)
    end

    assert_kind_of(Git::ProcessIOError, error)
    assert_kind_of(IOError, error.cause)
    assert_equal('error writing to stderr file', error.cause.message)
  end

  test 'run should be able to redirect stdout and stderr to the same file' do
    command_line = Git::CommandLine.new(env, binary_path, global_opts, logger)
    args = ['--stderr=ERROR: fatal error', '--stdout=STARTING PROCESS']
    Tempfile.create do |f|
      out_writer = f
      merge = true
      result = command_line.run(*args, out: out_writer, err: err_writer, normalize: normalize, chomp: chomp, merge: merge)
      f.rewind
      output = f.read

      # The output should be merged, but the order depends on a number of
      # external factors
      assert_include(output, 'ERROR: fatal error')
      assert_include(output, 'STARTING PROCESS')
    end
  end
end
