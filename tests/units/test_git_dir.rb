#!/usr/bin/env ruby

require 'test_helper'

class TestGitDir < Test::Unit::TestCase
  def test_index_calculated_from_git_dir
    Dir.mktmpdir do |work_tree|
      Dir.mktmpdir do |git_dir|
        git = Git.open(work_tree, repository: git_dir)

        assert_equal(work_tree, git.dir.path)
        assert_equal(git_dir, git.repo.path)

        # Since :index was not given in the options to Git#open, index should
        # be defined automatically based on the git_dir.
        #
        index = File.join(git_dir, 'index')
        assert_equal(index, git.index.path)
      end
    end
  end

  # Test the case where the git-dir is not a subdirectory of work-tree
  #
  def test_git_dir_outside_work_tree
    Dir.mktmpdir do |work_tree|
      Dir.mktmpdir do |git_dir|
        # Setup a bare repository
        #
        source_git_dir = File.expand_path(File.join('tests', 'files', 'working.git'))
        FileUtils.cp_r(Dir["#{source_git_dir}/*"], git_dir, preserve: true)
        git = Git.open(work_tree, repository: git_dir)

        assert_equal(work_tree, git.dir.path)
        assert_equal(git_dir, git.repo.path)

        # Reconstitute the work tree from the bare repository
        #
        branch = 'master'
        git.checkout(branch, force: true)

        # Make sure the work tree contains the expected files
        #
        expected_files = %w[ex_dir example.txt].sort
        actual_files = Dir[File.join(work_tree, '*')].map { |f| File.basename(f) }.sort
        assert_equal(expected_files, actual_files)

        # None of the expected files should have a status that says it has been changed
        #
        expected_files.each do |file|
          assert_equal(false, git.status.changed?(file))
        end

        # Change a file and make sure it's status says it has been changed
        #
        file = 'example.txt'
        File.open(File.join(work_tree, file), "a") { |f| f.write("A new line") }
        assert_equal(true, git.status.changed?(file))

        # Add and commit the file and then check that:
        # * the file is not flagged as changed anymore
        # * the commit was added to the log
        #
        max_log_size = 100
        assert_equal(64, git.log(max_log_size).size)
        git.add(file)
        git.commit('This is a new commit')
        assert_equal(false, git.status.changed?(file))
        assert_equal(65, git.log(max_log_size).size)
      end
    end
  end

  # Test that Git::Lib::Diff.to_a works from a linked working tree (not the
  # main working tree).  See https://git-scm.com/docs/git-worktree for a
  # description of 'main' and 'linked' working tree.
  #
  # This is a real world case where '.git' in the working tree is a file
  # instead of a directory and where the value of GIT_INDEX_FILE is relevant.
  #
  def test_git_diff_to_a
    work_tree = Dir.mktmpdir
    begin
      Dir.chdir(work_tree) do
        `git init`
        `git commit --allow-empty -m 'init'`
        `git worktree add --quiet child`
        Dir.chdir('child') do
          result = Git.open('.').diff.to_a
          assert_equal([], result)
        end
      end
    ensure
      FileUtils.rm_rf(work_tree)
    end
  end
end
