# frozen_string_literal: true

require 'test_helper'

class TestTimeoutError < Test::Unit::TestCase
  def test_initializer
    # `kill -9 $$`
    status = Class.new { def to_s = 'pid 65628 SIGKILL (signal 9)' }.new
    result = Git::CommandLineResult.new(%w[git status], status, 'stdout', 'stderr')
    timeout_diration = 10

    error = Git::TimeoutError.new(result, timeout_diration)

    assert(error.is_a?(Git::SignaledError))
  end

  def test_to_s
    # `kill -9 $$`
    status = Class.new { def to_s = 'pid 65628 SIGKILL (signal 9)' }.new
    result = Git::CommandLineResult.new(%w[git status], status, 'stdout', 'Waiting...')
    timeout_duration = 10

    error = Git::TimeoutError.new(result, timeout_duration)

    expected_message = '["git", "status"], status: pid 65628 SIGKILL (signal 9), stderr: "Waiting...", timed out after 10s'
    assert_equal(expected_message, error.to_s)
  end
end
