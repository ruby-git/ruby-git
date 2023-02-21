require 'test_helper'

class TestCommamndLineResult < Test::Unit::TestCase
  def test_initialization
    git_cmd = Object.new
    status = Object.new
    stdout = Object.new
    stderr = Object.new

    result = Git::CommandLineResult.new(git_cmd, status, stdout, stderr)

    assert_equal(git_cmd, result.git_cmd)
    assert_equal(status, result.status)
    assert_equal(stdout, result.stdout)
    assert_equal(stderr, result.stderr)
  end
end
