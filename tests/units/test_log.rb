#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../test_helper'

class TestLog < Test::Unit::TestCase
  def setup
    set_file_paths
    @git = Git.open(@wdir)
  end

  def test_get_log_entries
    log = @git.log
    assert(log.first.is_a?(Git::Object::Commit))
  end
  
  def test_get_log_entries    
    assert_equal(30, @git.log.size)
    assert_equal(50, @git.log(50).size)
    assert_equal(10, @git.log(10).size)
  end

  def test_get_log_to_s
    assert_equal(@git.log.to_s.split("\n").first, @git.log.first.sha)
  end
  
  def test_get_log_since
    l = @git.log.since("2 seconds ago")
    assert_equal(0, l.size)
    
    l = @git.log.since("2 years ago")
    assert_equal(30, l.size)
  end
  
  def test_get_log_since_file    
    l = @git.log.object('example.txt')
    assert_equal(30, l.size)
  
    l = @git.log.between('v2.5', 'test').path('example.txt')
    assert_equal(1, l.size)
  end
  
  def test_log_file_noexist
    assert_raise Git::GitExecuteError do
      @git.log.object('no-exist.txt').size
    end
  end
  
end
