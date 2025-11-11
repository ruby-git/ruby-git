# frozen_string_literal: true

require 'test_helper'
require 'git'
require 'fileutils'
require 'tmpdir'

# A test case to verify the functionality of the Git::Object.new factory method.
class ObjectNewTest < Test::Unit::TestCase
  # Set up a temporary Git repository with objects of different types.
  def setup
    @repo_path = Dir.mktmpdir('git_test')
    @repo = Git.init(@repo_path)

    Dir.chdir(@repo_path) do
      File.write('file.txt', 'This is a test file.')
      @repo.add('file.txt')
      @repo.commit('Initial commit')
      @repo.add_tag('v1.0', message: 'Version 1.0', annotate: true)
    end

    @commit = @repo.gcommit('HEAD')
    @tree = @commit.gtree
    @blob = @tree.blobs['file.txt']
    @tag = @repo.tag('v1.0')
  end

  # Clean up the temporary repository after each test.
  def teardown
    FileUtils.rm_rf(@repo_path)
  end

  # Test that the factory method creates a Git::Object::Commit for a commit SHA.
  def test_new_creates_commit_object
    object = Git::Object.new(@repo, @commit.sha)
    assert_instance_of(Git::Object::Commit, object, 'Should create a Commit object.')
    assert(object.commit?, 'Object#commit? should be true.')
  end

  # Test that the factory method creates a Git::Object::Tree for a tree SHA.
  def test_new_creates_tree_object
    object = Git::Object.new(@repo, @tree.sha)
    assert_instance_of(Git::Object::Tree, object, 'Should create a Tree object.')
    assert(object.tree?, 'Object#tree? should be true.')
  end

  # Test that the factory method creates a Git::Object::Blob for a blob SHA.
  def test_new_creates_blob_object
    object = Git::Object.new(@repo, @blob.sha)
    assert_instance_of(Git::Object::Blob, object, 'Should create a Blob object.')
    assert(object.blob?, 'Object#blob? should be true.')
  end
end
