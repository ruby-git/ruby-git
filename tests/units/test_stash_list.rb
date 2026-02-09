# frozen_string_literal: true

require 'test_helper'

class TestStashList < Test::Unit::TestCase
  test 'stash_list returns standard format for a single stash on a branch' do
    in_bare_repo_clone do |g|
      new_file('test-file1', 'content1')
      g.add
      g.branch.stashes.save('my stash message')

      result = g.lib.stash_list

      assert_match(/\Astash@\{0\}: On master: my stash message\z/, result)
    end
  end

  test 'stash_list returns standard format for multiple stashes' do
    in_bare_repo_clone do |g|
      new_file('test-file1', 'content1')
      g.add
      g.branch.stashes.save('first stash')

      new_file('test-file2', 'content2')
      g.add
      g.branch.stashes.save('second stash')

      result = g.lib.stash_list
      lines = result.split("\n")

      assert_equal(2, lines.size)
      assert_match(/\Astash@\{0\}: On master: second stash\z/, lines[0])
      assert_match(/\Astash@\{1\}: On master: first stash\z/, lines[1])
    end
  end

  test 'stash_list returns empty string when no stashes exist' do
    in_bare_repo_clone do |g|
      result = g.lib.stash_list

      assert_equal('', result)
    end
  end

  test 'stash_list returns standard format for stash from detached HEAD' do
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

      result = g.lib.stash_list

      # When stashing from detached HEAD, git uses "WIP on (no branch):" format
      assert_match(/\Astash@\{0\}: (?:WIP on|On) \(no branch\): detached stash\z/, result)
    end
  end

  test 'stash_list returns standard format for stash with colon in message' do
    in_bare_repo_clone do |g|
      new_file('test-file1', 'content1')
      g.add
      g.branch.stashes.save('fix: important bug')

      result = g.lib.stash_list

      assert_match(/\Astash@\{0\}: On master: fix: important bug\z/, result)
    end
  end

  test 'stash_list returns standard format for stash with custom message via git stash store' do
    in_temp_dir do
      `git init`
      `echo "hello world" > file1.txt`
      `git add file1.txt`
      `git commit -m "First commit"`
      `echo "update" > file1.txt`
      commit = `git stash create "stash message"`.chomp
      `git stash store -m "custom message" #{commit}`

      git = Git.open('.')

      result = git.lib.stash_list

      # Custom stash store messages have no branch prefix
      assert_match(/\Astash@\{0\}: custom message\z/, result)
    end
  end
end
