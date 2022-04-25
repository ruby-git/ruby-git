# frozen_string_literal: true

require 'test/unit'
require_relative '../test_helper'

# Tests for Git.clone
class TestGitClone < Test::Unit::TestCase
  def setup_repo
    Git.init('repository.git', bare: true)
    git = Git.clone('repository.git', 'temp')
    File.write('temp/test.txt', 'test')
    git.add('test.txt')
    git.commit('Initial commit')
  end

  def test_git_clone_with_name
    in_temp_dir do |path|
      setup_repo
      clone_dir = 'clone_to_this_dir'
      git = Git.clone('repository.git', clone_dir)
      assert(Dir.exist?(clone_dir))
      expected_dir = File.realpath(clone_dir)
      assert_equal(expected_dir, git.dir.to_s)
    end
  end

  def test_git_clone_with_no_name
    in_temp_dir do |path|
      setup_repo
      git = Git.clone('repository.git')
      assert(Dir.exist?('repository'))
      expected_dir = File.realpath('repository')
      assert_equal(expected_dir, git.dir.to_s)
    end
  end
end
