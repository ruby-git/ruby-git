require 'test_helper'

class TestPush < Test::Unit::TestCase
  test 'push with no args' do
    expected_command_line = ['push']
    git_cmd = :push
    git_cmd_args = []
    assert_command_line(expected_command_line, git_cmd, git_cmd_args)
  end

  test 'push with no args and options' do
    expected_command_line = ['push', '--force']
    git_cmd = :push
    git_cmd_args = [force: true]
    assert_command_line(expected_command_line, git_cmd, git_cmd_args)
  end

  test 'push with only a remote name' do
    expected_command_line = ['push', 'origin']
    git_cmd = :push
    git_cmd_args = ['origin']
    assert_command_line(expected_command_line, git_cmd, git_cmd_args)
  end

  test 'push with a single push option' do
    expected_command_line = ['push', '--push-option', 'foo']
    git_cmd = :push
    git_cmd_args = [push_option: 'foo']
    assert_command_line(expected_command_line, git_cmd, git_cmd_args)
  end

  test 'push with an array of push options' do
    expected_command_line = ['push', '--push-option', 'foo', '--push-option', 'bar', '--push-option', 'baz']
    git_cmd = :push
    git_cmd_args = [push_option: ['foo', 'bar', 'baz']]
    assert_command_line(expected_command_line, git_cmd, git_cmd_args)
  end

  test 'push with only a remote name and options' do
    expected_command_line = ['push', '--force', 'origin']
    git_cmd = :push
    git_cmd_args = ['origin', force: true]
    assert_command_line(expected_command_line, git_cmd, git_cmd_args)
  end

  test 'push with only a branch name' do
    expected_command_line = ['push', 'master']
    git_cmd = :push
    git_cmd_args = [nil, 'origin']

    in_temp_dir do
      git = Git.init('.', initial_branch: 'master')
      assert_raises(ArgumentError) { git.push(nil, 'master') }
    end
  end

  test 'push with both remote and branch name' do
    expected_command_line = ['push', 'origin', 'master']
    git_cmd = :push
    git_cmd_args = ['origin', 'master']
    assert_command_line(expected_command_line, git_cmd, git_cmd_args)
  end

  test 'push with force: true' do
    expected_command_line = ['push', '--force', 'origin', 'master']
    git_cmd = :push
    git_cmd_args = ['origin', 'master', force: true]
    assert_command_line(expected_command_line, git_cmd, git_cmd_args)
  end

  test 'push with f: true' do
    expected_command_line = ['push', '--force', 'origin', 'master']
    git_cmd = :push
    git_cmd_args = ['origin', 'master', f: true]
    assert_command_line(expected_command_line, git_cmd, git_cmd_args)
  end

  test 'push with mirror: true' do
    expected_command_line = ['push', '--force', 'origin', 'master']
    git_cmd = :push
    git_cmd_args = ['origin', 'master', f: true]
    assert_command_line(expected_command_line, git_cmd, git_cmd_args)
  end

  test 'push with delete: true' do
    expected_command_line = ['push', '--delete', 'origin', 'master']
    git_cmd = :push
    git_cmd_args = ['origin', 'master', delete: true]
    assert_command_line(expected_command_line, git_cmd, git_cmd_args)
  end

  test 'push with tags: true' do
    expected_command_line = ['push', '--tags', 'origin']
    git_cmd = :push
    git_cmd_args = ['origin', nil, tags: true]
    assert_command_line(expected_command_line, git_cmd, git_cmd_args)
  end

  test 'push with all: true' do
    expected_command_line = ['push', '--all', 'origin']
    git_cmd = :push
    git_cmd_args = ['origin', all: true]
    assert_command_line(expected_command_line, git_cmd, git_cmd_args)
  end

  test 'when push succeeds an error should not be raised' do
    in_temp_dir do
      Git.init('remote.git', initial_branch: 'master', bare: true)

      git = Git.clone('remote.git', 'local')
      Dir.chdir 'local' do
        File.write('File2.txt', 'hello world')
        git.add('File2.txt')
        git.commit('Second commit')
        assert_nothing_raised { git.push }
      end
    end
  end

  test 'when push fails a Git::FailedError should be raised' do
    in_temp_dir do
      Git.init('remote.git', initial_branch: 'master', bare: true)

      git = Git.clone('remote.git', 'local')
      Dir.chdir 'local' do
        # Pushing when there is nothing to push fails
        assert_raises(Git::FailedError) { git.push }
      end
    end
  end
end
