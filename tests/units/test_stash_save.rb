# frozen_string_literal: true

require 'test_helper'

class TestStashSave < Test::Unit::TestCase
  test 'stash_save returns true when changes are stashed' do
    in_bare_repo_clone do |g|
      new_file('test-file1', 'content1')
      g.add

      result = g.lib.stash_save('save with changes')

      assert_equal(true, result)
    end
  end

  test 'stash_save returns false when there are no local changes to save' do
    in_bare_repo_clone do |g|
      result = g.lib.stash_save('save without changes')

      assert_equal(false, result)
    end
  end

  test 'stash_save raises an error on an unborn branch' do
    in_temp_dir do
      `git init`
      File.write('file.txt', 'hello')
      `git add file.txt`

      git = Git.open('.')

      assert_raise(Git::FailedError) do
        git.lib.stash_save('unborn stash')
      end
    end
  end
end
