#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../test_helper'

class TestGitPath < Test::Unit::TestCase
  
  def setup
    set_file_paths
    @git = Git.open(@wdir)
  end

  def test_readables
    assert(@git.dir.readable?)
    assert(@git.index.readable?)
    assert(@git.repo.readable?)
  end
  
  def test_readables
    in_temp_dir do |dir|
      FileUtils.cp_r(@wdir, 'test')
      g = Git.open(File.join(dir, 'test'))
      
      assert(g.dir.writable?)
      assert(g.index.writable?)
      assert(g.repo.writable?)
    end
  end
  
end