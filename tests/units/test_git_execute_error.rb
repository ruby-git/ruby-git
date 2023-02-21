require 'test_helper'

class TestGitExecuteError < Test::Unit::TestCase
  def test_is_a_standard_error
    assert(Git::GitExecuteError < StandardError)
  end
end
