#!/usr/bin/env ruby

require 'test_helper'

class TestDescribe < Test::Unit::TestCase

  def setup
    clone_working_repo
    @git = Git.open(@wdir)
  end

  def test_describe
    assert_equal(@git.describe(nil, {:tags => true}), 'grep_colon_numbers')
  end

end
