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

  test 'Git::Lib#stashes_all' do
    in_bare_repo_clone do |g|
      assert_equal(0, g.branch.stashes.size)
      new_file('test-file1', 'blahblahblah1')
      new_file('test-file2', 'blahblahblah2')
      assert(g.status.untracked.assoc('test-file1'))

      g.add

      assert(g.status.added.assoc('test-file1'))

      g.branch.stashes.save('testing-stash-all')

      # puts `cat .git/logs/refs/stash`
      # 0000000000000000000000000000000000000000 b9b008cd179b0e8c4b8cda35bac43f7011a0836a James Couball <jcouball@yahoo.com> 1729463252 -0700   On master: testing-stash-all

      stashes = assert_nothing_raised { g.lib.stashes_all }

      expected_stashes = [
        [0, 'testing-stash-all']
      ]

      assert_equal(expected_stashes, stashes)
    end
  end

  test 'Git::Lib#stashes_all - stash message has colon' do
    in_bare_repo_clone do |g|
      assert_equal(0, g.branch.stashes.size)
      new_file('test-file1', 'blahblahblah1')
      new_file('test-file2', 'blahblahblah2')
      assert(g.status.untracked.assoc('test-file1'))

      g.add

      assert(g.status.added.assoc('test-file1'))

      g.branch.stashes.save('saving: testing-stash-all')

      # puts `cat .git/logs/refs/stash`
      # 0000000000000000000000000000000000000000 b9b008cd179b0e8c4b8cda35bac43f7011a0836a James Couball <jcouball@yahoo.com> 1729463252 -0700   On master: saving: testing-stash-all

      stashes = assert_nothing_raised { g.lib.stashes_all }

      expected_stashes = [
        [0, 'saving: testing-stash-all']
      ]

      assert_equal(expected_stashes, stashes)
    end
  end

  test 'Git::Lib#stashes_all -- git stash message with no branch and no colon' do
    in_temp_dir do
      `git init`
      `echo "hello world" > file1.txt`
      `git add file1.txt`
      `git commit -m "First commit"`
      `echo "update" > file1.txt`
      commit = `git stash create "stash message"`.chomp
      # Create a stash with this message: 'custom message'
      `git stash store -m "custom message" #{commit}`

      # puts `cat .git/logs/refs/stash`
      # 0000000000000000000000000000000000000000 0550a54ed781eda364ca3c22fcc46c37acae4bd6 James Couball <jcouball@yahoo.com> 1729460302 -0700   custom message

      git = Git.open('.')

      stashes = assert_nothing_raised { git.lib.stashes_all }

      expected_stashes = [
        [0, 'custom message']
      ]

      assert_equal(expected_stashes, stashes)
    end
  end

  test 'Git::Lib#stashes_all -- git stash message with no branch and explicit colon' do
    in_temp_dir do
      `git init`
      `echo "hello world" > file1.txt`
      `git add file1.txt`
      `git commit -m "First commit"`
      `echo "update" > file1.txt`
      commit = `git stash create "stash message"`.chomp
      # Create a stash with this message: 'custom message'
      `git stash store -m "testing: custom message" #{commit}`

      # puts `cat .git/logs/refs/stash`
      # 0000000000000000000000000000000000000000 eadd7858e53ea4fb8b1383d69cade1806d948867 James Couball <jcouball@yahoo.com> 1729462039 -0700   testing: custom message

      git = Git.open('.')

      stashes = assert_nothing_raised { git.lib.stashes_all }

      expected_stashes = [
        [0, 'custom message']
      ]

      assert_equal(expected_stashes, stashes)
    end
  end
end
