#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../test_helper'

class TestGitConfig < Test::Unit::TestCase
  def setup
    set_file_paths
    @git = Git::GitConfig
    @old_dir = Dir.pwd
    Dir.chdir(@wdir)
  end
  
  teardown
  def test_teardown
    Dir.chdir(@old_dir)
  end
  
  def test_config
    c = @git.config
    assert_equal('Scott Chacon', c['user.name'])
    assert_equal('false', c['core.bare'])
  end
  
  def test_read_config
    assert_equal('Scott Chacon', @git.config('user.name'))
    assert_equal('false', @git.config('core.bare'))
  end
  
  def test_set_config
    in_temp_dir do |path|
      g = Git.clone(@wbare, 'bare')
      assert_not_equal('bully', g.config('user.name'))
      g.config('user.name', 'bully')
      assert_equal('bully', g.config('user.name'))
    end
  end
end
