#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../test_helper'

class TestRebase < Test::Unit::TestCase
  def setup
    set_file_paths
  end

  def clone_in_temp_dir(name)
    in_temp_dir do |path|
      g = Git.clone(@wbare, name)
      Dir.chdir(name) do
        yield g
      end
    end
  end
  
  def test_branch_and_rebase_master
    clone_in_temp_dir('branch_rebase_test') do |g|

      branch_message = 'branch_file'
      g.branch('new_branch').in_branch(branch_message) do
        assert_equal('new_branch', g.current_branch)
        new_file('new_file_2', 'hello')
        g.add
        true
      end

      assert_equal('master', g.current_branch)
      new_file('new_file_1', 'hello')
      g.add        
      g.commit 'master'

      assert_equal('master', g.current_branch)
      assert(!g.status['new_file_2']) 
      
      assert(g.branch('new_branch').rebase)
      g.branch('new_branch').in_branch do 
        assert(g.status['new_file_1'])
        assert(g.status['new_file_2'])
        assert_equal(branch_message, g.log.first.message)
        assert(g.status)
      end
    end
  end

  def test_branch_and_fail_rebase
    clone_in_temp_dir('branch_fail_rebase_test') do |g|

      branch_message = 'branch_file'
      g.branch('new_branch').in_branch(branch_message) do
        assert_equal('new_branch', g.current_branch)
        new_file('new_file_1', 'new_branch')
        g.add
        true
      end

      assert_equal('master', g.current_branch)
      new_file('new_file_1', 'master')
      g.add        
      g.commit 'master'

      assert_equal('master', g.current_branch)
      assert_raise do
        g.branch('new_branch').rebase
      end
      assert(g.status)
    end
  end

  def test_branch_rebase_with_merge
    clone_in_temp_dir('branch_rebase_with_merge') do |g|

      branch_message = 'branch_file'
      g.branch('new_branch').in_branch(branch_message) do
        assert_equal('new_branch', g.current_branch)
        new_file('new_file_1', 'hello')
        g.add
        true
      end

      assert_equal('master', g.current_branch)
      new_file('new_file_1', 'hello')
      g.add        
      g.commit 'master'

      assert_equal('master', g.current_branch)
      assert(g.branch('new_branch').rebase)
      assert(g.status)
    end
  end
end