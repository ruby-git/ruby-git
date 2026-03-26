# frozen_string_literal: true

require 'test_helper'

class TestEachConflict < Test::Unit::TestCase
  def test_unmerged_returns_empty_when_no_conflicts
    in_temp_repo('working') do
      g = Git.open('.')
      assert_equal([], g.lib.unmerged)
    end
  end

  def test_conflicts
    in_temp_repo('working') do
      # Setup a repository with a conflict
      g = Git.open('.')

      g.branch('new_branch').in_branch('commit message') do
        new_file('example.txt', "1\n2\n3")
        g.add
        true
      end

      g.branch('new_branch2').in_branch('test') do
        new_file('example.txt', "1\n4\n3")
        g.add
        true
      end

      g.merge('new_branch')

      begin
        g.merge('new_branch2')
      rescue Git::FailedError => e
        assert_equal(1, e.result.status.exitstatus)
        assert_match(/CONFLICT/, e.result.stdout)
      end

      assert_equal(['example.txt'], g.lib.unmerged)

      # Check the conflict
      g.each_conflict do |file, your, their|
        assert_equal('example.txt', file)
        assert_equal("1\n2\n3\n", File.read(your))
        assert_equal("1\n4\n3\n", File.read(their))
      end
    end
  end

  def test_unmerged_returns_all_conflicting_files
    in_temp_repo('working') do
      g = Git.open('.')

      g.branch('branch_a').in_branch('branch a changes') do
        new_file('file1.txt', "a\nb\nc")
        new_file('file2.txt', "x\ny\nz")
        g.add
        true
      end

      g.branch('branch_b').in_branch('branch b changes') do
        new_file('file1.txt', "a\nB\nc")
        new_file('file2.txt', "x\nY\nz")
        g.add
        true
      end

      g.merge('branch_a')

      begin
        g.merge('branch_b')
      rescue Git::FailedError
        # expected conflict
      end

      assert_equal(['file1.txt', 'file2.txt'], g.lib.unmerged.sort)
    end
  end
end
