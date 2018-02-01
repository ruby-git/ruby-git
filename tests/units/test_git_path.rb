#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../test_helper'

class TestGitPath < Test::Unit::TestCase
  
  def setup
    set_file_paths
    @git = Git.open(@wdir)
  end
  
  def test_initalize_with_good_path_and_check_path
    path = Git::Path.new(@git.index.to_s, true)
    assert_equal @git.index.to_s, path.to_s
  end
  
  def test_initialize_with_bad_path_and_check_path
    assert_raises ArgumentError do
      Git::Path.new('/this path does not exist', true)
    end
  end
  
  def test_initialize_with_bad_path_and_no_check
    path = Git::Path.new('/this path does not exist', false)
    assert_equal '/this path does not exist', path.to_s
  end

  def test_readables
    assert(@git.dir.readable?)
    assert(@git.index.readable?)
    assert(@git.repo.readable?)
  end
  
  def test_readables_in_temp_dir
    in_temp_dir do |dir|
      FileUtils.cp_r(@wdir, 'test')
      g = Git.open(File.join(dir, 'test'))
      
      assert(g.dir.writable?)
      assert(g.index.writable?)
      assert(g.repo.writable?)
    end
  end
  
end