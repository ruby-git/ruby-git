#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../test_helper'

class TestIndex< Test::Unit::TestCase
  
  def setup
    set_file_paths
    @git = Git.open(@wdir)
  end
  
  def test_add
    in_temp_dir do |path|
      g = Git.clone(@wbare, 'new')
      Dir.chdir('new') do
        puts `pwd`
        #assert_equal('100644', g.status['example.txt'].mode_index)
        
        new_file('test-file', 'blahblahblah')
        assert(g.status.untracked.assoc('test-file'))
        
        g.add
        assert(g.status.added.assoc('test-file'))
        assert(!g.status.untracked.assoc('test-file'))
        assert(!g.status.changed.assoc('example.txt'))
        
        append_file('example.txt', 'hahahaha')
        puts g.status.pretty
        assert(g.status.changed.assoc('example.txt'))
        
        g.add
        assert(g.status.changed.assoc('example.txt'))
        
        g.commit('my message')
        assert(!g.status.changed.assoc('example.txt'))
        assert(!g.status.added.assoc('test-file'))
        assert(!g.status.untracked.assoc('test-file')) 
        assert_equal('hahahaha', g.status['example.txt'].blob.contents)
      end
    end
  end
  
  def test_add_array
    in_temp_dir do |path|
      g = Git.clone(@wbare, 'new')
      Dir.chdir('new') do
        
        new_file('test-file1', 'blahblahblah1')
        new_file('test-file2', 'blahblahblah2')
        assert(g.status.untracked.assoc('test-file1'))
        
        g.add(['test-file1', 'test-file2'])
        assert(g.status.added.assoc('test-file1'))
        assert(g.status.added.assoc('test-file1'))
        assert(!g.status.untracked.assoc('test-file1'))
                
        g.commit('my message')
        assert(!g.status.added.assoc('test-file1'))
        assert(!g.status.untracked.assoc('test-file1')) 
        assert_equal('blahblahblah1', g.status['test-file1'].blob.contents)
      end
    end
  end
  
  def new_file(name, contents)
    File.open(name, 'w') do |f|
      f.puts contents
    end
  end

  def append_file(name, contents)
    File.open(name, 'a') do |f|
      f.puts contents
    end
  end
  
end