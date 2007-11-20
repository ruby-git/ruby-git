#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../test_helper'

class TestRawInternals < Test::Unit::TestCase
  
  def setup
    set_file_paths
    @git = Git.open(@wdir)
  end
  
  def test_raw_log
  end

end