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
    branch = @git.branches[:test_object]
    assert_equal('test_object', branch.name)

    %w{working/master remotes/working/master}.each do |branch_name|
      branch = @git.branches[branch_name]
     
      assert_equal('master', branch.name)
      assert_equal('remotes/working/master', branch.full)
      assert_equal('working', branch.remote.name)
      assert_equal('+refs/heads/*:refs/remotes/working/*', branch.remote.fetch_opts)
      assert_equal('../working.git', branch.remote.url)
    end
  end
  
  def test_branch_commit
    assert_equal(270, @git.branches[:test_branches].gcommit.size)
  end
  
  def test_branch_create_and_switch
    in_temp_dir do |path|
      g = Git.clone(@wbare, 'branch_test')
      Dir.chdir('branch_test') do
        assert(!g.branch('new_branch').current)
        g.branch('other_branch').create
        g.branch('new_branch').checkout
        assert(g.branch('new_branch').current)

        assert_equal(1, g.branches.select { |b| b.name == 'new_branch' }.size)

        new_file('test-file1', 'blahblahblah1')
        new_file('test-file2', 'blahblahblah2')
        assert(g.status.untracked.assoc('test-file1'))
        
        g.add(['test-file1', 'test-file2'])
        assert(!g.status.untracked.assoc('test-file1'))
        
        g.reset
        assert(g.status.untracked.assoc('test-file1'))
        assert(!g.status.added.assoc('test-file1'))

        assert_raise Git::GitExecuteError do
          g.branch('new_branch').delete 
        end
        assert_equal(1, g.branches.select { |b| b.name == 'new_branch' }.size)

        g.branch('master').checkout
        g.branch('new_branch').delete
        assert_equal(0, g.branches.select { |b| b.name == 'new_branch' }.size)
        
        g.checkout('other_branch')
        assert(g.branch('other_branch').current)

        g.checkout('master')
        assert(!g.branch('other_branch').current)

        g.checkout(g.branch('other_branch'))
        assert(g.branch('other_branch').current)
        
      end
    end
  end
  
end
