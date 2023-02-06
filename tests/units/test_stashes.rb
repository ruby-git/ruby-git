#!/usr/bin/env ruby

require 'test_helper'

class TestStashes < Test::Unit::TestCase
  def test_stash_unstash
    in_bare_repo_clone do |g|
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

  def test_stashes_all
    in_bare_repo_clone do |g|
      assert_equal(0, g.branch.stashes.size)
      new_file('test-file1', 'blahblahblah1')
      new_file('test-file2', 'blahblahblah2')
      assert(g.status.untracked.assoc('test-file1'))

      g.add

      assert(g.status.added.assoc('test-file1'))

      g.branch.stashes.save('testing-stash-all')

      stashes = g.branch.stashes.all

      assert(stashes[0].include?('testing-stash-all'))
    end
  end
end
