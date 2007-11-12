#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../test_helper'

class TestRemotes < Test::Unit::TestCase
  def setup
    set_file_paths
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

end