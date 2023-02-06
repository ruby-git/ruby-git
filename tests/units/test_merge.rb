#!/usr/bin/env ruby

require 'test_helper'

class TestMerge < Test::Unit::TestCase
  def test_branch_and_merge
    in_bare_repo_clone do |g|
      g.branch('new_branch').in_branch('test') do
        assert_equal('new_branch', g.current_branch)
        new_file('new_file_1', 'hello')
        new_file('new_file_2', 'hello')
        g.add
        true
      end

      assert_equal('master', g.current_branch)

      new_file('new_file_3', 'hello')
      g.add

      assert(!g.status['new_file_1'])  # file is not there

      assert(g.branch('new_branch').merge)
      assert(g.status['new_file_1'])  # file has been merged in
    end
  end

  def test_branch_and_merge_two
    in_bare_repo_clone do |g|
      g.branch('new_branch').in_branch('test') do
        assert_equal('new_branch', g.current_branch)
        new_file('new_file_1', 'hello')
        new_file('new_file_2', 'hello')
        g.add
        true
      end

      g.branch('new_branch2').in_branch('test') do
        assert_equal('new_branch2', g.current_branch)
        new_file('new_file_3', 'hello')
        new_file('new_file_4', 'hello')
        g.add
        true
      end

      g.branch('new_branch').merge('new_branch2')
      assert(!g.status['new_file_3'])  # still in master branch

      g.branch('new_branch').checkout
      assert(g.status['new_file_3'])  # file has been merged in

      g.branch('master').checkout
      g.merge(g.branch('new_branch'))
      assert(g.status['new_file_3'])  # file has been merged in

    end
  end

  def test_branch_and_merge_multiple
    in_bare_repo_clone do |g|
      g.branch('new_branch').in_branch('test') do
        assert_equal('new_branch', g.current_branch)
        new_file('new_file_1', 'hello')
        new_file('new_file_2', 'hello')
        g.add
        true
      end

      g.branch('new_branch2').in_branch('test') do
        assert_equal('new_branch2', g.current_branch)
        new_file('new_file_3', 'hello')
        new_file('new_file_4', 'hello')
        g.add
        true
      end

      assert(!g.status['new_file_1'])  # still in master branch
      assert(!g.status['new_file_3'])  # still in master branch

      g.merge(['new_branch', 'new_branch2'])

      assert(g.status['new_file_1'])  # file has been merged in
      assert(g.status['new_file_3'])  # file has been merged in

    end
  end

  def test_no_ff_merge
    in_bare_repo_clone do |g|
      g.branch('new_branch').in_branch('first commit message') do
        new_file('new_file_1', 'hello')
        g.add
        true
      end

      g.branch('new_branch2').checkout
      g.merge('new_branch', 'merge commit message') # ff merge
      assert(g.status['new_file_1']) # file has been merged in
      assert_equal('first commit message', g.log.first.message) # merge commit message was ignored

      g.branch('new_branch').in_branch('second commit message') do
        new_file('new_file_2', 'hello')
        g.add
        true
      end

      assert_equal('new_branch2', g.current_branch) # still in new_branch2 branch
      g.merge('new_branch', 'merge commit message', no_ff: true) # no-ff merge
      assert(g.status['new_file_2']) # file has been merged in
      assert_equal('merge commit message', g.log.first.message)
    end
  end

  def test_merge_no_commit
    in_bare_repo_clone do |g|
      g.branch('new_branch_1').in_branch('first commit message') do
        new_file('new_file_1', 'foo')
        g.add
        true
      end

      g.branch('new_branch_2').in_branch('first commit message') do
        new_file('new_file_2', 'bar')
        g.add
        true
      end

      g.checkout('new_branch_2')
      before_merge = g.show
      g.merge('new_branch_1', nil, no_commit: true)
      # HEAD is the same as before.
      assert_equal(before_merge, g.show)
      # File has not been merged in.
      status = g.status['new_file_1']
      assert_equal('new_file_1', status.path)
      assert_equal('A', status.type)
    end
  end
end
