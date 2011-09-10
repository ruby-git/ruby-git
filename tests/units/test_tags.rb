#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../test_helper'

class TestTags < Test::Unit::TestCase
  def setup
    set_file_paths
  end

  def test_unannotated_tags
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
      tag = r1.add_tag('second')

      assert(!tag.commit?)
      assert(tag.tag?)
      assert(!tag.annotated?)

      assert(r1.tags.map{|t| t.name}.include?('first'))

      r2.add_tag('third')

      assert(r2.tags.map{|t| t.name}.include?('third'))
      assert(!r2.tags.map{|t| t.name}.include?('second'))
    end
  end

  def test_annotated_tags
    in_temp_dir do |path|
      g = Git.clone(@wbare, 'bare')
      g.config('user.name', 'Lawrence Pit')
      g.config('user.email', 'lawrence.pit@example.com')
      
      g.chdir { new_file('new_file', 'new content') }
      g.add
      g.commit('first commit')
      t1 = g.add_tag('v3.0', "FirstMessage")

      g.chdir { new_file('new_file2', 'new content2') }
      g.add
      g.commit('second commit')
      g.add_tag('v3.1', "Second message\nSecond line")

      assert(!t1.commit?)
      assert(t1.tag?)
      assert(t1.annotated?)
      assert_equal('Lawrence Pit', t1.tagger.name)
      assert_equal('lawrence.pit@example.com', t1.tagger.email)
      assert_equal(Time.now.strftime("%m-%d-%y"), t1.tagger.date.strftime("%m-%d-%y"))
      assert_equal('FirstMessage', t1.message)

      t2 = g.tag('v3.1')
      assert_equal('Lawrence Pit', t2.tagger.name)
      assert_equal('lawrence.pit@example.com', t2.tagger.email)
      assert_equal(Time.now.strftime("%m-%d-%y"), t2.tagger.date.strftime("%m-%d-%y"))
      assert_equal("Second message\nSecond line", t2.message)
    end
  end

end