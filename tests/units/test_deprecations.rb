# frozen_string_literal: true

require_relative '../test_helper'

# Consolidated deprecation tests to ensure all deprecated entry points emit
# Git::Deprecation warnings and still behave as expected.
class TestDeprecations < Test::Unit::TestCase
  def setup
    clone_working_repo
    @git = Git.open(@wdir)
  end

  def teardown
    # Cleanup handled by TestCase#git_teardown
  end

  # --- Git::Base deprecations ---

  def test_base_is_local_branch_deprecation
    Git::Deprecation.expects(:warn).with(
      'Git::Base#is_local_branch? is deprecated and will be removed in a future version. ' \
      'Use Git::Base#local_branch? instead.'
    )

    assert_equal(true, @git.is_local_branch?(@git.current_branch))
  end

  def test_base_is_remote_branch_deprecation
    Git::Deprecation.expects(:warn).with(
      'Git::Base#is_remote_branch? is deprecated and will be removed in a future version. ' \
      'Use Git::Base#remote_branch? instead.'
    )

    # No remotes in fixture; method should return false
    assert_equal(false, @git.is_remote_branch?('origin/master'))
  end

  def test_base_is_branch_deprecation
    Git::Deprecation.expects(:warn).with(
      'Git::Base#is_branch? is deprecated and will be removed in a future version. ' \
      'Use Git::Base#branch? instead.'
    )

    assert_equal(true, @git.is_branch?(@git.current_branch))
  end

  def test_base_set_index_check_arg_deprecation
    require 'tempfile'
    tmp = Tempfile.new('index')
    tmp.close

    Git::Deprecation.expects(:warn).with(
      'The "check" argument is deprecated and will be removed in a future version. ' \
      'Use "must_exist:" instead.'
    )

    # Ensure must_exist is provided to avoid nil | check
    @git.set_index(tmp.path, false, must_exist: true)
    assert_instance_of(Git::Index, @git.index)
  ensure
    tmp&.unlink
  end

  def test_base_set_working_check_arg_deprecation
    Dir.mktmpdir('git_work') do |dir|
      Git::Deprecation.expects(:warn).with(
        'The "check" argument is deprecated and will be removed in a future version. ' \
        'Use "must_exist:" instead.'
      )

      @git.set_working(dir, false, must_exist: true)
      assert_equal(dir, @git.dir.to_s)
    end
  end

  # --- Git::Log deprecations ---

  def test_log_each_deprecation
    log = @git.log
    first_commit = @git.gcommit('HEAD')

    Git::Deprecation.expects(:warn).with(
      'Calling Git::Log#each is deprecated. Call #execute and then #each on the result object.'
    )

    commits = log.map { |c| c }
    assert_equal(first_commit.sha, commits.first.sha)
  end

  def test_log_size_deprecation
    log = @git.log
    Git::Deprecation.expects(:warn).with(
      'Calling Git::Log#size is deprecated. Call #execute and then #size on the result object.'
    )
    assert_operator(log.size, :>=, 1)
  end

  def test_log_to_s_deprecation
    log = @git.log
    first_commit = @git.gcommit('HEAD')

    Git::Deprecation.expects(:warn).with(
      'Calling Git::Log#to_s is deprecated. Call #execute and then #to_s on the result object.'
    )
    assert_match(first_commit.sha, log.to_s)
  end

  def test_log_first_deprecation
    log = @git.log
    first_commit = @git.gcommit('HEAD')

    Git::Deprecation.expects(:warn).with(
      'Calling Git::Log#first is deprecated. Call #execute and then #first on the result object.'
    )
    assert_equal(first_commit.sha, log.first.sha)
  end

  def test_log_last_deprecation
    log = @git.log
    # Determine expected last via modern API to avoid assumptions about repo history
    expected_last_sha = log.execute.last.sha

    Git::Deprecation.expects(:warn).with(
      'Calling Git::Log#last is deprecated. Call #execute and then #last on the result object.'
    )
    assert_equal(expected_last_sha, log.last.sha)
  end

  def test_log_indexer_deprecation
    log = @git.log
    first_commit = @git.gcommit('HEAD')

    Git::Deprecation.expects(:warn).with(
      'Calling Git::Log#[] is deprecated. Call #execute and then #[] on the result object.'
    )
    assert_equal(first_commit.sha, log[0].sha)
  end

  # --- Git::Object deprecations ---

  def test_object_new_is_tag_deprecation
    # The `objectish` here is the tag name, as was the old pattern.
    tag_name = 'v2.8' # Present in fixtures

    Git::Deprecation.expects(:warn).with(
      'Git::Object.new with is_tag argument is deprecated. Use Git::Object::Tag.new instead.'
    )

    tag_object = Git::Object.new(@git, tag_name, nil, true)
    assert_instance_of(Git::Object::Tag, tag_object)
    assert(tag_object.tag?)
  end

  def test_commit_set_commit_deprecation_warns_and_delegates
    commit = Git::Object::Commit.new(@git, 'deadbeef')

    data = {
      'sha' => 'deadbeef',
      'committer' => { 'name' => 'C', 'email' => 'c@example.com', 'date' => Time.now },
      'author' => { 'name' => 'A', 'email' => 'a@example.com', 'date' => Time.now },
      'tree' => 'cafebabe',
      'parent' => [],
      'message' => 'message'
    }

    Git::Deprecation.expects(:warn).with(
      'Git::Object::Commit#set_commit is deprecated and will be removed in a future version. ' \
      'Use #from_data instead.'
    )

    commit.expects(:from_data).with(data)
    commit.set_commit(data)
  end

  # --- Git::Lib deprecations ---

  def test_lib_warn_if_old_command_deprecation
    # Ensure class-level check does not short-circuit the call in this test
    Git::Lib.instance_variable_set(:@version_checked, nil)

    Git::Deprecation.expects(:warn).with(
      'Git::Lib#warn_if_old_command is deprecated. Use meets_required_version?.'
    )

    assert_equal(true, Git::Lib.warn_if_old_command(@git.lib))
  end

  # --- Git::Path deprecations ---

  def test_working_directory_path_accessor_deprecation
    Git::Deprecation.expects(:warn).with(
      'The .path accessor is deprecated and will be removed in v5.0. ' \
      'Use .to_s instead.'
    )

    @git.dir.path
  end

  def test_index_path_accessor_deprecation
    Git::Deprecation.expects(:warn).with(
      'The .path accessor is deprecated and will be removed in v5.0. ' \
      'Use .to_s instead.'
    )

    @git.index.path
  end

  def test_repository_path_accessor_deprecation
    Git::Deprecation.expects(:warn).with(
      'The .path accessor is deprecated and will be removed in v5.0. ' \
      'Use .to_s instead.'
    )

    @git.repo.path
  end
end
