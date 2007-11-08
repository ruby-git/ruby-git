#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../test_helper'

class TestInit < Test::Unit::TestCase
  def setup
    set_file_paths
    @git = Git.open(@wdir)
  end

  def test_get_log_entries
    log = @git.log
    assert(log.first.is_a? Git::Commit)
  end
  
  def test_get_log_entries
    assert_equal(30, @git.log.size)
    assert_equal(50, @git.log(50).size)
    assert_equal(10, @git.log(10).size)
  end

  def test_get_log_to_s
    assert_equal(@git.log.to_s.split("\n").first, @git.log.first.sha)
  end
  
end
