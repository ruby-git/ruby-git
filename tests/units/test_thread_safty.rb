#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../test_helper'

class TestThreadSafety < Test::Unit::TestCase
  def setup
    set_file_paths
  end

  def test_git_init_bare
    dirs = []
    threads = []
    
    5.times do 
      dirs << Dir.mktmpdir
    end
    
    dirs.each do |dir|
      threads << Thread.new do
        Git.init(dir, :bare => true)
      end
    end

    threads.each {|thread| thread.join}

    dirs.each do |dir|
      Git.bare("#{dir}/.git").ls_files
    end
  end
end
