# frozen_string_literal: true

require 'test_helper'
require 'git'
require 'fileutils'
require 'tmpdir'

# A test case to demonstrate the use of Git::Base#set_working
class SetWorkingTest < Test::Unit::TestCase
  # Set up a temporary Git repository before each test.
  def setup
    # Create a temporary directory for the repository
    @repo_path = Dir.mktmpdir('git_test')

    # Initialize a new Git repository in the temporary directory
    @repo = Git.init(@repo_path)
  end

  attr_reader :repo_path, :repo

  # Clean up the temporary repository after each test.
  def teardown
    FileUtils.rm_rf(repo_path)
  end

  # Tests that `set_working` can point to a new, non-existent directory
  # when `must_exist: false` is specified.
  def test_set_working_with_must_exist_false_for_new_path
    custom_working_path = File.join(repo_path, 'custom_work_dir')
    assert(!File.exist?(custom_working_path), 'Precondition: Custom working directory should not exist.')

    # Action: Set the working directory to a new path, allowing it to not exist.
    repo.set_working(custom_working_path, must_exist: false)

    # Verification: The repo object should now point to the new working directory path.
    assert_equal(custom_working_path, repo.dir.path, 'Working directory path should be updated to the custom path.')
  end

  # Tests that `set_working` successfully points to an existing directory
  # when `must_exist: true` is specified.
  def test_set_working_with_must_exist_true_for_existing_path
    original_working_path = repo.dir.path
    assert(File.exist?(original_working_path), 'Precondition: Original working directory should exist.')

    # Action: Set the working directory to the same, existing path, explicitly requiring it to exist.
    repo.set_working(original_working_path, must_exist: true)

    # Verification: The working directory path should remain unchanged.
    assert_equal(original_working_path, repo.dir.path, 'Working directory path should still be the original path.')
  end

  # Tests that `set_working` raises an ArgumentError when trying to point to a
  # non-existent directory with the default behavior (`must_exist: true`).
  def test_set_working_with_must_exist_true_raises_error_for_new_path
    non_existent_path = File.join(repo_path, 'no_such_dir')
    assert(!File.exist?(non_existent_path), 'Precondition: The target working directory path should not exist.')

    # Action & Verification: Assert that an ArgumentError is raised.
    assert_raise(ArgumentError, 'Should raise ArgumentError for a non-existent working directory path.') do
      repo.set_working(non_existent_path) # must_exist defaults to true
    end
  end

  # Tests that using the deprecated `check` argument issues a warning via mocking.
  def test_set_working_with_deprecated_check_argument
    custom_working_path = File.join(repo_path, 'custom_work_dir')
    assert(!File.exist?(custom_working_path), 'Precondition: Custom working directory should not exist.')

    # Set up the mock expectation.
    # We expect Git::Deprecation.warn to be called once with a message
    # matching the expected deprecation warning.
    Git::Deprecation.expects(:warn).with(
      regexp_matches(/The "check" argument is deprecated/)
    )

    # Action: Use the deprecated positional argument `check = false`
    repo.set_working(custom_working_path, false)

    # Verification: The repo object should still point to the new working directory path.
    assert_equal(custom_working_path, repo.dir.path, 'Working directory path should be updated even with deprecated argument.')
    # Mocha automatically verifies the expectation at the end of the test.
  end
end
