#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../test_helper'

class TestObject < Test::Unit::TestCase
  def setup
    set_file_paths
    @git = Git.open(@wdir)
    
    @commit = @git.gcommit('1cc8667014381')
    @tree = @git.gtree('1cc8667014381^{tree}')
    @blob = @git.gblob('v2.5:example.txt')
  end
  
  def test_commit
    o = @git.gcommit('1cc8667014381')
    assert(o.is_a?(Git::Object::Commit))
    assert(o.commit?)
    assert(!o.tag?)
    
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
    
    o = @git.gcommit('HEAD')
    assert(o.is_a?(Git::Object::Commit))
    assert(o.commit?)
    
    o = @git.gcommit('test_object')
    assert(o.is_a?(Git::Object::Commit))
    assert(o.commit?)
  end
  
  def test_commit_contents
    o = @git.gcommit('1cc8667014381')
    assert_equal('tree 94c827875e2cadb8bc8d4cdd900f19aa9e8634c7', o.contents_array[0])
    assert_equal('parent 546bec6f8872efa41d5d97a369f669165ecda0de', o.contents_array[1])
  end
  
  def test_object_to_s
    assert_equal('1cc8667014381e2788a94777532a788307f38d26', @commit.sha)
    assert_equal('94c827875e2cadb8bc8d4cdd900f19aa9e8634c7', @tree.sha)
    assert_equal('ba492c62b6227d7f3507b4dcc6e6d5f13790eabf', @blob.sha)
  end
  
  def test_object_size
    assert_equal(265, @commit.size)
    assert_equal(72, @tree.size)
    assert_equal(128, @blob.size)
  end
  
  def test_tree
    o = @git.gtree('1cc8667014381^{tree}')
    assert(o.is_a?(Git::Object::Tree))
    assert(o.tree?)
    
    o = @git.gtree('v2.7^{tree}')
    
    assert_equal(2, o.children.size)
    assert_equal(1, o.blobs.size)
    assert_equal(1, o.subtrees.size)
    assert_equal(1, o.trees['ex_dir'].blobs.size)

    assert_equal(2, o.full_tree.size)
    assert_equal("100644 blob e69de29bb2d1d6434b8b29ae775ad8c2e48c5391\tex_dir/ex.txt", o.full_tree.first)
    
    assert_equal(2, o.depth)
    
    o = @git.gtree('94c827875e2cadb8bc8d4cdd900f19aa9e8634c7')
    assert(o.is_a?(Git::Object::Tree))
    assert(o.tree?)
  end
  
  def test_tree_contents
    o = @git.gtree('1cc8667014381^{tree}')
    assert_equal('040000 tree 6b790ddc5eab30f18cabdd0513e8f8dac0d2d3ed	ex_dir', o.contents_array.first)
  end
  
  def test_blob
    o = @git.gblob('ba492c62b6')
    assert(o.is_a?(Git::Object::Blob))
    assert(o.blob?)
    
    o = @git.gblob('v2.5:example.txt')
    assert(o.is_a?(Git::Object::Blob))
    assert(o.blob?)
  end
  
  def test_blob_contents
    o = @git.gblob('v2.6:example.txt')
    assert_equal('replace with new text', o.contents)
    assert_equal('replace with new text', o.contents)  # this should be cached
    
    # make sure the block is called
    block_called = false
    o.contents do |f|
      block_called = true
      assert_equal('replace with new text', f.read.chomp)
    end
    
    assert(block_called)
  end
  
  def test_revparse
    sha = @git.revparse('v2.6:example.txt')
    assert_equal('1f09f2edb9c0d9275d15960771b363ca6940fbe3', sha)
  end
  
  def test_grep
    g = @git.gtree('a3db7143944dcfa0').grep('search') # there
    assert_equal(3, g.to_a.flatten.size)
    assert_equal(1, g.size)

    assert_equal({}, @git.gtree('a3db7143944dcfa0').grep('34a566d193'))  # not there

    g = @git.gcommit('gitsearch1').grep('search') # there
    assert_equal(8, g.to_a.flatten.size)
    assert_equal(2, g.size)
    
    g = @git.gcommit('gitsearch1').grep('search', 'scott/new*') # there
    assert_equal(3, g.to_a.flatten.size)
    assert_equal(1, g.size)
  end
  
  
end
