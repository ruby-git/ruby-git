#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../test_helper'

class TestBare < Test::Unit::TestCase
  
  def setup
    set_file_paths
    @git = Git.bare(@wbare)
  end
  
  def test_commit
    o = @git.object('1cc8667014381')
    assert(o.is_a?(Git::Object::Commit))
    
    assert_equal('94c827875e2cadb8bc8d4cdd900f19aa9e8634c7', o.gtree.to_s)
    assert_equal('546bec6f8872efa41d5d97a369f669165ecda0de', o.parent.sha)
    assert_equal(1, o.parents.size)
    assert_equal('scott Chacon', o.author.name)
    assert_equal('schacon@agadorsparticus.corp.reactrix.com', o.author.email)
    assert_equal('11-08-07', o.author.date.strftime("%m-%d-%y"))
    assert_equal('11-08-07', o.author_date.strftime("%m-%d-%y"))
    assert_equal('scott Chacon', o.committer.name)
    assert_equal('11-08-07', o.committer_date.strftime("%m-%d-%y"))
    assert_equal('11-08-07', o.date.strftime("%m-%d-%y"))
    assert_equal('test', o.message)
    
    assert_equal('tags/v2.5', o.parent.name)
    assert_equal('master', o.parent.parent.name)
    assert_equal('master~1', o.parent.parent.parent.name)
    
    o = @git.object('HEAD')
    assert(o.is_a?(Git::Object::Commit))
    assert(o.commit?)
    
    o = @git.object('test_object')
    assert(o.is_a?(Git::Object::Commit))
    assert(o.commit?)
  end
  
end