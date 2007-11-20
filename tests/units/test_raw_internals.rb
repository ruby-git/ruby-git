#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../test_helper'

class TestRawInternals < Test::Unit::TestCase
  
  def setup
    set_file_paths
  end
  
  def test_raw_log
    g = Git.bare(@wbare)
    #g.repack
    
    c = g.object("HEAD")
    puts sha = c.sha
    
    repo = Git::Raw::Repository.new(@wbare)
    while sha do
      o = repo.get_raw_object_by_sha1(sha)
      c = Git::Raw::Object.from_raw(o)
    
      sha = c.parent.first
      puts sha
    end
    
    g.log(60).each do |c|
      puts c.sha
    end
  
    puts c.inspect
    
  end

end