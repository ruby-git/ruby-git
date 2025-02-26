# frozen_string_literal: true

require 'test_helper'

class TestCommitWithGPG < Test::Unit::TestCase
  def setup
    clone_working_repo
  end

  def test_with_configured_gpg_keyid
    message = 'My commit message'
    expected_command_line = ["commit", "--message=#{message}", "--gpg-sign", {}]
    assert_command_line_eq(expected_command_line) { |g| g.commit(message, gpg_sign: true) }
  end

  def test_with_specific_gpg_keyid
    message = 'My commit message'
    key = 'keykeykey'
    expected_command_line = ["commit", "--message=#{message}", "--gpg-sign=#{key}", {}]
    assert_command_line_eq(expected_command_line) { |g| g.commit(message, gpg_sign: key) }
  end

  def test_disabling_gpg_sign
    message = 'My commit message'
    expected_command_line = ["commit", "--message=#{message}", "--no-gpg-sign", {}]
    assert_command_line_eq(expected_command_line) { |g| g.commit(message, no_gpg_sign: true) }
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
