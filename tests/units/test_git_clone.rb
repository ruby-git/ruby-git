# frozen_string_literal: true

require 'test/unit'
require 'test_helper'

# Tests for Git.clone
class TestGitClone < Test::Unit::TestCase
  sub_test_case 'Git.clone with timeouts' do
    test 'global timmeout' do
      saved_timeout = Git.config.timeout

      in_temp_dir do |_path|
        setup_repo
        # Use larger timeout on JRuby due to subprocess timing differences
        Git.config.timeout = jruby_platform? ? 0.001 : 0.00001

        error = assert_raise Git::TimeoutError do
          Git.clone('repository.git', 'temp2', timeout: nil)
        end

        assert_equal(true, error.result.status.timed_out?)
      end
    ensure
      Git.config.timeout = saved_timeout
    end

    test 'override global timeout' do
      in_temp_dir do |_path|
        saved_timeout = Git.config.timeout

        in_temp_dir do |_path|
          setup_repo
          # Use larger timeout on JRuby due to subprocess timing differences
          Git.config.timeout = jruby_platform? ? 0.001 : 0.00001

          assert_nothing_raised do
            Git.clone('repository.git', 'temp2', timeout: 10)
          end
        end
      ensure
        Git.config.timeout = saved_timeout
      end
    end

    test 'per command timeout' do
      in_temp_dir do |_path|
        setup_repo

        # Use larger timeout on JRuby due to subprocess timing differences
        timeout_value = jruby_platform? ? 0.001 : 0.00001
        error = assert_raise Git::TimeoutError do
          Git.clone('repository.git', 'temp2', timeout: timeout_value)
        end

        assert_equal(true, error.result.status.timed_out?)
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
    in_temp_dir do |_path|
      setup_repo
      clone_dir = 'clone_to_this_dir'
      git = Git.clone('repository.git', clone_dir)
      assert(Dir.exist?(clone_dir))
      expected_dir = File.realpath(clone_dir)
      assert_equal(expected_dir, git.dir.to_s)
    end
  end

  def test_git_clone_with_no_name
    in_temp_dir do |_path|
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

    in_temp_dir do |_path|
      git = Git.init('.')

      # Mock the Git::Lib#command! method to capture the actual command line args
      clone_result = mock_clone_result(destination)
      git.lib.define_singleton_method(:command) do |cmd, *opts|
        actual_command_line = [cmd, *opts.flatten]
        clone_result
      end

      git.lib.clone(repository_url, destination, { config: 'user.name=John Doe' })
    end

    expected_command_line = ['clone', '--config', 'user.name=John Doe', '--', repository_url, destination,
                             { timeout: nil }]

    assert_equal(expected_command_line, actual_command_line)
  end

  test 'clone with multiple config options' do
    repository_url = 'https://github.com/ruby-git/ruby-git.git'
    destination = 'ruby-git'

    actual_command_line = nil

    in_temp_dir do |_path|
      git = Git.init('.')

      # Mock the Git::Lib#command! method to capture the actual command line args
      clone_result = mock_clone_result(destination)
      git.lib.define_singleton_method(:command) do |cmd, *opts|
        actual_command_line = [cmd, *opts.flatten]
        clone_result
      end

      git.lib.clone(repository_url, destination, { config: ['user.name=John Doe', 'user.email=john@doe.com'] })
    end

    expected_command_line = [
      'clone',
      '--config', 'user.name=John Doe',
      '--config', 'user.email=john@doe.com',
      '--', repository_url, destination, { timeout: nil }
    ]

    assert_equal(expected_command_line, actual_command_line)
  end

  test 'clone with a filter' do
    repository_url = 'https://github.com/ruby-git/ruby-git.git'
    destination = 'ruby-git'

    actual_command_line = nil

    in_temp_dir do |_path|
      git = Git.init('.')

      # Mock the Git::Lib#command! method to capture the actual command line args
      clone_result = mock_clone_result(destination)
      git.lib.define_singleton_method(:command) do |cmd, *opts|
        actual_command_line = [cmd, *opts.flatten]
        clone_result
      end

      git.lib.clone(repository_url, destination, filter: 'tree:0')
    end

    expected_command_line = [
      'clone',
      '--filter', 'tree:0',
      '--', repository_url, destination, { timeout: nil }
    ]

    assert_equal(expected_command_line, actual_command_line)
  end

  test 'clone without giving the single_branch option' do
    repository_url = 'https://github.com/ruby-git/ruby-git.git'
    destination = 'ruby-git'

    actual_command_line = nil

    in_temp_dir do |_path|
      git = Git.init('.')

      clone_result = mock_clone_result(destination)
      git.lib.define_singleton_method(:command) do |cmd, *opts|
        actual_command_line = [cmd, *opts.flatten]
        clone_result
      end

      git.lib.clone(repository_url, destination)
    end

    expected_command_line = [
      'clone',
      '--', repository_url, destination, { timeout: nil }
    ]

    assert_equal(expected_command_line, actual_command_line)
  end

  test 'clone with single_branch true' do
    repository_url = 'https://github.com/ruby-git/ruby-git.git'
    destination = 'ruby-git'

    actual_command_line = nil

    in_temp_dir do |_path|
      git = Git.init('.')

      clone_result = mock_clone_result(destination)
      git.lib.define_singleton_method(:command) do |cmd, *opts|
        actual_command_line = [cmd, *opts.flatten]
        clone_result
      end

      git.lib.clone(repository_url, destination, single_branch: true)
    end

    expected_command_line = [
      'clone',
      '--single-branch',
      '--', repository_url, destination, { timeout: nil }
    ]

    assert_equal(expected_command_line, actual_command_line)
  end

  test 'clone with single_branch false' do
    repository_url = 'https://github.com/ruby-git/ruby-git.git'
    destination = 'ruby-git'

    actual_command_line = nil

    in_temp_dir do |_path|
      git = Git.init('.')

      clone_result = mock_clone_result(destination)
      git.lib.define_singleton_method(:command) do |cmd, *opts|
        actual_command_line = [cmd, *opts.flatten]
        clone_result
      end

      git.lib.clone(repository_url, destination, single_branch: false)
    end

    expected_command_line = [
      'clone',
      '--no-single-branch',
      '--', repository_url, destination, { timeout: nil }
    ]

    assert_equal(expected_command_line, actual_command_line)
  end

  test 'clone with single_branch nil adds no flag' do
    repository_url = 'https://github.com/ruby-git/ruby-git.git'
    destination = 'ruby-git'

    actual_command_line = nil

    in_temp_dir do |_path|
      git = Git.init('.')

      clone_result = mock_clone_result(destination)
      git.lib.define_singleton_method(:command) do |cmd, *opts|
        actual_command_line = [cmd, *opts.flatten]
        clone_result
      end

      git.lib.clone(repository_url, destination, single_branch: nil)
    end

    expected_command_line = [
      'clone',
      '--', repository_url, destination, { timeout: nil }
    ]

    assert_equal(expected_command_line, actual_command_line)
  end

  test 'shallow clone with single_branch false uses wide refspec' do
    in_temp_dir do |path|
      repository_path = File.join(path, 'remote.git')
      Git.init(repository_path, bare: true)

      worktree_path = File.join(path, 'remote-worktree')
      worktree = Git.clone(repository_path, worktree_path)
      File.write(File.join(worktree_path, 'test.txt'), 'test')
      worktree.add('test.txt')
      worktree.commit('Initial commit')
      worktree.push

      worktree.branch('feature').checkout
      File.write(File.join(worktree_path, 'feature.txt'), 'feature branch')
      worktree.add('feature.txt')
      worktree.commit('Add feature branch commit')
      worktree.push('origin', 'feature')
      FileUtils.rm_rf(worktree_path)

      shallow_path = File.join(path, 'shallow')
      shallow_clone = Git.clone(repository_path, shallow_path, depth: 1, single_branch: false)
      fetch_spec = shallow_clone.config('remote.origin.fetch')

      assert_equal('+refs/heads/*:refs/remotes/origin/*', fetch_spec)
    end
  end

  test 'clone with negative depth' do
    in_temp_dir do |path|
      # Give a bare repository with a single commit
      repository_path = File.join(path, 'repository.git')
      Git.init(repository_path, bare: true)
      worktree_path = File.join(path, 'repository')
      worktree = Git.clone(repository_path, worktree_path)
      File.write(File.join(worktree_path, 'test.txt'), 'test')
      worktree.add('test.txt')
      worktree.commit('Initial commit')
      worktree.push
      FileUtils.rm_rf(worktree_path)

      # When I clone it with a negative depth with
      error = assert_raises(Git::FailedError) do
        Git.clone(repository_path, worktree, depth: -1)
      end

      assert_match(/depth/, error.result.stderr)
    end

    #   git = Git.init('.')

    #   # Mock the Git::Lib#command method to capture the actual command line args
    #   git.lib.define_singleton_method(:command) do |cmd, *opts, &block|
    #     actual_command_line = [cmd, *opts.flatten]
    #   end

    #   git.lib.clone(repository_url, destination, depth: -1)
    # end

    # expected_command_line = [
    #   'clone',
    #   '--depth', '-1',
    #   '--', repository_url, destination, {timeout: nil}
    # ]

    # assert_equal(expected_command_line, actual_command_line)
  end
end
