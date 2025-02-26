# frozen_string_literal: true

require 'test_helper'

class TestCommitWithEmptyMessage < Test::Unit::TestCase
  def setup
    clone_working_repo
  end

  def test_without_allow_empty_message_option
    Dir.mktmpdir do |dir|
      git = Git.init(dir)
      assert_raises Git::FailedError do
        git.commit('', { allow_empty: true })
      end
    end
  end

  def test_with_allow_empty_message_option
    Dir.mktmpdir do |dir|
      git = Git.init(dir)
      git.commit('', { allow_empty: true, allow_empty_message: true})
      assert_equal(1, git.log.to_a.size)
    end
  end
end
