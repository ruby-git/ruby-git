# frozen_string_literal: true

require 'test_helper'

class TestPush < Test::Unit::TestCase
  test 'push with no args' do
    expected_command_line = ['push', {}]
    assert_command_line_eq(expected_command_line, &:push)
  end

  test 'push with no args and options' do
    expected_command_line = ['push', '--force', {}]
    assert_command_line_eq(expected_command_line) { |git| git.push(force: true) }
  end

  test 'push with only a remote name' do
    expected_command_line = ['push', 'origin', {}]
    assert_command_line_eq(expected_command_line) { |git| git.push('origin') }
  end

  test 'push with a single push option' do
    expected_command_line = ['push', '--push-option', 'foo', {}]
    assert_command_line_eq(expected_command_line) { |git| git.push(push_option: 'foo') }
  end

  test 'push with an array of push options' do
    expected_command_line = ['push', '--push-option', 'foo', '--push-option', 'bar', '--push-option', 'baz', {}]
    assert_command_line_eq(expected_command_line) { |git| git.push(push_option: %w[foo bar baz]) }
  end

  test 'push with only a remote name and options' do
    expected_command_line = ['push', '--force', 'origin', {}]
    assert_command_line_eq(expected_command_line) { |git| git.push('origin', force: true) }
  end

  test 'push with only a branch name' do
    in_temp_dir do
      git = Git.init('.', initial_branch: 'master')
      assert_raises(ArgumentError) { git.push(nil, 'master') }
    end
  end

  test 'push with both remote and branch name' do
    expected_command_line = ['push', 'origin', 'master', {}]
    assert_command_line_eq(expected_command_line) { |git| git.push('origin', 'master') }
  end

  test 'push with force: true' do
    expected_command_line = ['push', '--force', 'origin', 'master', {}]
    assert_command_line_eq(expected_command_line) { |git| git.push('origin', 'master', force: true) }
  end

  test 'push with f: true' do
    expected_command_line = ['push', '--force', 'origin', 'master', {}]
    assert_command_line_eq(expected_command_line) { |git| git.push('origin', 'master', f: true) }
  end

  test 'push with mirror: true' do
    expected_command_line = ['push', '--mirror', 'origin', 'master', {}]
    assert_command_line_eq(expected_command_line) { |git| git.push('origin', 'master', mirror: true) }
  end

  test 'push with delete: true' do
    expected_command_line = ['push', '--delete', 'origin', 'master', {}]
    assert_command_line_eq(expected_command_line) { |git| git.push('origin', 'master', delete: true) }
  end

  test 'push with tags: true' do
    expected_command_line = ['push', '--tags', 'origin', {}]
    assert_command_line_eq(expected_command_line) { |git| git.push('origin', 'master', tags: true) }
  end

  test 'push with all: true' do
    expected_command_line = ['push', '--all', 'origin', {}]
    assert_command_line_eq(expected_command_line) { |git| git.push('origin', all: true) }
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
