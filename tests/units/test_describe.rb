#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../test_helper'

class TestDescribe < Test::Unit::TestCase

  def setup
    set_file_paths
    @git = Git.open(@wdir)
  end

  def test_describe
    assert_equal'v2.8', @git.describe(nil, tags: true)
  end

end
