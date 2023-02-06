#!/usr/bin/env ruby

require 'test_helper'

class TestShow < Test::Unit::TestCase
  def test_do_not_chomp_contents
    in_temp_dir do
      file_name = 'README.md'
      expected_contents = "hello\nworld\n\n"

      g = Git.init
      g.commit('Initial commit', allow_empty: true)
      new_file(file_name, expected_contents)
      g.add(file_name)
      # Show the file from the index by prefixing the file namne with a colon
      contents = g.show(":#{file_name}")
      assert_equal(expected_contents, contents)
    end
  end
end
