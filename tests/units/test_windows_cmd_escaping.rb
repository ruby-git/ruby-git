#!/usr/bin/env ruby
# encoding: utf-8

require 'test_helper'

# Test diff when the file path has to be quoted according to core.quotePath
# See https://git-scm.com/docs/git-config#Documentation/git-config.txt-corequotePath
#
class TestWindowsCmdEscaping < Test::Unit::TestCase
  def test_commit_with_double_quote_in_commit_message
    expected_commit_message = 'Commit message with "double quotes"'
    in_temp_dir do |path|
      create_file('README.md', "# README\n")
      git = Git.init('.')
      git.add
      git.commit(expected_commit_message)
      commits = git.log(1)
      actual_commit_message = commits.first.message
      assert_equal(expected_commit_message, actual_commit_message)
    end
  end
end
