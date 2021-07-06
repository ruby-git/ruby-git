#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../test_helper'

class TestCommitWithGPG < Test::Unit::TestCase
  def setup
    set_file_paths
  end

  def test_with_configured_gpg_keyid
    Dir.mktmpdir do |dir|
      git = Git.init(dir)
      actual_cmd = nil
      git.lib.define_singleton_method(:run_command) do |git_cmd, &block|
        actual_cmd = git_cmd
        `true`
      end
      message = 'My commit message'
      git.commit(message, gpg_sign: true)
      assert_match(/commit.*--gpg-sign['"]/, actual_cmd)
    end
  end

  def test_with_specific_gpg_keyid
    Dir.mktmpdir do |dir|
      git = Git.init(dir)
      actual_cmd = nil
      git.lib.define_singleton_method(:run_command) do |git_cmd, &block|
        actual_cmd = git_cmd
        `true`
      end
      message = 'My commit message'
      git.commit(message, gpg_sign: 'keykeykey')
      assert_match(/commit.*--gpg-sign=keykeykey['"]/, actual_cmd)
    end
  end
end
