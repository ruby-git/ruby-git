# frozen_string_literal: true

require 'test_helper'

class TestCommandLineError < Test::Unit::TestCase
  def test_initializer
    status = Class.new { def to_s = 'pid 89784 exit 1' }.new
    result = Git::CommandLineResult.new(%w[git status], status, 'stdout', 'stderr')
    error = Git::CommandLineError.new(result)

    assert(error.is_a?(Git::Error))
    assert_equal(result, error.result)
  end

  def test_to_s
    status = Class.new { def to_s = 'pid 89784 exit 1' }.new
    result = Git::CommandLineResult.new(%w[git status], status, 'stdout', 'stderr')

    error = Git::CommandLineError.new(result)

    expected_message = '["git", "status"], status: pid 89784 exit 1, stderr: "stderr"'
    assert_equal(expected_message, error.to_s)
  end
end
