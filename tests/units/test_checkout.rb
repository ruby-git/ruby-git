require 'test_helper'

    # Runs checkout command to checkout or create branch
    #
    # accepts options:
    #  :new_branch
    #  :force
    #  :start_point
    #
    # @param [String] branch
    # @param [Hash] opts
    # def checkout(branch, opts = {})

class TestCheckout < Test::Unit::TestCase
  test 'checkout with no args' do
    expected_command_line = ['checkout']
    git_cmd = :checkout
    git_cmd_args = []
    assert_command_line(expected_command_line, git_cmd, git_cmd_args)
  end

  test 'checkout with no args and options' do
    expected_command_line = ['checkout', '--force']
    git_cmd = :checkout
    git_cmd_args = [force: true]
    assert_command_line(expected_command_line, git_cmd, git_cmd_args)
  end

  test 'checkout with branch' do
    expected_command_line = ['checkout', 'feature1']
    git_cmd = :checkout
    git_cmd_args = ['feature1']
    assert_command_line(expected_command_line, git_cmd, git_cmd_args)
  end

  test 'checkout with branch and options' do
    expected_command_line = ['checkout', '--force', 'feature1']
    git_cmd = :checkout
    git_cmd_args = ['feature1', force: true]
    assert_command_line(expected_command_line, git_cmd, git_cmd_args)
  end

  test 'checkout with branch name and new_branch: true' do
    expected_command_line = ['checkout', '-b', 'feature1']
    git_cmd = :checkout
    git_cmd_args = ['feature1', new_branch: true]
    assert_command_line(expected_command_line, git_cmd, git_cmd_args)
  end

  test 'checkout with force: true' do
    expected_command_line = ['checkout', '--force', 'feature1']
    git_cmd = :checkout
    git_cmd_args = ['feature1', force: true]
    assert_command_line(expected_command_line, git_cmd, git_cmd_args)
  end

  test 'checkout with branch name and new_branch: true and start_point: "sha"' do
    expected_command_line = ['checkout', '-b', 'feature1', 'sha']
    git_cmd = :checkout
    git_cmd_args = ['feature1', new_branch: true, start_point: 'sha']
    assert_command_line(expected_command_line, git_cmd, git_cmd_args)
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
end
