#!/usr/bin/env ruby
require 'logger'
require File.dirname(__FILE__) + '/../test_helper'

class TestLog < Test::Unit::TestCase
  def setup
    set_file_paths
    #@git = Git.open(@wdir, :log => Logger.new(STDOUT))
    @git = Git.open(@wdir)
  end

  def test_get_first_and_last_entries
    log = @git.log
    assert(log.first.is_a?(Git::Object::Commit))
    assert_equal('9641f3383a015620ffd40591a4d7ec9ef07697d6', log.first.objectish)

    assert(log.last.is_a?(Git::Object::Commit))
    assert_equal('b03003311ad3fa368b475df58390353868e13c91', log.last.objectish)
  end
  
  def test_get_log_entries    
    assert_equal(30, @git.log.size)
    assert_equal(50, @git.log(50).size)
    assert_equal(10, @git.log(10).size)
  end

  def test_get_log_to_s
    assert_equal(@git.log.to_s.split("\n").first, @git.log.first.sha)
  end

  def test_log_skip
    three1 = @git.log(3).to_a[-1]
    three2 = @git.log(2).skip(1).to_a[-1]
    three3 = @git.log(1).skip(2).to_a[-1]
    assert_equal(three2.sha, three3.sha)
    assert_equal(three1.sha, three2.sha)
  end
  
  def test_get_log_since
    l = @git.log.since("2 seconds ago")
    assert_equal(0, l.size)
    
    l = @git.log.since("#{Date.today.year - 2006} years ago")
    assert_equal(30, l.size)
  end
  
  def test_get_log_grep
    l = @git.log.grep("search")
    assert_equal(2, l.size)
  end

  def test_get_log_author
    l = @git.log(5).author("chacon")
    assert_equal(5, l.size)
    l = @git.log(5).author("lazySusan")
    assert_equal(0, l.size)
  end
  
  def test_get_log_since_file    
    l = @git.log.path('example.txt')
    assert_equal(30, l.size)
  
    l = @git.log.between('v2.5', 'test').path('example.txt')
    assert_equal(1, l.size)
  end

  def test_get_log_path
    log = @git.log.path('example.txt')
    assert_equal(30, log.size)
    log = @git.log.path('example*')
    assert_equal(30, log.size)
    log = @git.log.path(['example.txt','scott/text.txt'])
    assert_equal(30, log.size)
  end
  
  def test_log_file_noexist
    assert_raise Git::GitExecuteError do
      @git.log.object('no-exist.txt').size
    end
  end

  def test_log_with_empty_commit_message
    Dir.mktmpdir do |dir|
      git = Git.init(dir)
      expected_message = 'message'
      git.commit(expected_message, { allow_empty: true })
      git.commit('', { allow_empty: true, allow_empty_message: true })
      log = git.log
      assert_equal(2, log.to_a.size)
      assert_equal('', log[0].message)
      assert_equal(expected_message, log[1].message)
    end
  end
end
