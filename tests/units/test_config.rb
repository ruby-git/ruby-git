#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../test_helper'

class TestBranch < Test::Unit::TestCase
  def setup
    set_file_paths
    @git = Git.open(@wdir)
  end
  
  def test_config
    c = @git.config
    assert_equal('scott Chacon', c['user.name'])
    assert_equal('false', c['core.bare'])
  end
  
  def test_read_config
    assert_equal('scott Chacon', @git.config('user.name'))
    assert_equal('false', @git.config('core.bare'))
  end
  
  def test_set_config
    # !! TODO !!
  end  
  
end