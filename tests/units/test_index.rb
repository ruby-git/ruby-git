#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../test_helper'

class TestIndex< Test::Unit::TestCase
  
  def setup
    set_file_paths
    @git = Git.open(@wdir)
  end
  
  def test_add
    in_temp_dir do |path|
      #puts path
      g = Git.clone(@wbare, 'new')
      Dir.chdir('new') do
        assert_equal('100644', g.status['example.txt'].mode_index)
        new_file('test-file', 'blahblahblah')
        assert(g.status.untracked.assoc('test-file'))
        g.add
        assert(g.status.added.assoc('test-file'))
        assert(!g.status.untracked.assoc('test-file'))
        assert(!g.status.changed.assoc('example.txt'))
        append_file('example.txt', 'hahahaha')
        assert(g.status.changed.assoc('example.txt'))
        g.add
        assert(g.status.changed.assoc('example.txt'))
        g.commit('my message')
        assert(!g.status.changed.assoc('example.txt'))
        assert(!g.status.added.assoc('test-file'))
        assert(!g.status.untracked.assoc('test-file'))        
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