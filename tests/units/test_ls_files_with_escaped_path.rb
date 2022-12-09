#!/usr/bin/env ruby
# encoding: utf-8

require File.dirname(__FILE__) + '/../test_helper'

# Test diff when the file path has to be quoted according to core.quotePath
# See https://git-scm.com/docs/git-config#Documentation/git-config.txt-corequotePath
#
class TestLsFilesWithEscapedPath < Test::Unit::TestCase
  def test_diff_with_non_ascii_filename
    in_temp_dir do |path|
      create_file('my_other_file_☠', "First Line\n")
      create_file('README.md', '# My Project')
      `git init`
      `git add .`
      `git config --local core.safecrlf false` if Gem.win_platform?
      `git commit -m "First Commit"`
      paths = Git.open('.').ls_files.keys.sort
      assert_equal(["my_other_file_☠", 'README.md'].sort, paths)
    end
  end
end
