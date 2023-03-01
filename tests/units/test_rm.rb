#!/usr/bin/env ruby

require 'test_helper'

# tests all the low level git communication
#
# this will be helpful if we ever figure out how
# to either build these in pure ruby or get git bindings working
# because right now it forks for every call

class TestRm < Test::Unit::TestCase
  test 'rm with no options should specific "." for the pathspec' do
    expected_command_line = ['rm', '-f', '--', '.']
    git_cmd = :rm
    git_cmd_args = []
    assert_command_line(expected_command_line, git_cmd, git_cmd_args)
  end

  test 'rm with one pathspec' do
    expected_command_line = ['rm', '-f', '--', 'pathspec']
    git_cmd = :rm
    git_cmd_args = ['pathspec']
    assert_command_line(expected_command_line, git_cmd, git_cmd_args)
  end

  test 'rm with multiple pathspecs' do
    expected_command_line = ['rm', '-f', '--', 'pathspec1', 'pathspec2']
    git_cmd = :rm
    git_cmd_args = [['pathspec1', 'pathspec2']]
    assert_command_line(expected_command_line, git_cmd, git_cmd_args)
  end

  test 'rm with the recursive option' do
    expected_command_line = ['rm', '-f', '-r', '--', 'pathspec']
    git_cmd = :rm
    git_cmd_args = ['pathspec', recursive: true]
    assert_command_line(expected_command_line, git_cmd, git_cmd_args)
  end

  test 'rm with the cached option' do
    expected_command_line = ['rm', '-f', '--cached', '--', 'pathspec']
    git_cmd = :rm
    git_cmd_args = ['pathspec', cached: true]
    assert_command_line(expected_command_line, git_cmd, git_cmd_args)
  end

  test 'when rm succeeds an error should not be raised' do
    in_temp_dir do
      git = Git.init
      File.write('README.txt', 'hello world')
      git.add('README.txt')
      git.commit('Initial commit')

      assert(File.exist?('README.txt'))

      assert_nothing_raised do
        git.rm('README.txt')
      end

      assert(!File.exist?('README.txt'))
    end
  end

  test 'when rm fails a Git::FailedError error should be raised' do
    in_temp_dir do
      git = Git.init
      File.write('README.txt', 'hello world')
      git.add('README.txt')
      git.commit('Initial commit')

      assert_raises(Git::FailedError) do
        git.rm('Bogus.txt')
      end
    end
  end
end
