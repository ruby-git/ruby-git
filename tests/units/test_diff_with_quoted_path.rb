#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../test_helper'

class TestDiffWithQuotedPath < Test::Unit::TestCase
  def git_working_dir
    test_dir = File.join(`git rev-parse --show-toplevel`.chomp, 'tests', 'files')
    create_temp_repo(File.expand_path(File.join(test_dir, 'quoted_path')))
  end

  def create_temp_repo(clone_path)
    filename = 'git_test' + Time.now.to_i.to_s + rand(300).to_s.rjust(3, '0')
    @tmp_path = File.join("/tmp/", filename)
    FileUtils.mkdir_p(@tmp_path)
    FileUtils.cp_r(clone_path, @tmp_path)
    tmp_path = File.join(@tmp_path, File.basename(clone_path))
    Dir.chdir(tmp_path) do
      FileUtils.mv('dot_git', '.git')
    end
    tmp_path
  end

  def setup
    @git = Git.open(git_working_dir)
  end

  def test_diff_with_quoted_path
    diff = @git.diff('@^')
    diff_paths = []
    assert_nothing_raised do
      diff.each { |diff_file| diff_paths << diff_file.path }
    end
    assert_include(diff_paths, 'asdf\"asdf')
    assert_include(diff_paths, 'my_other_file_☠')
  end
end
