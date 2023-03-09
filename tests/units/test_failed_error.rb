require 'test_helper'

class TestFailedError < Test::Unit::TestCase
  def test_initializer
    status = Struct.new(:to_s).new('pid 89784 exit 1')
    result = Git::CommandLineResult.new(%w[git status], status, 'stdout', 'stderr')

    error = Git::FailedError.new(result)

    assert(error.is_a?(Git::GitExecuteError))
    assert_equal(result, error.result)
  end

  def test_message
    status = Struct.new(:to_s).new('pid 89784 exit 1')
    result = Git::CommandLineResult.new(%w[git status], status, 'stdout', 'stderr')

    error = Git::FailedError.new(result)

    expected_message = "[\"git\", \"status\"]\nstatus: pid 89784 exit 1\noutput: \"stdout\""
    assert_equal(expected_message, error.message)
  end
end
