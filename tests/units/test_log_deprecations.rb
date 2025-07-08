# frozen_string_literal: true

require 'test_helper'
require 'git'
require 'fileutils'
require 'tmpdir'

# A test case to verify the deprecation warnings for methods on the Git::Log class.
class LogDeprecationsTest < Test::Unit::TestCase
  # Set up a temporary Git repository with a single commit before each test.
  def setup
    @repo_path = Dir.mktmpdir('git_test')
    @repo = Git.init(@repo_path)

    # Create a commit so the log has an entry to work with.
    Dir.chdir(@repo_path) do
      File.write('file.txt', 'content')
      @repo.add('file.txt')
      @repo.commit('Initial commit')
    end

    @log = @repo.log
    @first_commit = @repo.gcommit('HEAD')
  end

  # Clean up the temporary repository after each test.
  def teardown
    FileUtils.rm_rf(@repo_path)
  end

  # Test the deprecation warning and functionality of Git::Log#each
  def test_each_deprecation
    Git::Deprecation.expects(:warn).with(
      'Calling Git::Log#each is deprecated. Call #execute and then #each on the result object.'
    )

    commits = @log.map { |c| c }

    assert_equal(1, commits.size, 'The #each method should still yield the correct number of commits.')
    assert_equal(@first_commit.sha, commits.first.sha, 'The yielded commit should have the correct SHA.')
  end

  # Test the deprecation warning and functionality of Git::Log#size
  def test_size_deprecation
    Git::Deprecation.expects(:warn).with(
      'Calling Git::Log#size is deprecated. Call #execute and then #size on the result object.'
    )
    assert_equal(1, @log.size, 'The #size method should still return the correct number of commits.')
  end

  # Test the deprecation warning and functionality of Git::Log#to_s
  def test_to_s_deprecation
    Git::Deprecation.expects(:warn).with(
      'Calling Git::Log#to_s is deprecated. Call #execute and then #to_s on the result object.'
    )
    assert_equal(@first_commit.sha, @log.to_s, 'The #to_s method should return the commit SHA.')
  end

  # Test the deprecation warning and functionality of Git::Log#first
  def test_first_deprecation
    Git::Deprecation.expects(:warn).with(
      'Calling Git::Log#first is deprecated. Call #execute and then #first on the result object.'
    )
    assert_equal(@first_commit.sha, @log.first.sha, 'The #first method should return the correct commit.')
  end

  # Test the deprecation warning and functionality of Git::Log#last
  def test_last_deprecation
    Git::Deprecation.expects(:warn).with(
      'Calling Git::Log#last is deprecated. Call #execute and then #last on the result object.'
    )
    assert_equal(@first_commit.sha, @log.last.sha, 'The #last method should return the correct commit.')
  end

  # Test the deprecation warning and functionality of Git::Log#[]
  def test_indexer_deprecation
    Git::Deprecation.expects(:warn).with(
      'Calling Git::Log#[] is deprecated. Call #execute and then #[] on the result object.'
    )
    assert_equal(@first_commit.sha, @log[0].sha, 'The #[] method should return the correct commit at the specified index.')
  end
end
