#!/usr/bin/env ruby
require 'logger'
require File.dirname(__FILE__) + '/../test_helper'

class TestRawInternals < Test::Unit::TestCase
  
  def setup
    set_file_paths
  end
  
  def test_raw_log
    with_temp_bare do |g|
      t_log(g)
    end
  end
  
  def test_packed_log
    with_temp_bare do |g|
      g.repack
      t_log(g)
    end
  end
  
  def test_commit_object
    g = Git.bare(@wbare)    
    c = g.gcommit("v2.5")
    assert_equal('test', c.message)
  end
  
  def test_lstree
    g = Git.bare(@wbare)
    c = g.object("v2.5").gtree
    sha = c.sha
    
    repo = Git::Raw::Repository.new(@wbare)
    assert_equal('ex_dir', repo.object(sha).entry.first.name)
  end
  
  def t_log(g)
    c = g.object("v2.5")
    sha = c.sha
    
    repo = Git::Raw::Repository.new(g.repo.path)
    raw_out = repo.log(sha)
    
    assert_equal('commit 546bec6f8872efa41d5d97a369f669165ecda0de', raw_out.split("\n").first)
    assert_equal('546bec6f8872efa41d5d97a369f669165ecda0de', c.log(30).first.sha)
  end
  
  

  
end