#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../test_helper'

class TestStashes < Test::Unit::TestCase
  def setup
    set_file_paths
  end
  
  def test_stash_unstash
    in_temp_dir do |path|
      g = Git.clone(@wbare, 'stash_test')
      Dir.chdir('stash_test') do
        assert_equal(0, g.branch.stashes.size)
        new_file('test-file1', 'blahblahblah1')
        new_file('test-file2', 'blahblahblah2')
        assert(g.status.untracked.assoc('test-file1'))

        g.add

        assert(g.status.added.assoc('test-file1'))
      
        g.branch.stashes.save('testing')
      
        g.reset
        assert_nil(g.status.untracked.assoc('test-file1'))
        assert_nil(g.status.added.assoc('test-file1'))

        g.branch.stashes.apply

        assert(g.status.added.assoc('test-file1'))
      end
    end
  end
  
end