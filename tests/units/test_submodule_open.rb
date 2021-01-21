#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../test_helper'
require 'English'

class TestShow < Test::Unit::TestCase
  def setup
    @temp_dir = Dir.mktmpdir

    @submodule_working_tree_path = File.join(@temp_dir, 'submodule')
    @main_working_tree_path = File.join(@temp_dir, 'main')
    @submodule_path_in_main = 'my_submodule'

    FileUtils.mkdir_p(@submodule_working_tree_path)

    g = Git.init(@submodule_working_tree_path)
    File.write(File.join(@submodule_working_tree_path, 'submodule_file.md'), '# Submodule File')
    g.add('submodule_file.md')
    g.commit('Initial submodule commit')
    @submodule_head = g.log[0].sha

    FileUtils.mkdir(@main_working_tree_path)
    g = Git.init(@main_working_tree_path)
    File.write(File.join(@main_working_tree_path, 'README.md'), '# Main Repository')
    g.add('README.md')
    g.commit('Initial commit')
    Dir.chdir @main_working_tree_path do
      `git submodule -q add #{@submodule_working_tree_path}/.git my_submodule`
      assert_true($CHILD_STATUS.success?)
    end
    @main_head = g.log[0].sha

    assert_not_equal(@submodule_head, @main_head)
  end

  def teardown
    FileUtils.rm_rf(@temp_dir)
  end

  def test_open_in_current_directory
    Dir.chdir File.join(@main_working_tree_path, @submodule_path_in_main) do
      g = Git.open('.')
      assert_equal(@submodule_head, g.log[0].sha)
    end
  end

  def test_not_in_current_directory
    working_tree_directory = File.join(@main_working_tree_path, @submodule_path_in_main)
    g = Git.open(working_tree_directory)
    assert_equal(@submodule_head, g.log[0].sha)
  end
end
