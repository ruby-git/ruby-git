# frozen_string_literal: true

require 'test_helper'

class TestDiffStats < Test::Unit::TestCase
  def setup
    clone_working_repo
    @git = Git.open(@wdir)
  end

  def test_total_stats
    stats = @git.diff_stats('gitsearch1', 'v2.5')

    assert_equal(3, stats.total[:files])
    assert_equal(74, stats.total[:lines])
    assert_equal(10, stats.total[:deletions])
    assert_equal(64, stats.total[:insertions])
  end

  def test_file_stats
    stats = @git.diff_stats('gitsearch1', 'v2.5')
    assert_equal(1, stats.files['scott/newfile'][:deletions])
    # CORRECTED: A deleted file should have 0 insertions.
    assert_equal(0, stats.files['scott/newfile'][:insertions])
  end

  def test_diff_stats_with_path
    stats = Git::DiffStats.new(@git, 'gitsearch1', 'v2.5', 'scott/')

    assert_equal(2, stats.total[:files])
    assert_equal(9, stats.total[:lines])
    assert_equal(9, stats.total[:deletions])
    assert_equal(0, stats.total[:insertions])
  end

  def test_diff_stats_on_object
    stats = @git.diff_stats('v2.5', 'gitsearch1')
    assert_equal(10, stats.insertions)
    assert_equal(64, stats.deletions)
  end

  def test_diff_stats_with_bad_commit
    # CORRECTED: No longer need to call a method, error is raised on initialize.
    assert_raise(ArgumentError) do
      @git.diff_stats('-s')
    end

    assert_raise(ArgumentError) do
      @git.diff_stats('gitsearch1', '-s')
    end
  end
end
