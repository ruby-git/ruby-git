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
    expected_command_line = ['push', '--', 'origin', {}]
    assert_command_line_eq(expected_command_line) { |git| git.push('origin') }
  end

  test 'push with a single push option' do
    expected_command_line = ['push', '--push-option=foo', {}]
    assert_command_line_eq(expected_command_line) { |git| git.push(push_option: 'foo') }
  end

  test 'push with an array of push options' do
    expected_command_line = ['push', '--push-option=foo', '--push-option=bar', '--push-option=baz', {}]
    assert_command_line_eq(expected_command_line) { |git| git.push(push_option: %w[foo bar baz]) }
  end

  test 'push with only a remote name and options' do
    expected_command_line = ['push', '--force', '--', 'origin', {}]
    assert_command_line_eq(expected_command_line) { |git| git.push('origin', force: true) }
  end

  test 'push with only a branch name' do
    in_temp_dir do
      git = Git.init('.', initial_branch: 'master')
      assert_raises(ArgumentError) { git.push(nil, 'master') }
    end
  end

  test 'push with both remote and branch name' do
    expected_command_line = ['push', '--', 'origin', 'master', {}]
    assert_command_line_eq(expected_command_line) { |git| git.push('origin', 'master') }
  end

  test 'push with force: true' do
    expected_command_line = ['push', '--force', '--', 'origin', 'master', {}]
    assert_command_line_eq(expected_command_line) { |git| git.push('origin', 'master', force: true) }
  end

  test 'push with f: true' do
    expected_command_line = ['push', '--force', '--', 'origin', 'master', {}]
    assert_command_line_eq(expected_command_line) { |git| git.push('origin', 'master', f: true) }
  end

  test 'push with mirror: true' do
    expected_command_line = ['push', '--mirror', '--', 'origin', 'master', {}]
    assert_command_line_eq(expected_command_line) { |git| git.push('origin', 'master', mirror: true) }
  end

  test 'push with delete: true' do
    expected_command_line = ['push', '--delete', '--', 'origin', 'master', {}]
    assert_command_line_eq(expected_command_line) { |git| git.push('origin', 'master', delete: true) }
  end

  test 'push with tags: true does a second tags push and returns its stdout' do
    in_temp_dir do
      git = Git.init('.', initial_branch: 'master')
      push_cmd = Git::Commands::Push.new(git.lib)

      status = Struct.new(:success?, :exitstatus, :signaled?).new(true, 0, false)
      first_result = Git::CommandLineResult.new(%w[git push], status, 'first push', '')
      second_result = Git::CommandLineResult.new(%w[git push], status, 'tags push', '')

      Git::Commands::Push.expects(:new).with(git.lib).twice.returns(push_cmd)
      push_cmd.expects(:call).with('origin', 'master').returns(first_result)
      push_cmd.expects(:call).with('origin', tags: true).returns(second_result)

      assert_equal('tags push', git.push('origin', 'master', tags: true))
    end
  end

  test 'push with mirror: true and tags: true silently drops tags push' do
    in_temp_dir do
      git = Git.init('.', initial_branch: 'master')
      push_cmd = Git::Commands::Push.new(git.lib)

      status = Struct.new(:success?, :exitstatus, :signaled?).new(true, 0, false)
      result = Git::CommandLineResult.new(%w[git push], status, 'mirror push', '')

      Git::Commands::Push.expects(:new).with(git.lib).once.returns(push_cmd)
      push_cmd.expects(:call).with('origin', 'master', mirror: true).returns(result)

      assert_equal('mirror push', git.push('origin', 'master', mirror: true, tags: true))
    end
  end

  test 'push with all: true and tags: true allows the mutually exclusive combination' do
    in_temp_dir do
      git = Git.init('.', initial_branch: 'master')
      push_cmd = Git::Commands::Push.new(git.lib)

      status = Struct.new(:success?, :exitstatus, :signaled?).new(true, 0, false)
      first_result = Git::CommandLineResult.new(%w[git push], status, 'all push', '')
      second_result = Git::CommandLineResult.new(%w[git push], status, 'all tags push', '')

      Git::Commands::Push.expects(:new).with(git.lib).twice.returns(push_cmd)
      push_cmd.expects(:call).with('origin', all: true).returns(first_result)
      push_cmd.expects(:call).with('origin', all: true, tags: true).returns(second_result)

      assert_equal('all tags push', git.push('origin', all: true, tags: true))
    end
  end

  test 'push with all: true' do
    expected_command_line = ['push', '--all', '--', 'origin', {}]
    assert_command_line_eq(expected_command_line) { |git| git.push('origin', all: true) }
  end

  test 'push rejects branches option because it was not supported by the legacy interface' do
    in_temp_dir do
      git = Git.init('.', initial_branch: 'master')

      error = assert_raise(ArgumentError) { git.push('origin', branches: true) }
      assert_equal('Unknown options: branches', error.message)
    end
  end

  test 'push rejects timeout option because it was not supported by the legacy interface' do
    in_temp_dir do
      git = Git.init('.', initial_branch: 'master')

      error = assert_raise(ArgumentError) { git.push('origin', timeout: 1) }
      assert_equal('Unknown options: timeout', error.message)
    end
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
