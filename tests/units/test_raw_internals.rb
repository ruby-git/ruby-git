#!/usr/bin/env ruby
require 'logger'
require File.dirname(__FILE__) + '/../test_helper'

class TestRawInternals < Test::Unit::TestCase
  
  def setup
    set_file_paths
  end
  
  def test_raw_log
    g = Git.bare(@wbare)
    t_log(g)
  end
  
  def test_packed_log
    g = Git.bare(@wbare)
    g.repack
    t_log(g)
  end
  
  def test_commit_object
    g = Git.bare(@wbare, :log => Logger.new(STDOUT))
    
    c = g.gcommit("v2.5")
    assert_equal('test', c.message)
  end
  
  def t_log(g)
    c = g.object("v2.5")
    sha = c.sha
    
    repo = Git::Raw::Repository.new(@wbare)
    raw_out = repo.log(sha)
    
    assert_equal('commit 546bec6f8872efa41d5d97a369f669165ecda0de', raw_out.split("\n").first)
    assert_equal('546bec6f8872efa41d5d97a369f669165ecda0de', c.log(30).first.sha)
  end
  
end