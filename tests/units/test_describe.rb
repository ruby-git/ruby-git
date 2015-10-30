#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../test_helper'

class TestDescribe < Test::Unit::TestCase

  def setup
    set_file_paths
    @git = Git.open(@wdir)
  end

  def test_describe
    assert_equal(@git.describe(nil, {:tags => true}), 'v2.8')
  end

  def test_describe_with_exact_tag_match
    assert_equal(@git.describe(nil, {:tags => true, :match => 'v2.8'}), 'v2.8')
  end

  def test_describe_with_match
    assert_equal(@git.describe(nil, {:tags => true, :match => 'v2.6'}), 'v2.6-4-g5e53019')
  end
end
