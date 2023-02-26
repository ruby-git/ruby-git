#!/usr/bin/env ruby

require 'test_helper'

class TestBranch < Test::Unit::TestCase
  def setup
    clone_working_repo
    @git = Git.open(@wdir)

    @commit = @git.object('1cc8667014381')
    @tree = @git.object('1cc8667014381^{tree}')
    @blob = @git.object('v2.5:example.txt')

    @branches = @git.branches
  end

  def test_branches_all
    assert(@git.branches[:master].is_a?(Git::Branch))
    assert(@git.branches.size > 5)
  end

  def test_branches_local
    bs = @git.branches.local
    assert(bs.size > 4)
  end

  def test_branches_remote
    bs = @git.branches.remote
    assert_equal(1, bs.size)
  end

  def test_branches_single
    branch = @git.branches[:test_object]
    assert_equal('test_object', branch.name)

    %w{working/master remotes/working/master}.each do |branch_name|
      branch = @git.branches[branch_name]

      assert_equal('master', branch.name)
      assert_equal('remotes/working/master', branch.full)
      assert_equal('working', branch.remote.name)
      assert_equal('+refs/heads/*:refs/remotes/working/*', branch.remote.fetch_opts)
      assert_equal('../working.git', branch.remote.url)
    end
  end

  def test_true_branch_contains?
    assert(@git.branch('git_grep').contains?('master'))
  end

  def test_false_branch_contains?
    assert(!@git.branch('master').contains?('git_grep'))
  end

  def test_branch_commit
    assert_equal(270, @git.branches[:test_branches].gcommit.size)
  end

  def test_branch_create_and_switch
    in_bare_repo_clone do |git|
      assert(!git.branch('new_branch').current)
      git.branch('other_branch').create
      assert(!git.branch('other_branch').current)
      git.branch('new_branch').checkout
      assert(git.branch('new_branch').current)

      assert_equal(1, git.branches.select { |b| b.name == 'new_branch' }.size)

      new_file('test-file1', 'blahblahblah1')
      new_file('test-file2', 'blahblahblah2')
      new_file('.test-dot-file1', 'blahblahblahdot1')
      assert(git.status.untracked.assoc('test-file1'))
      assert(git.status.untracked.assoc('.test-dot-file1'))

      git.add(['test-file1', 'test-file2'])
      assert(!git.status.untracked.assoc('test-file1'))

      git.reset
      assert(git.status.untracked.assoc('test-file1'))
      assert(!git.status.added.assoc('test-file1'))

      assert_raise Git::FailedError do
        git.branch('new_branch').delete
      end
      assert_equal(1, git.branches.select { |b| b.name == 'new_branch' }.size)

      git.branch('master').checkout
      git.branch('new_branch').delete
      assert_equal(0, git.branches.select { |b| b.name == 'new_branch' }.size)

      git.checkout('other_branch')
      assert(git.branch('other_branch').current)

      git.checkout('master')
      assert(!git.branch('other_branch').current)

      git.checkout(@git.branch('other_branch'))
      assert(git.branch('other_branch').current)
    end
  end

  def test_branch_update_ref
    in_temp_dir do |path|
      git = Git.init
      File.write('foo','rev 1')
      git.add('foo')
      git.commit('rev 1')
      git.branch('testing').create
      File.write('foo','rev 2')
      git.add('foo')
      git.commit('rev 2')
      git.branch('testing').update_ref(git.revparse('HEAD'))

      # Expect the call to Branch#update_ref to pass the full ref name for the
      # of the testing branch to Lib#update_ref
      assert_equal(git.revparse('HEAD'), git.revparse('refs/heads/testing'))
    end
  end
end
