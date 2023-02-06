#!/usr/bin/env ruby

require 'test_helper'

class TestMergeBase < Test::Unit::TestCase
  def test_branch_and_master_merge_base
    in_bare_repo_clone do |repo|
      true_ancestor_sha = repo.gcommit('master').sha

      add_commit(repo, 'new_branch')
      add_commit(repo, 'master')

      ancestors = repo.merge_base('master', 'new_branch')
      assert_equal(ancestors.size, 1) # there is only one true ancestor
      assert_equal(ancestors.first.sha, true_ancestor_sha) # proper common ancestor
    end
  end

  def test_branch_and_master_independent_merge_base
    in_bare_repo_clone do |repo|
      true_ancestor_sha = repo.gcommit('master').sha

      add_commit(repo, 'new_branch')
      add_commit(repo, 'master')

      independent_commits = repo.merge_base(true_ancestor_sha, 'master', 'new_branch', independent: true)
      assert_equal(independent_commits.size, 2) # both new master and a branch are unreachable from each other
      true_independent_commits_shas = [repo.gcommit('master').sha, repo.gcommit('new_branch').sha]
      assert_equal(independent_commits.map(&:sha).sort, true_independent_commits_shas.sort)
    end
  end

  def test_branch_and_master_fork_point_merge_base
    in_bare_repo_clone do |repo|
      add_commit(repo, 'master')

      true_ancestor_sha = repo.gcommit('master').sha

      add_commit(repo, 'new_branch')

      repo.reset_hard(repo.gcommit('HEAD^'))

      add_commit(repo, 'master')

      ancestors = repo.merge_base('master', 'new_branch', fork_point: true)
      assert_equal(ancestors.size, 1) # there is only one true ancestor
      assert_equal(ancestors.first.sha, true_ancestor_sha) # proper common ancestor
    end
  end

  def test_branch_and_master_all_merge_base
    in_bare_repo_clone do |repo|
      add_commit(repo, 'new_branch_1')

      first_commit_sha = repo.gcommit('new_branch_1').sha

      add_commit(repo, 'new_branch_2')

      second_commit_sha = repo.gcommit('new_branch_2').sha

      repo.branch('new_branch_1').merge('new_branch_2')
      repo.branch('new_branch_2').merge('new_branch_1^')

      add_commit(repo, 'new_branch_1')
      add_commit(repo, 'new_branch_2')

      true_ancestors_shas = [first_commit_sha, second_commit_sha]

      ancestors = repo.merge_base('new_branch_1', 'new_branch_2')
      assert_equal(ancestors.size, 1) # default behavior returns only one ancestor
      assert(true_ancestors_shas.include?(ancestors.first.sha))

      all_ancestors = repo.merge_base('new_branch_1', 'new_branch_2', all: true)
      assert_equal(all_ancestors.size, 2) # there are two best ancestors in such case
      assert_equal(all_ancestors.map(&:sha).sort, true_ancestors_shas.sort)
    end
  end

  def test_branches_and_master_merge_base
    in_bare_repo_clone do |repo|
      add_commit(repo, 'new_branch_1')
      add_commit(repo, 'master')

      non_octopus_ancestor_sha = repo.gcommit('master').sha

      add_commit(repo, 'new_branch_2')
      add_commit(repo, 'master')

      ancestors = repo.merge_base('master', 'new_branch_1', 'new_branch_2')
      assert_equal(ancestors.size, 1) # there is only one true ancestor
      assert_equal(ancestors.first.sha, non_octopus_ancestor_sha) # proper common ancestor
    end
  end

  def test_branches_and_master_octopus_merge_base
    in_bare_repo_clone do |repo|
      true_ancestor_sha = repo.gcommit('master').sha

      add_commit(repo, 'new_branch_1')
      add_commit(repo, 'master')
      add_commit(repo, 'new_branch_2')
      add_commit(repo, 'master')

      ancestors = repo.merge_base('master', 'new_branch_1', 'new_branch_2', octopus: true)
      assert_equal(ancestors.size, 1) # there is only one true ancestor
      assert_equal(ancestors.first.sha, true_ancestor_sha) # proper common ancestor
    end
  end

  private

  def add_commit(repo, branch_name)
    @commit_number ||= 0
    @commit_number += 1

    repo.branch(branch_name).in_branch("test commit #{@commit_number}") do
      new_file("new_file_#{@commit_number}", 'hello')
      repo.add
      true
    end
  end
end
