#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../test_helper'

class TestBranch < Test::Unit::TestCase
  def setup
    set_file_paths
    @git = Git.open(@wdir)
    
    @commit = @git.object('1cc8667014381')
    @tree = @git.object('1cc8667014381^{tree}')
    @blob = @git.object('v2.5:example.txt')
    
    @branches = @git.branches
  end

  
  def test_branches_all
    assert(@git.branches[:master].is_a?(Git::Branch))
    assert(@git.branches.size > 5)
  end
  
  def test_branches_local
    bs = @git.branches.local
    assert(bs.size > 4)
  end

  def test_branches_remote
    bs = @git.branches.remote
    assert_equal(1, bs.size)
  end
  
  def test_branches_single
    b = @git.branches[:test_object]
    assert_equal('test_object', b.name)

    b = @git.branches['working/master']
    assert_equal('master', b.name)
    assert_equal('working/master', b.full)
    assert_equal('working', b.remote.name)
    assert_equal('+refs/heads/*:refs/remotes/working/*', b.remote.fetch)
    assert_equal('../working.git', b.remote.url)
  end
  
  def test_branch_commit
    assert_equal(270, @git.branches[:test_branches].commit.size)
  end
  
end