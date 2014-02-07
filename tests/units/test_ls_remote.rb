#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../test_helper'

class TestRemoteLs < Test::Unit::TestCase
  def setup
    set_file_paths
  end

  def test_remote_ls
    file_name = "test_remote_ls_tags.file"
    in_temp_dir do |path|
      r1 = Git.clone(@wbare, 'repo1')
      r2 = Git.init('repo2', :bare => true)

      # setup
      r1.add_remote('r2', r2)
      create_file('repo1/' + file_name, 'content tets_file_1')
      r1.add(file_name)
      r1.commit_all('test_add/test_remote_ls_tags')
      r1.push('origin', 'master')
      r1.push('r2', 'master')

      # add a second file
      file_name += '2'
      create_file('repo1/' + file_name, 'content tets_file_1')
      r1.add(file_name)
      r1.commit_all('test_add/test_remote_ls_tags')
      r1.push('origin', 'master')

      # this is the sha for the second commit
      test_file_sha = r1.log(1)[0].sha

      refs = r1.ls_remote('r2')
      refs.each { |r|
        assert_false r.has_value? test_file_sha
      }

      r1.push('r2', 'master')
      refs = r1.ls_remote('r2')

      found = false
      refs.each { |r|
        # the r2 HEAD must point at the local sha captured
        if r[:ref] == "HEAD"
          assert_equal test_file_sha, r[:sha]
          found = true
        end
      }
      assert (found === true), "Expected sha was not found in remote!"
    end
  end

  def test_remote_ls_tags
    in_temp_dir do |path|
      r1 = Git.clone(@wbare, 'repo1')
      r2 = Git.init('repo2', :bare => true)

      # setup
      tag_name = 'foo_bar_bazz'
      r1.add_remote('r2', r2)
      r1.add_tag(tag_name)
      test_sha = r1.log(1)[0].sha

      tags = r1.ls_remote('r2', {:tags => true})
      tags.each { |t|
        assert_false t.has_value? tag_name
      }

      r1.push('origin', 'master', {:tags => true})
      r1.push('r2', 'master', {:tags => true})
      tags = r1.ls_remote('r2', {:tags => true})

      found = false
      tags.each { |t|
        if t[:sha] == test_sha
          assert_equal t[:name], tag_name
          assert_equal t[:tag_ref], "refs/tags/#{tag_name}"
          found = true
        end
      }
      assert (found === true), "Tag was not found in remote!"
    end
  end
end
