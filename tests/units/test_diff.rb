#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../test_helper'

class TestDiff < Test::Unit::TestCase
  def setup
    set_file_paths
    @git = Git.open(@wdir)
  end
  
  def test_diff
  end
  
  def test_diff_summary
  end
  
  def test_diff_stat
  end
  
  def test_diff_shortstat
  end
  
  def test_patch
  end
  
  def test_unified
  end
  
end