require 'test_helper'

class TestSignaledError < Test::Unit::TestCase
  def test_initializer
    status = Struct.new(:to_s).new('pid 65628 SIGKILL (signal 9)') # `kill -9 $$`
    result = Git::CommandLineResult.new(%w[git status], status, '', "uncaught signal")

    error = Git::SignaledError.new(result)

    assert(error.is_a?(Git::GitExecuteError))
    assert_equal(result, error.result)
  end

  def test_message
    status = Struct.new(:to_s).new('pid 65628 SIGKILL (signal 9)') # `kill -9 $$`
    result = Git::CommandLineResult.new(%w[git status], status, '', "uncaught signal")

    error = Git::SignaledError.new(result)

    expected_message = "[\"git\", \"status\"]\nstatus: pid 65628 SIGKILL (signal 9)\nstderr: \"uncaught signal\""
    assert_equal(expected_message, error.message)
  end
end
