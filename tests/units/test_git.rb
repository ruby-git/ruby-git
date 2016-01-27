#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../test_helper'

# tests all the low level git communication
#
# this will be helpful if we ever figure out how
# to either build these in pure ruby or get git bindings working
# because right now it forks for every call

class TestGit < Test::Unit::TestCase
  def setup
    set_file_paths
  end
  def test_get_branch
    Git.get_branch( 'https://github.com/onetwotrip/ruby-git.git' )
    assert_equal(Git.get_branch( 'https://github.com/onetwotrip/ruby-git.git' ).index.path,
                 Git.get('onetwotrip/ruby-git.git',
                         'https://github.com/onetwotrip/ruby-git.git',
                         ).index.path)
  end
end
