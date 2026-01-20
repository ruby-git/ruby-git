# frozen_string_literal: true

require 'test_helper'

# tests all the low level git communication
#
# this will be helpful if we ever figure out how
# to either build these in pure ruby or get git bindings working
# because right now it forks for every call

class TestRm < Test::Unit::TestCase
  test 'rm with no options should specify "." for the pathspec' do
    expected_command_line = ['rm', '--', '.', {}]
    assert_command_line_eq(expected_command_line, &:rm)
  end

  test 'rm with one pathspec' do
    expected_command_line = ['rm', '--', 'pathspec', {}]
    assert_command_line_eq(expected_command_line) { |git| git.rm('pathspec') }
  end

  test 'rm with multiple pathspecs' do
    expected_command_line = ['rm', '--', 'pathspec1', 'pathspec2', {}]
    assert_command_line_eq(expected_command_line) { |git| git.rm(%w[pathspec1 pathspec2]) }
  end

  test 'rm with the force option' do
    expected_command_line = ['rm', '-f', '--', 'pathspec', {}]
    assert_command_line_eq(expected_command_line) { |git| git.rm('pathspec', force: true) }
  end

  test 'rm with the recursive option' do
    expected_command_line = ['rm', '-r', '--', 'pathspec', {}]
    assert_command_line_eq(expected_command_line) { |git| git.rm('pathspec', recursive: true) }
  end

  test 'rm with the cached option' do
    expected_command_line = ['rm', '--cached', '--', 'pathspec', {}]
    assert_command_line_eq(expected_command_line) { |git| git.rm('pathspec', cached: true) }
  end

  test 'when rm succeeds an error should not be raised' do
    in_temp_dir do
      git = Git.init
      File.write('README.txt', 'hello world')
      git.add('README.txt')
      git.commit('Initial commit')

      assert(File.exist?('README.txt'))

      assert_nothing_raised do
        git.rm('README.txt', force: true)
      end

      assert(!File.exist?('README.txt'))
    end
  end

  test '#rm should be aliased to #remove' do
    in_temp_dir do
      git = Git.init
      File.write('README.txt', 'hello world')
      git.add('README.txt')
      git.commit('Initial commit')

      assert(File.exist?('README.txt'))

      assert_nothing_raised do
        git.remove('README.txt', force: true)
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
