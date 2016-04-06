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
  def test_get_branch_is_GitBase
    in_temp_dir do |path|
      # Get branch should Git::Base
      repo = Git.get_branch('https://github.com/onetwotrip/ruby-git.git')
      assert_equal(repo.class, Git::Base)
      # Get branch should Git::Base
      repo = Git.get_branch('https://github.com/onetwotrip/ruby-git.git/branch/develop')
      assert_equal(repo.class, Git::Base)
    end
  end
  def test_get_branch_master_to_branch
    in_temp_dir do |path|
      # Get branch should checkout to default (master) branch
      repo = Git.get_branch('https://github.com/onetwotrip/ruby-git.git')
      assert_equal(repo.current_branch, 'master')
      # Get branch should checkout to develop branch
      repo = Git.get_branch('https://github.com/onetwotrip/ruby-git.git/branch/develop')
      assert_equal(repo.current_branch, 'develop')
    end
  end
  def test_get_branch_branch_to_master
    in_temp_dir do |path|
      # Get branch should checkout to develop branch
      repo = Git.get_branch('https://github.com/onetwotrip/ruby-git.git/branch/develop')
      assert_equal(repo.current_branch, 'develop')
      # Get branch should checkout to default (master) branch
      repo = Git.get_branch('https://github.com/onetwotrip/ruby-git.git')
      assert_equal(repo.current_branch, 'master')
    end
  end
  def test_get_branch_after_merge
    in_temp_dir do |path|
      repo = Git.get_branch('https://github.com/onetwotrip/ruby-git.git/branch/develop')
      develop_sha = repo.log.first.sha
      repo = Git.get_branch('https://github.com/onetwotrip/ruby-git.git')
      master_sha = repo.log.first.sha
      repo.merge 'origin/develop'
      # Check merge cleanup
      repo = Git.get_branch('https://github.com/onetwotrip/ruby-git.git')
      assert_equal(master_sha, repo.log.first.sha)
    end
  end
end
