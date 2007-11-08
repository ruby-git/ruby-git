#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../test_helper'

class TestInit < Test::Unit::TestCase
  def setup
    set_file_paths
  end

  def test_open_simple
    g = Git.open(@wdir)
    assert_equal(g.dir.path, @wdir)
    assert_equal(g.repo.path, File.join(@wdir, '.git'))
    assert_equal(g.index.path, File.join(@wdir, '.git', 'index'))
  end
    
  def test_open_opts 
    g = Git.open @wdir, :repository => @wbare, :index => @index
    assert_equal(g.repo.path, @wbare)
    assert_equal(g.index.path, @index)
  end
  
  def test_git_bare
    g = Git.repo @wbare
    assert_equal(g.repo.path, @wbare)
  end

  # trying to open a git project using a bare repo - rather than using Git.repo
  def test_git_open_error
    assert_raise ArgumentError do
      g = Git.open @wbare
    end
  end
  
end
