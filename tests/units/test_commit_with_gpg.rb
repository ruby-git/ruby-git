#!/usr/bin/env ruby

require 'test_helper'

class TestCommitWithGPG < Test::Unit::TestCase
  def setup
    clone_working_repo
  end

  def test_with_configured_gpg_keyid
    Dir.mktmpdir do |dir|
      git = Git.init(dir)
      actual_opts = nil
      git.lib.define_singleton_method(:command) do |cmd, *opts, &block|
        actual_opts = opts.flatten
        ''
      end
      message = 'My commit message'
      git.commit(message, gpg_sign: true)
      assert(actual_opts.include?('--gpg-sign'))
    end
  end

  def test_with_specific_gpg_keyid
    Dir.mktmpdir do |dir|
      git = Git.init(dir)
      actual_opts = nil
      git.lib.define_singleton_method(:command) do |cmd, *opts, &block|
        actual_opts = opts.flatten
        ''
      end
      message = 'My commit message'
      git.commit(message, gpg_sign: 'keykeykey')
      assert(actual_opts.include?('--gpg-sign=keykeykey'))
    end
  end

  def test_disabling_gpg_sign
    Dir.mktmpdir do |dir|
      git = Git.init(dir)
      actual_opts = nil
      git.lib.define_singleton_method(:command) do |cmd, *opts, &block|
        actual_opts = opts.flatten
        ''
      end
      message = 'My commit message'
      git.commit(message, no_gpg_sign: true)
      assert(actual_opts.include?('--no-gpg-sign'))
    end
  end

  def test_conflicting_gpg_sign_options
    Dir.mktmpdir do |dir|
      git = Git.init(dir)
      message = 'My commit message'

      assert_raises ArgumentError do
        git.commit(message, gpg_sign: true, no_gpg_sign: true)
      end
    end
  end
end
