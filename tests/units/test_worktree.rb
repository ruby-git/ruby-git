#!/usr/bin/env ruby
require 'fileutils'
require 'pathname'
require 'test_helper'

SAMPLE_LAST_COMMIT = '5e53019b3238362144c2766f02a2c00d91fcc023'

class TestWorktree < Test::Unit::TestCase
  def git_working_dir
    create_temp_repo('worktree')
  end

  def setup
    @git = Git.open(git_working_dir)

    @commit = @git.object('1cc8667014381')
    @tree = @git.object('1cc8667014381^{tree}')
    @blob = @git.object('v2.5:example.txt')

    @worktrees = @git.worktrees
  end

  def test_worktrees_all
    assert(@git.worktrees.is_a?(Git::Worktrees))
    assert(@git.worktrees.first.is_a?(Git::Worktree))
    assert_equal(@git.worktrees.size, 2)
  end

  def test_worktrees_single
    worktree = @git.worktrees.first
    git_dir = Pathname.new(@git.dir.to_s).realpath.to_s
    assert_equal(worktree.dir, git_dir)
    assert_equal(worktree.gcommit, SAMPLE_LAST_COMMIT)
  end

  def test_worktree_add_and_remove
    assert_equal(@git.worktrees.size, 2)

    @git.worktree('/tmp/pp1').add
    assert_equal(@git.worktrees.size, 3)
    @git.worktree('/tmp/pp1').remove
    assert_equal(@git.worktrees.size, 2)

    @git.worktree('/tmp/pp2', 'gitsearch1').add
    @git.worktree('/tmp/pp2').remove

    @git.worktree('/tmp/pp3', '34a566d193dc4702f03149969a2aad1443231560').add
    @git.worktree('/tmp/pp3').remove

    @git.worktree('/tmp/pp4', 'test_object').add
    @git.worktree('/tmp/pp4').remove

    assert_equal(@git.worktrees.size, 2)
  end

  def test_worktree_prune
    assert_equal(2, @git.worktrees.size)

    @git.worktree('/tmp/pp1').add
    assert_equal(3, @git.worktrees.size)
    @git.worktrees.prune
    assert_equal(2, @git.worktrees.size)
    FileUtils.rm_rf('/tmp/pp1')
    @git.worktrees.prune
    assert_equal(1, @git.worktrees.size)
  end
end
