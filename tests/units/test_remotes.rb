#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../test_helper'

class TestRemotes < Test::Unit::TestCase
  def setup
    set_file_paths
  end

  def test_add_remote
    in_temp_dir do |path|
      local = Git.clone(@wbare, 'local')
      remote = Git.clone(@wbare, 'remote')

      local.add_remote('testremote', remote)

      assert(!local.branches.map{|b| b.full}.include?('testremote/master'))
      assert(local.remotes.map{|b| b.name}.include?('testremote'))

      local.add_remote('testremote2', remote, :fetch => true)

      assert(local.branches.map{|b| b.full}.include?('remotes/testremote2/master'))
      assert(local.remotes.map{|b| b.name}.include?('testremote2'))

      local.add_remote('testremote3', remote, :track => 'master')
      
      assert(local.branches.map{|b| b.full}.include?('master')) #We actually a new branch ('test_track') on the remote and track that one intead. 
      assert(local.remotes.map{|b| b.name}.include?('testremote3'))
    end 
  end

  def test_remove_remote_remove
    in_temp_dir do |path|
      local = Git.clone(@wbare, 'local')
      remote = Git.clone(@wbare, 'remote')
      
      local.add_remote('testremote', remote)
      local.remove_remote('testremote')
      
      assert(!local.remotes.map{|b| b.name}.include?('testremote'))

      local.add_remote('testremote', remote)
      local.remote('testremote').remove
      
      assert(!local.remotes.map{|b| b.name}.include?('testremote'))
    end
  end
  
  def test_remote_fun
    in_temp_dir do |path|
      loc = Git.clone(@wbare, 'local')
      rem = Git.clone(@wbare, 'remote')
        
      r = loc.add_remote('testrem', rem)

      Dir.chdir('remote') do
        new_file('test-file1', 'blahblahblah1')
        rem.add
        rem.commit('master commit')
        
        rem.branch('testbranch').in_branch('tb commit') do
          new_file('test-file3', 'blahblahblah3')
          rem.add
          true          
        end
      end
      assert(!loc.status['test-file1'])
      assert(!loc.status['test-file3'])
    
      r.fetch
      r.merge   
      assert(loc.status['test-file1'])
      
      loc.merge(loc.remote('testrem').branch('testbranch'))
      assert(loc.status['test-file3'])    
      
      #puts loc.remotes.map { |r| r.to_s }.inspect
      
      #r.remove  
      #puts loc.remotes.inspect
    end
  end
  
  def test_push
    in_temp_dir do |path|
      loc = Git.clone(@wbare, 'local')
      rem = Git.clone(@wbare, 'remote', :config => 'receive.denyCurrentBranch=ignore')
        
      loc.add_remote('testrem', rem)

      loc.chdir do
        new_file('test-file1', 'blahblahblah1')
        loc.add
        loc.commit('master commit')
        loc.add_tag('test-tag')
        
        loc.branch('testbranch').in_branch('tb commit') do
          new_file('test-file3', 'blahblahblah3')
          loc.add
          true          
        end
      end
      assert(!rem.status['test-file1'])
      assert(!rem.status['test-file3'])
      
      loc.push('testrem')

      assert(rem.status['test-file1'])    
      assert(!rem.status['test-file3'])    
      assert_raise Git::GitTagNameDoesNotExist do
        rem.tag('test-tag')
      end
      
      loc.push('testrem', 'testbranch', true)

      rem.checkout('testbranch')
      assert(rem.status['test-file1'])    
      assert(rem.status['test-file3'])    
      assert(rem.tag('test-tag'))
    end
  end


end
