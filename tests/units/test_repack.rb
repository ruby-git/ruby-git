#!/usr/bin/env ruby

require 'test_helper'

class TestRepack < Test::Unit::TestCase
  test 'should be able to call repack with the right args' do
    in_bare_repo_clone do |r1|
      new_file('new_file', 'new content')
      r1.add
      r1.commit('my commit')

      # assert_nothing_raised { r1.repack }

      expected_command_line = ['repack', '-a', '-d']
      git_cmd = :repack
      git_cmd_args = []
      assert_command_line(expected_command_line, git_cmd, git_cmd_args)
    end
  end
end
