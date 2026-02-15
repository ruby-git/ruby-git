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

  def test_path_status_with_multiple_paths
    path_status = Git::DiffPathStatus.new(@git, 'gitsearch1', 'v2.5', ['scott/', 'example.txt'])
    status_hash = path_status.to_h

    assert_equal(3, status_hash.size)
    assert_equal('M', status_hash['example.txt'])
    assert_equal('D', status_hash['scott/newfile'])
    assert_equal('D', status_hash['scott/text.txt'])
  end

  def test_path_status_path_option_deprecated
    Git::Deprecation.expects(:warn).with('Git::Base#diff_path_status :path option is deprecated. Use :path_limiter instead.')

    status_hash = @git.diff_path_status('gitsearch1', 'v2.5', path: 'scott/').to_h
    assert(status_hash.key?('scott/newfile'))
  end

  def test_path_status_path_limiter_takes_precedence
    Git::Deprecation.expects(:warn).never

    status_hash = @git.diff_path_status('gitsearch1', 'v2.5', path: 'scott/', path_limiter: 'example.txt').to_h

    assert_equal(1, status_hash.size)
    assert_equal('M', status_hash['example.txt'])
  end

  def test_lib_path_status_path_option_deprecated
    Git::Deprecation.expects(:warn).with('Git::Lib#diff_path_status :path option is deprecated. Use :path_limiter instead.')

    status_hash = @git.lib.diff_path_status('gitsearch1', 'v2.5', path: 'scott/')
    assert(status_hash.key?('scott/newfile'))
  end

  def test_path_status_with_empty_path_array
    status = Struct.new(:success?, :exitstatus) { def exitstatus = 0 }.new(true)
    result = Git::CommandLineResult.new(%w[git diff], status, '', '')
    raw_cmd = Git::Commands::Diff::Raw.new(@git.lib)
    Git::Commands::Diff::Raw.expects(:new).with(@git.lib).returns(raw_cmd)
    raw_cmd.expects(:call).with('gitsearch1', 'v2.5', pathspecs: nil).returns(result)

    status_hash = Git::DiffPathStatus.new(@git, 'gitsearch1', 'v2.5', []).to_h
    assert_equal({}, status_hash)
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
