# frozen_string_literal: true

require 'test_helper'

class TestPull < Test::Unit::TestCase

  test 'pull with branch only should raise an ArgumentError' do
    in_temp_dir do
      Dir.mkdir('remote')

      Dir.chdir('remote') do
        `git init --initial-branch=branch1`
        File.write('README.md', 'Line 1')
        `git add README.md`
        `git commit -m "Initial commit"`
      end

      `git clone remote/.git local 2>&1`

      Dir.chdir('local') do
        git = Git.open('.')
        assert_raises(ArgumentError) { git.pull(nil, 'branch1') }
      end
    end
  end

  test 'pull with no args should use the default remote and current branch name' do
    in_temp_dir do
      Dir.mkdir('remote')

      Dir.chdir('remote') do
        `git init --initial-branch=branch1`
        File.write('README.md', 'Line 1')
        `git add README.md`
        `git commit -m "Initial commit"`
      end

      `git clone remote/.git local 2>&1`

      Dir.chdir('remote') do
        File.open('README.md', 'a') { |f| f.write('Line 2') }
        `git add README.md`
        `git commit -m "Initial commit"`
      end

      Dir.chdir('local') do
        git = Git.open('.')
        assert_equal(1, git.log.size)
        assert_nothing_raised { git.pull }
        assert_equal(2, git.log.size)
      end
    end
  end

  test 'pull with one arg should use arg as remote and the current branch name' do
    in_temp_dir do
      Dir.mkdir('remote')

      Dir.chdir('remote') do
        `git init --initial-branch=branch1`
        File.write('README.md', 'Line 1')
        `git add README.md`
        `git commit -m "Initial commit"`
      end

      `git clone remote/.git local 2>&1`

      Dir.chdir('remote') do
        File.open('README.md', 'a') { |f| f.write('Line 2') }
        `git add README.md`
        `git commit -m "Initial commit"`
      end

      Dir.chdir('local') do
        git = Git.open('.')
        assert_equal(1, git.log.size)
        assert_nothing_raised { git.pull('origin') }
        assert_equal(2, git.log.size)
      end
    end
  end

  test 'pull with both remote and branch should use both' do
    in_temp_dir do
      Dir.mkdir('remote')

      Dir.chdir('remote') do
        `git init --initial-branch=master`
        File.write('README.md', 'Line 1')
        `git add README.md`
        `git commit -m "Initial commit"`
      end

      `git clone remote/.git local 2>&1`

      Dir.chdir('remote') do
        `git checkout -b feature1 2>&1`
        File.write('feature1.md', 'Line 1')
        `git add feature1.md`
        `git commit -m "Implement feature 1"`
        File.open('feature1.md', 'a') { |f| f.write('Line 2') }
        `git add feature1.md`
        `git commit -m "Implement feature 1, line 2"`
      end

      Dir.chdir('local') do
        git = Git.open('.')
        assert_equal(1, git.log.size)
        assert_nothing_raised { git.pull('origin', 'feature1') }
        assert_equal(3, git.log.size)
      end
    end
  end

  test 'when pull fails a Git::FailedError should be raised' do
    in_temp_dir do
      Dir.mkdir('remote')

      Dir.chdir('remote') do
        `git init --initial-branch=master`
        File.write('README.md', 'Line 1')
        `git add README.md`
        `git commit -m "Initial commit"`
      end

      `git clone remote/.git local 2>&1`

      Dir.chdir('local') do
        git = Git.open('.')
        assert_raises(Git::FailedError) { git.pull('origin', 'none_existing_branch') }
      end
    end
  end

  test 'pull with allow_unrelated_histories: true' do
    expected_command_line = ['pull', '--allow-unrelated-histories', 'origin', 'feature1', {}]
    assert_command_line_eq(expected_command_line) do |git|
      git.pull('origin', 'feature1', allow_unrelated_histories: true)
    end
  end
end
