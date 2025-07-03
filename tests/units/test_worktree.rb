# frozen_string_literal: true

# require 'fileutils'
# require 'pathname'
# require 'tmpdir'
require 'test_helper'

# SAMPLE_LAST_COMMIT = '5e53019b3238362144c2766f02a2c00d91fcc023'

class TestWorktree < Test::Unit::TestCase
  def setup
    ENV['GIT_DIR'] = nil
  end

  test 'listing worktrees when there are no commits should return only the main worktree' do
    Dir.mktmpdir do |path|
      path = File.realpath(path)
      Dir.chdir(path) do
        Dir.mkdir('main_worktree')
        Dir.chdir('main_worktree') do
          `git init`
        end

        git = Git.open('main_worktree')

        assert_equal(1, git.worktrees.size)
        expected_worktree_dir = File.join(path, 'main_worktree')
        assert_equal(expected_worktree_dir, git.worktrees.to_a[0].dir)
      end
    end
  end

  test 'adding a worktree when there are no commits should fail' do
    omit('Omitted since git version is >= 2.42.0') if Git::Lib.new(nil, nil).compare_version_to(2, 42, 0) >= 0

    in_temp_dir do |_path|
      Dir.mkdir('main_worktree')
      Dir.chdir('main_worktree') do
        `git init`
      end

      git = Git.open('main_worktree')

      assert_equal(1, git.worktrees.size)

      assert_raises(Git::FailedError) do
        git.worktree('feature1').add
      end
    end
  end

  test 'adding a worktree when there are no commits should succeed' do
    omit('Omitted since git version is < 2.42.0') if Git::Lib.new(nil, nil).compare_version_to(2, 42, 0) < 0

    in_temp_dir do |path|
      Dir.mkdir('main_worktree')
      Dir.chdir('main_worktree') do
        `git init`
        # `git commit --allow-empty -m "first commit"`
      end

      git = Git.open('main_worktree')

      assert_nothing_raised do
        git.worktree('feature1').add
      end

      assert_equal(2, git.worktrees.size)

      [
        File.join(path, 'main_worktree'),
        File.join(path, 'feature1')
      ].each_with_index do |expected_worktree_dir, i|
        assert_equal(expected_worktree_dir, git.worktrees.to_a[i].dir)
      end
    end
  end

  test 'adding a worktree when there is at least one commit should succeed' do
    in_temp_dir do |path|
      Dir.mkdir('main_worktree')
      Dir.chdir('main_worktree') do
        `git init`
        `git commit --allow-empty -m "first commit"`
      end

      git = Git.open('main_worktree')

      assert_nothing_raised do
        git.worktree('feature1').add
      end

      assert_equal(2, git.worktrees.size)

      [
        File.join(path, 'main_worktree'),
        File.join(path, 'feature1')
      ].each_with_index do |expected_worktree_dir, i|
        assert_equal(expected_worktree_dir, git.worktrees.to_a[i].dir)
      end
    end
  end

  test 'removing a worktree by directory name should succeed' do
    in_temp_dir do |path|
      Dir.mkdir('main_worktree')
      Dir.chdir('main_worktree') do
        `git init`
        `git commit --allow-empty -m "first commit"`
      end

      git = Git.open('main_worktree')
      git.worktree('feature1').add
      git.worktree('feature2').add

      assert_equal(3, git.worktrees.size)

      git.worktrees[File.join(path, 'feature1')].remove

      assert_equal(2, git.worktrees.size)

      git.worktrees[File.join(path, 'feature2')].remove

      assert_equal(1, git.worktrees.size)
    end
  end

  test 'removing a non-existant worktree should fail'

  test 'should be able to get the main_worktree' do
    in_temp_dir do |path|
      Dir.mkdir('main_worktree')
      Dir.chdir('main_worktree') do
        `git init`
        `git commit --allow-empty -m "first commit"`
      end

      git = Git.open('main_worktree')

      assert_equal(1, git.worktrees.size)

      assert_not_nil(git.worktrees[File.join(path, 'main_worktree')])
    end
  end

  test 'removing the main worktree should fail' do
    in_temp_dir do |path|
      Dir.mkdir('main_worktree')
      Dir.chdir('main_worktree') do
        `git init`
        `git commit --allow-empty -m "first commit"`
      end

      git = Git.open('main_worktree')
      git.worktree('feature1').add
      git.worktree('feature2').add

      assert_equal(3, git.worktrees.size)

      assert_raises(Git::FailedError) do
        git.worktrees[File.join(path, 'main_worktree')].remove
      end

      assert_equal(3, git.worktrees.size)
    end
  end

  test 'pruning should remove worktrees that were manually deleted' do
    in_temp_dir do |path|
      Dir.mkdir('main_worktree')
      Dir.chdir('main_worktree') do
        `git init`
        `git commit --allow-empty -m "first commit"`
      end

      git = Git.open('main_worktree')
      git.worktree('feature1').add
      FileUtils.rm_rf(File.join(path, 'feature1'))

      git.worktree('feature2').add
      FileUtils.rm_rf(File.join(path, 'feature2'))

      assert_equal(3, git.worktrees.size)

      git.worktrees.prune

      assert_equal(1, git.worktrees.size)
    end
  end
end
