#!/usr/bin/env ruby

require 'test_helper'

class TestRepack < Test::Unit::TestCase
  test 'should be able to call repack with the right args' do
    expected_command_line = ['repack', '-a', '-d', {}]
    assert_command_line_eq(expected_command_line) { |git| git.repack }
  end
end
