#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../test_helper'

class TestCommit < Test::Unit::TestCase

  def setup
    set_file_paths
  end

  def test_add
    in_temp_dir do |path|
      git = Git.clone(@wdir, 'test_commit')

      create_file('test_commit/test_file_1', 'content tets_file_1')
      git.add('test_file_1')

      git.commit('test_add commit #1')

      head = git.log[0]
      assert(head.message == 'test_add commit #1')
      assert(head.author.name == head.committer.name)
      assert(head.author.email == head.committer.email)
      assert(head.author.date == head.committer.date)

      update_file('test_commit/test_file_1', 'new content')
      git.commit('commit #2', all: true)

      previous = head
      head = git.log[0]

      assert(head.message == 'commit #2')
      assert(head.parent.sha == previous.sha)

      update_file('test_commit/test_file_1', 'other content')
      git.add('test_file_1')

      author_date = Time.new(2016, 8, 3, 17, 37, 0, "-03:00")
      new_author = "#{head.author.name} Other <#{head.author.email}.tld>"

      git.commit('commit #3', date: author_date.strftime('%Y-%m-%dT%H:%M:%S %z'), author: new_author)

      previous = head
      head = git.log[0]

      assert(head.author.name != head.committer.name)
      assert(head.author.email != head.committer.email)
      assert(head.author.date != head.committer.date)
      assert(head.author.date == author_date)
    end
  end

end
