#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../test_helper'

class TestObject < Test::Unit::TestCase
  def setup
    set_file_paths
    @git = Git.open(@wdir)
  end
  
  def test_commit
    o = @git.object('1cc8667014381')
    assert(o.is_a?(Git::Object::Commit))
    
    o = @git.object('HEAD')
    assert(o.is_a?(Git::Object::Commit))
    assert_equal('commit', o.type)
    
    o = @git.object('test_object')
    assert(o.is_a?(Git::Object::Commit))
    assert_equal('commit', o.type)
  end
  
  def test_commit_contents
    o = @git.object('1cc8667014381')
    assert_equal('tree 94c827875e2cadb8bc8d4cdd900f19aa9e8634c7', o.contents_array[0])
    assert_equal('parent 546bec6f8872efa41d5d97a369f669165ecda0de', o.contents_array[1])
  end
  
  def test_object_to_s
    o = @git.object('1cc8667014381')
    assert_equal('commit 1cc8667014381e2788a94777532a788307f38d26', o.to_s)
    
    o = @git.object('1cc8667014381^{tree}')
    assert_equal('tree   94c827875e2cadb8bc8d4cdd900f19aa9e8634c7', o.to_s)
    
    o = @git.object('v2.5:example.txt')
    assert_equal('blob   ba492c62b6227d7f3507b4dcc6e6d5f13790eabf', o.to_s)
  end
  
  def test_tree
    o = @git.object('1cc8667014381^{tree}')
    assert(o.is_a?(Git::Object::Tree))
    
    o = @git.object('94c827875e2cadb8bc8d4cdd900f19aa9e8634c7')
    assert(o.is_a?(Git::Object::Tree))
    assert_equal('tree', o.type)
  end
  
  def test_tree_contents
    o = @git.object('1cc8667014381^{tree}')
    assert_equal('040000 tree 6b790ddc5eab30f18cabdd0513e8f8dac0d2d3ed	ex_dir', o.contents_array.first)
  end
  
  def test_blob
    o = @git.object('ba492c62b6')
    assert(o.is_a?(Git::Object::Blob))
    
    o = @git.object('v2.5:example.txt')
    assert(o.is_a?(Git::Object::Blob))
    assert_equal('blob', o.type)
  end
  
  def test_blob_contents
    o = @git.object('v2.6:example.txt')
    assert_equal('replace with new text', o.contents)
  end
  
end