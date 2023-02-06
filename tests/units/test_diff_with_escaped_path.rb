#!/usr/bin/env ruby
# encoding: utf-8

require 'test_helper'

# Test diff when the file path has to be quoted according to core.quotePath
# See https://git-scm.com/docs/git-config#Documentation/git-config.txt-corequotePath
#
class TestDiffWithEscapedPath < Test::Unit::TestCase
  def test_diff_with_non_ascii_filename
    in_temp_dir do |path|
      create_file('my_other_file_☠', "First Line\n")
      `git init`
      `git add .`
      `git config --local core.safecrlf false` if Gem.win_platform?
      `git commit -m "First Commit"`
      update_file('my_other_file_☠', "Second Line\n")
      diff_paths = Git.open('.').diff.map(&:path)
      assert_equal(["my_other_file_☠"], diff_paths)
    end
  end
end
