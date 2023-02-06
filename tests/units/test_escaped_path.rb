#!/usr/bin/env ruby
# frozen_string_literal: true

require 'test_helper'

# Test diff when the file path has escapes according to core.quotePath
# See https://git-scm.com/docs/git-config#Documentation/git-config.txt-corequotePath
# See https://www.jvt.me/posts/2020/06/23/byte-array-to-string-ruby/
# See https://stackoverflow.com/questions/54788845/how-can-i-convert-a-guid-into-a-byte-array-in-ruby
#
class TestEscapedPath < Test::Unit::TestCase
  def test_simple_path
    path = 'my_other_file'
    expected_unescaped_path = 'my_other_file'
    assert_equal(expected_unescaped_path, Git::EscapedPath.new(path).unescape)
  end

  def test_unicode_path
    path = 'my_other_file_\\342\\230\\240'
    expected_unescaped_path = 'my_other_file_☠'
    assert_equal(expected_unescaped_path, Git::EscapedPath.new(path).unescape)
  end

  def test_unicode_path2
    path = 'test\320\2411991923'
    expected_unescaped_path = 'testС1991923'
    assert_equal(expected_unescaped_path, Git::EscapedPath.new(path).unescape)
  end

  def test_single_char_escapes
    Git::EscapedPath::UNESCAPES.each_pair do |escape_char, expected_char|
      path = "\\#{escape_char}"
      assert_equal(expected_char.chr, Git::EscapedPath.new(path).unescape)
    end
  end

  def test_compound_escape
    path = 'my_other_file_"\\342\\230\\240\\n"'
    expected_unescaped_path = "my_other_file_\"☠\n\""
    assert_equal(expected_unescaped_path, Git::EscapedPath.new(path).unescape)
  end
end
