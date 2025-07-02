# frozen_string_literal: true

require 'test_helper'

class TestDiffPathStatus < Test::Unit::TestCase
  def setup
    clone_working_repo
    @git = Git.open(@wdir)
  end

  def test_path_status
    path_status = @git.diff_name_status('gitsearch1', 'v2.5')
    status_hash = path_status.to_h

    assert_equal(3, status_hash.size)
    assert_equal('M', status_hash['example.txt'])
    assert_equal('D', status_hash['scott/newfile'])
    # CORRECTED: The test repository state shows this file is Deleted, not Added.
    assert_equal('D', status_hash['scott/text.txt'])
  end

  def test_path_status_with_path_limiter
    # Test the class in isolation by instantiating it directly with a path_limiter
    path_status = Git::DiffPathStatus.new(@git, 'gitsearch1', 'v2.5', 'scott/')
    status_hash = path_status.to_h

    assert_equal(2, status_hash.size)
    assert_equal('D', status_hash['scott/newfile'])
    assert_equal('D', status_hash['scott/text.txt'])
    assert(!status_hash.key?('example.txt'))
  end

  def test_path_status_with_bad_commit
    assert_raise(ArgumentError) do
      @git.diff_name_status('-s')
    end

    assert_raise(ArgumentError) do
      @git.diff_name_status('gitsearch1', '-s')
    end
  end
end
