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
      r1.config('user.name', 'Test User')
      r1.config('user.email', 'test@email.com')
      r2.config('user.name', 'Test User')
      r2.config('user.email', 'test@email.com')
        
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
      
      assert(r1.tags.any?{|t| t.name == 'first'})
      
      r2.add_tag('third')
      
      assert(r2.tags.any?{|t| t.name == 'third'})
      assert(r2.tags.none?{|t| t.name == 'second'})
      
      assert_raise RuntimeError do
        r2.add_tag('fourth', {:a => true})
      end
        
      r2.add_tag('fourth', {:a => true, :m => 'test message'})

      assert(r2.tags.any?{|t| t.name == 'fourth'})
      
      r2.add_tag('fifth', r2.tags.detect{|t| t.name == 'third'}.objectish)

      assert(r2.tags.detect{|t| t.name == 'third'}.objectish == r2.tags.detect{|t| t.name == 'fifth'}.objectish)

      assert_raise Git::GitExecuteError do
        r2.add_tag('third')
      end

      r2.add_tag('third', {:f => true})
      
      r2.delete_tag('third')
      
      assert_raise Git::GitTagNameDoesNotExist do
        r2.tag('third')
      end

      tag1 = r2.tag('fourth')
      assert_true(tag1.annotated?)
      assert_equal(tag1.tagger.class, Git::Author)
      assert_equal(tag1.tagger.name, 'Test User')
      assert_equal(tag1.tagger.email, 'test@email.com')
      assert_true((Time.now - tag1.tagger.date) <  10)
      assert_equal(tag1.message, ' test message')
      
      tag2 = r2.tag('fifth')
      assert_false(tag2.annotated?)
      assert_equal(tag2.tagger, nil)
      assert_equal(tag2.message, nil)
    end
  end
end
