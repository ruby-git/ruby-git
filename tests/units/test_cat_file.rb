# frozen_string_literal: true

require 'test_helper'

class TestCatFile < Test::Unit::TestCase
  def setup
    clone_working_repo
    @git = Git.open(@wdir)
  end

  def test_cat_file_commit
    result = @git.cat_file('1cc8667014381')
    assert_match(/^tree 94c827875e2cadb8bc8d4cdd900f19aa9e8634c7$/, result)
    assert_match(/^author scott Chacon/, result)
    assert_match(/test\z/, result)
  end

  def test_cat_file_tree
    result = @git.cat_file('1cc8667014381^{tree}')
    assert_match(/ex_dir/, result)
    assert_match(/example\.txt/, result)
  end

  def test_cat_file_blob
    result = @git.cat_file('v2.5:example.txt')
    assert_equal("1\n1\n#{"1\n" * 61}2", result)
  end

  def test_cat_file_by_tag
    result = @git.cat_file('v2.5')
    assert_match(/^tree /, result)
  end
end
