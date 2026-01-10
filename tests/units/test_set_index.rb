# frozen_string_literal: true

require 'test_helper'
require 'git'
require 'fileutils'
require 'tmpdir'

# A test case to demonstrate the use of Git::Base#set_index
#
# This test case will to programmatically create a new commit without affecting the
# main working directory or index.
#
class SetIndexTest < Test::Unit::TestCase
  # Set up a temporary Git repository before each test.
  def setup
    # Create a temporary directory for the repository
    @repo_path = Dir.mktmpdir('git_test')

    # Initialize a new Git repository in the temporary directory
    @repo = Git.init(@repo_path)

    # Change into the repo directory to perform file operations
    Dir.chdir(@repo_path) do
      # Create and commit an initial file to establish a HEAD and a root tree.
      # This gives us a base state to work from.
      File.write('file1.txt', 'This is the first file.')
      @repo.add('file1.txt')
      @repo.commit('Initial commit')
    end
  end

  attr_reader :repo_path, :repo

  # Clean up the temporary repository after each test.
  def teardown
    FileUtils.rm_rf(repo_path)
  end

  # Tests that `set_index` can point to a new, non-existent index file
  # when `must_exist: false` is specified.
  def test_set_index_with_must_exist_false_for_new_path
    custom_index_path = File.join(repo_path, 'custom_index')
    assert(!File.exist?(custom_index_path), 'Precondition: Custom index file should not exist.')

    # Action: Set the index to a new path, allowing it to not exist.
    repo.set_index(custom_index_path, must_exist: false)

    # Verification: The repo object should now point to the new index path.
    assert_equal(custom_index_path, repo.index.to_s, 'Index path should be updated to the custom path.')
  end

  # Tests that `set_index` successfully points to an existing index file
  # when `must_exist: true` is specified.
  def test_set_index_with_must_exist_true_for_existing_path
    original_index_path = repo.index.to_s
    assert(File.exist?(original_index_path), 'Precondition: Original index file should exist.')

    # Action: Set the index to the same, existing path, explicitly requiring it to exist.
    repo.set_index(original_index_path, must_exist: true)

    # Verification: The index path should remain unchanged.
    assert_equal(original_index_path, repo.index.to_s, 'Index path should still be the original path.')
  end

  # Tests that `set_index` raises an ArgumentError when trying to point to a
  # non-existent index file with the default behavior (`must_exist: true`).
  def test_set_index_with_must_exist_true_raises_error_for_new_path
    non_existent_path = File.join(repo_path, 'no_such_file')
    assert(!File.exist?(non_existent_path), 'Precondition: The target index path should not exist.')

    # Action & Verification: Assert that an ArgumentError is raised.
    assert_raise(ArgumentError, 'Should raise ArgumentError for a non-existent index path.') do
      repo.set_index(non_existent_path) # must_exist defaults to true
    end
  end

  # Tests that using the deprecated `check` argument issues a warning via mocking.
  def test_set_index_with_deprecated_check_argument
    custom_index_path = File.join(repo_path, 'custom_index')
    assert(!File.exist?(custom_index_path), 'Precondition: Custom index file should not exist.')

    # Set up the mock expectation.
    # We expect Git::Deprecation.warn to be called once with a message
    # matching the expected deprecation warning.
    Git::Deprecation.expects(:warn).with(
      regexp_matches(/The "check" argument is deprecated/)
    )

    # Action: Use the deprecated positional argument `check = false`
    repo.set_index(custom_index_path, false)

    # Verification: The repo object should still point to the new index path.
    assert_equal(custom_index_path, repo.index.to_s, 'Index path should be updated even with deprecated argument.')
    # Mocha automatically verifies the expectation at the end of the test.
  end

  # This test demonstrates creating a new commit on a new branch by
  # manipulating a custom, temporary index file. This allows for building
  # commits programmatically without touching the working directory or the
  # default .git/index.
  def test_programmatic_commit_with_set_index
    # 1. Get the initial commit object to use as a parent for our new commit.
    main_commit = repo.gcommit('main')
    assert(!main_commit.nil?, 'Initial commit should exist.')

    # 2. Define a path for a new, temporary index file within the repo directory.
    custom_index_path = File.join(repo_path, 'custom_index')
    assert(!File.exist?(custom_index_path), 'Custom index file should not exist yet.')

    # 3. Point the git object to use our custom index file.
    #    Since the file doesn't exist yet, we must pass `must_exist: false`.
    repo.set_index(custom_index_path, must_exist: false)
    assert_equal(custom_index_path, repo.index.to_s, 'The git object should now be using the custom index.')

    # 4. Populate the new index by reading the tree from our initial commit into it.
    #    This stages all the files from the 'main' commit in our custom index.
    repo.read_tree(main_commit.gtree.sha)

    # 5. Programmatically create a new file blob and add it to our custom index.
    #    This simulates `git add` for a new file, but operates directly on the index.
    new_content = 'This is a brand new file.'
    blob_sha = Tempfile.create('new_blob_content') do |file|
      file.write(new_content)
      file.rewind
      # Use `git hash-object -w` to write the blob to the object database and get its SHA
      repo.lib.send(:command, 'hash-object', '-w', file.path)
    end
    repo.lib.send(:command, 'update-index', '--add', '--cacheinfo', "100644,#{blob_sha},new_file.txt")

    # 6. Write the state of the custom index to a new tree object in the Git database.
    new_tree_sha = repo.write_tree
    assert_match(/^[0-9a-f]{40}$/, new_tree_sha, 'A new tree SHA should be created.')

    # 7. Create a new commit object from the new tree.
    #    This commit will have the initial commit as its parent.
    new_commit = repo.commit_tree(
      new_tree_sha,
      parents: [main_commit.sha],
      message: 'Commit created programmatically via custom index'
    )
    assert(new_commit.commit?, 'A new commit object should be created.')

    # 8. Create a new branch pointing to our new commit.
    repo.branch('feature-branch').update_ref(new_commit)
    assert(repo.branch('feature-branch').gcommit.sha == new_commit.sha, 'feature-branch should point to the new commit.')

    # --- Verification ---
    # Verify the history of the new branch
    feature_log = repo.log.object('feature-branch').execute
    main_commit_sha = repo.rev_parse('main') # Get SHA directly for reliable comparison

    assert_equal(2, feature_log.size, 'Feature branch should have two commits.')
    assert_equal(new_commit.sha, feature_log.first.sha, 'HEAD of feature-branch should be our new commit.')
    assert_equal(main_commit_sha, feature_log.last.sha, 'Parent of new commit should be the initial commit.')

    # Verify that the main branch is unchanged
    main_log = repo.log.object('main').execute
    assert_equal(1, main_log.size, 'Main branch should still have one commit.')
    assert_equal(main_commit_sha, main_log.first.sha, 'Main branch should still point to the initial commit.')

    # Verify the contents of the new commit's tree
    new_commit_tree = new_commit.gtree
    assert(new_commit_tree.blobs.key?('file1.txt'), 'Original file should exist in the new tree.')
    assert(new_commit_tree.blobs.key?('new_file.txt'), 'New file should exist in the new tree.')
    assert_equal(new_content, new_commit_tree.blobs['new_file.txt'].contents, 'Content of new file should match.')
  end
end
