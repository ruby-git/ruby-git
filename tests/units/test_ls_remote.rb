#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../test_helper'

class TestRemoteLs < Test::Unit::TestCase
  def setup
    set_file_paths
  end

  def test_remote_ls_tags
    in_temp_dir do |path|
      r1 = Git.clone(@wbare, 'repo1')
      r2 = Git.clone(@wbare, 'repo2')

      # setup
      r1.add_remote('r2', r2)
      r1.add_tag('foo_bar_baz')

      tags = r1.ls_remote('r2', {:tags => true})
      tags.each { |t|
        assert_false t.has_value? 'foo_bar_baz'
      }

      r1.push('origin', 'master', {:tags => true})
      r1.push('r2', 'master', {:tags => true})
      tags = r1.ls_remote('r2', {:tags => true})

      found = false
      tags.each { |t|
        if t.has_value? 'foo_bar_baz'
          found = true
        end
      }
      assert found === true
    end
  end
end
