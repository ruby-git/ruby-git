# frozen_string_literal: true

require 'test_helper'

class TestStashList < Test::Unit::TestCase
  test 'stashes_all returns a single-element array for one stash' do
    in_bare_repo_clone do |g|
      new_file('test-file1', 'content1')
      g.add
      g.branch.stashes.save('my stash message')

      result = g.stashes_all

      assert_equal(1, result.size)
      assert_equal([0, 'my stash message'], result[0])
    end
  end

  test 'stashes_all returns a multi-element array for multiple stashes' do
    in_bare_repo_clone do |g|
      new_file('test-file1', 'content1')
      g.add
      g.branch.stashes.save('first stash')

      new_file('test-file2', 'content2')
      g.add
      g.branch.stashes.save('second stash')

      result = g.stashes_all

      assert_equal(2, result.size)
      assert_equal([0, 'first stash'], result[0])
      assert_equal([1, 'second stash'], result[1])
    end
  end

  test 'stashes_all returns empty array when no stashes exist' do
    in_bare_repo_clone do |g|
      result = g.stashes_all

      assert_equal([], result)
    end
  end

  test 'stashes_all returns [index, message] pair for stash from detached HEAD' do
    in_bare_repo_clone do |g|
      # Create a commit so we have something to detach to
      new_file('test-file1', 'content1')
      g.add
      g.commit('add test file')

      # Detach HEAD by checking out the commit directly
      sha = g.log.execute.first.sha
      g.checkout(sha)

      # Create a change and stash it
      append_file('test-file1', "\nmodified content")
      g.add
      g.branch.stashes.save('detached stash')

      result = g.stashes_all

      assert_equal(1, result.size)
      assert_equal(0, result[0][0])
      assert_equal('detached stash', result[0][1])
    end
  end

  test 'stashes_all handles a stash message containing a colon' do
    in_bare_repo_clone do |g|
      new_file('test-file1', 'content1')
      g.add
      g.branch.stashes.save('fix: important bug')

      result = g.stashes_all

      assert_equal(1, result.size)
      assert_equal([0, 'fix: important bug'], result[0])
    end
  end

  test 'stashes_all handles a stash created with a custom message via git stash store' do
    in_temp_dir do
      `git init`
      `echo "hello world" > file1.txt`
      `git add file1.txt`
      `git commit -m "First commit"`
      `echo "update" > file1.txt`
      commit = `git stash create "stash message"`.chomp
      `git stash store -m "custom message" #{commit}`

      git = Git.open('.')

      result = git.stashes_all

      assert_equal(1, result.size)
      assert_equal([0, 'custom message'], result[0])
    end
  end

  test 'stashes_all handles a stash store message that itself contains a colon' do
    in_temp_dir do
      `git init`
      `echo "hello world" > file1.txt`
      `git add file1.txt`
      `git commit -m "First commit"`
      `echo "update" > file1.txt`
      commit = `git stash create "stash message"`.chomp
      `git stash store -m "fix: important bug" #{commit}`

      git = Git.open('.')

      result = git.stashes_all

      assert_equal(1, result.size)
      assert_equal([0, 'fix: important bug'], result[0])
    end
  end
end
