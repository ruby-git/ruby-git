# frozen_string_literal: true

require 'test_helper'

class TestDescribe < Test::Unit::TestCase
  def setup
    clone_working_repo
    @git = Git.open(@wdir)
  end

  def test_describe
    assert_equal(@git.describe(nil, { tags: true }), 'grep_colon_numbers')
  end

  def test_describe_with_invalid_commitish
    assert_raise ArgumentError do
      @git.describe('--all')
    end
  end
end
