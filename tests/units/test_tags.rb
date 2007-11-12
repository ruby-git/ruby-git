#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../test_helper'

class TestTags < Test::Unit::TestCase
  def setup
    set_file_paths
  end
  
  def test_tags
    in_temp_dir do |path|
      r1 = Git.clone(@wbare, 'repo1')
      r2 = Git.clone(@wbare, 'repo2')
        
      assert_raise Git::GitTagNameDoesNotExist do
        r1.tag('first')
      end
      
      r1.add_tag('first')
      r1.chdir do 
        new_file('new_file', 'new content')
      end
      r1.add
      r1.commit('my commit')
      r1.add_tag('second')
      
      assert(r1.tags.map{|t| t.name}.include?('first'))
      
      r2.add_tag('third')
      
      assert(r2.tags.map{|t| t.name}.include?('third'))
      assert(!r2.tags.map{|t| t.name}.include?('second'))
    end
  end
end