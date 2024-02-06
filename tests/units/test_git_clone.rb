# frozen_string_literal: true

require 'test/unit'
require 'test_helper'

# Tests for Git.clone
class TestGitClone < Test::Unit::TestCase
  sub_test_case 'Git.clone with timeouts' do
    test 'global timmeout' do
      begin
        saved_timeout = Git.config.timeout

        in_temp_dir do |path|
          setup_repo
          Git.config.timeout = 0.00001

          error = assert_raise Git::TimeoutError do
            Git.clone('repository.git', 'temp2', timeout: nil)
          end

          assert_equal(true, error.result.status.timeout?)
        end
      ensure
        Git.config.timeout = saved_timeout
      end
    end

    test 'override global timeout' do
      in_temp_dir do |path|
        saved_timeout = Git.config.timeout

        in_temp_dir do |path|
          setup_repo
          Git.config.timeout = 0.00001

          assert_nothing_raised do
            Git.clone('repository.git', 'temp2', timeout: 10)
          end
        end
      ensure
        Git.config.timeout = saved_timeout
      end
    end

    test 'per command timeout' do
      in_temp_dir do |path|
        setup_repo

        error = assert_raise Git::TimeoutError do
          Git.clone('repository.git', 'temp2', timeout: 0.00001)
        end

        assert_equal(true, error.result.status.timeout?)
      end
    end

  end

  def setup_repo
    Git.init('repository.git', bare: true)
    git = Git.clone('repository.git', 'temp')
    File.write('temp/test.txt', 'test')
    git.add('test.txt')
    git.commit('Initial commit')
  end

  def test_git_clone_with_name
    in_temp_dir do |path|
      setup_repo
      clone_dir = 'clone_to_this_dir'
      git = Git.clone('repository.git', clone_dir)
      assert(Dir.exist?(clone_dir))
      expected_dir = File.realpath(clone_dir)
      assert_equal(expected_dir, git.dir.to_s)
    end
  end

  def test_git_clone_with_no_name
    in_temp_dir do |path|
      setup_repo
      git = Git.clone('repository.git')
      assert(Dir.exist?('repository'))
      expected_dir = File.realpath('repository')
      assert_equal(expected_dir, git.dir.to_s)
    end
  end

  test 'clone with single config option' do
    repository_url = 'https://github.com/ruby-git/ruby-git.git'
    destination = 'ruby-git'

    actual_command_line = nil

    in_temp_dir do |path|
      git = Git.init('.')

      # Mock the Git::Lib#command method to capture the actual command line args
      git.lib.define_singleton_method(:command) do |cmd, *opts, &block|
        actual_command_line = [cmd, *opts.flatten]
      end

      git.lib.clone(repository_url, destination, { config: 'user.name=John Doe' })
    end

    expected_command_line = ['clone', '--config', 'user.name=John Doe', '--', repository_url, destination, {timeout: nil}]

    assert_equal(expected_command_line, actual_command_line)
  end

  test 'clone with multiple config options' do
    repository_url = 'https://github.com/ruby-git/ruby-git.git'
    destination = 'ruby-git'

    actual_command_line = nil

    in_temp_dir do |path|
      git = Git.init('.')

      # Mock the Git::Lib#command method to capture the actual command line args
      git.lib.define_singleton_method(:command) do |cmd, *opts, &block|
        actual_command_line = [cmd, *opts.flatten]
      end

      git.lib.clone(repository_url, destination, { config: ['user.name=John Doe', 'user.email=john@doe.com'] })
    end

    expected_command_line = [
      'clone',
      '--config', 'user.name=John Doe',
      '--config', 'user.email=john@doe.com',
      '--', repository_url, destination, {timeout: nil}
    ]

    assert_equal(expected_command_line, actual_command_line)
  end

  test 'clone with a filter' do
    repository_url = 'https://github.com/ruby-git/ruby-git.git'
    destination = 'ruby-git'

    actual_command_line = nil

    in_temp_dir do |path|
      git = Git.init('.')

      # Mock the Git::Lib#command method to capture the actual command line args
      git.lib.define_singleton_method(:command) do |cmd, *opts, &block|
        actual_command_line = [cmd, *opts.flatten]
      end

      git.lib.clone(repository_url, destination, filter: 'tree:0')
    end

    expected_command_line = [
      'clone',
      '--filter', 'tree:0',
      '--', repository_url, destination, {timeout: nil}
    ]

    assert_equal(expected_command_line, actual_command_line)
  end
end
