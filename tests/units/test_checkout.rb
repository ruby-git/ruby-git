require 'test_helper'

class TestCheckout < Test::Unit::TestCase
  test 'checkout with no args' do
    expected_command_line = ['checkout', {}]
    assert_command_line_eq(expected_command_line) { |git| git.checkout }
  end

  test 'checkout with no args and options' do
    expected_command_line = ['checkout', '--force', {}]
    assert_command_line_eq(expected_command_line) { |git| git.checkout(force: true) }
  end

  test 'checkout with branch' do
    expected_command_line = ['checkout', 'feature1', {}]
    assert_command_line_eq(expected_command_line) { |git| git.checkout('feature1') }
  end

  test 'checkout with branch and options' do
    expected_command_line = ['checkout', '--force', 'feature1', {}]
    assert_command_line_eq(expected_command_line) { |git| git.checkout('feature1', force: true) }
  end

  test 'checkout with branch name and new_branch: true' do
    expected_command_line = ['checkout', '-b', 'feature1', {}]
    assert_command_line_eq(expected_command_line) { |git| git.checkout('feature1', new_branch: true) }
  end

  test 'checkout with force: true' do
    expected_command_line = ['checkout', '--force', 'feature1', {}]
    assert_command_line_eq(expected_command_line) { |git| git.checkout('feature1', force: true) }
  end

  test 'checkout with branch name and new_branch: true and start_point: "sha"' do
    expected_command_line = ['checkout', '-b', 'feature1', 'sha', {}]
    assert_command_line_eq(expected_command_line) { |git| git.checkout('feature1', new_branch: true, start_point: 'sha') }
  end

  test 'when checkout succeeds an error should not be raised' do
    in_temp_dir do
      git = Git.init('.', initial_branch: 'master')
      File.write('file1.txt', 'file1')
      git.add('file1.txt')
      git.commit('commit1')
      assert_nothing_raised { git.checkout('master') }
    end
  end

  test 'when checkout fails a Git::FailedError should be raised' do
    in_temp_dir do
      git = Git.init('.', initial_branch: 'master')
      # fails because there are no commits
      assert_raises(Git::FailedError) { git.checkout('master') }
    end
  end

  test 'checking out to a branch whose name contains slashes' do
    in_temp_dir do
      git = Git.init('.', initial_branch: 'master')

      File.write('file1.txt', 'file1')
      git.add('file1.txt')
      git.commit('commit1')

      assert_nothing_raised { git.branch('foo/a_new_branch').checkout }

      assert_equal('foo/a_new_branch', git.current_branch)
    end
  end
end
