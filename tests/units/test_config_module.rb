#!/usr/bin/env ruby

require 'test_helper'

class TestConfigModule < Test::Unit::TestCase
  def setup
    clone_working_repo
    git_class = Class.new do
      include Git
    end
    @git = git_class.new
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
    assert_not_equal('bully', @git.config('user.name'))
    @git.config('user.name', 'bully')
    assert_equal('bully', @git.config('user.name'))
  end
end
