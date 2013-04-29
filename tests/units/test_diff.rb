#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../test_helper'

class TestDiff < Test::Unit::TestCase
  def setup
    set_file_paths
    @git = Git.open(@wdir)
    @diff = @git.diff('gitsearch1', 'v2.5')
  end
  
  #def test_diff
  #  g.diff
  #  assert(1, d.size)
  #end

  def test_diff_tags
    d = @git.diff('gitsearch1', 'v2.5')
    assert_equal(3, d.size)
    assert_equal(74, d.lines)
    assert_equal(10, d.deletions)
    assert_equal(64, d.insertions)
  end

  def test_diff_path
    d = @git.diff('gitsearch1', 'v2.5').path('scott/')
    assert_equal(d.from, 'gitsearch1')
    assert_equal(d.to, 'v2.5')
    assert_equal(2, d.size)
    assert_equal(9, d.lines)
    assert_equal(9, d.deletions)
    assert_equal(0, d.insertions)
  end
  
  def test_diff_objects
    d = @git.diff('gitsearch1', @git.gtree('v2.5'))
    assert_equal(3, d.size)
  end
  
  def test_object_diff
    d = @git.gtree('v2.5').diff('gitsearch1')
    assert_equal(3, d.size)
    assert_equal(74, d.lines)
    assert_equal(10, d.insertions)
    assert_equal(64, d.deletions)
    
    d = @git.gtree('v2.6').diff(@git.gtree('gitsearch1'))
    assert_equal(2, d.size)
    assert_equal(9, d.lines)
  end
  
  def test_diff_stats
    s = @diff.stats
    assert_equal(3, s[:total][:files])
    assert_equal(74, s[:total][:lines])
    assert_equal(10, s[:total][:deletions])
    assert_equal(64, s[:total][:insertions])
    
    # per file
    assert_equal(1, s[:files]["scott/newfile"][:deletions])
  end
  
  def test_diff_hashkey
    assert_equal('5d46068', @diff["scott/newfile"].src)
    assert_nil(@diff["scott/newfile"].blob(:dst))
    assert(@diff["scott/newfile"].blob(:src).is_a?(Git::Object::Blob))
  end
  
  def test_patch
    p = @git.diff('v2.8^', 'v2.8').patch
    diff = "diff --git a/example.txt b/example.txt\nindex 1f09f2e..8dc79ae 100644\n--- a/example.txt\n+++ b/example.txt\n@@ -1 +1 @@\n-replace with new text\n+replace with new text - diff test"
    assert_equal(diff, p)
  end
  
  def test_diff_each
    files = {}
    @diff.each do |d|
      files[d.path] = d
    end
    
    assert(files['example.txt'])
    assert_equal('100644', files['scott/newfile'].mode)
    assert_equal('deleted', files['scott/newfile'].type)
    assert_equal(160, files['scott/newfile'].patch.size)
  end
  
  
end
