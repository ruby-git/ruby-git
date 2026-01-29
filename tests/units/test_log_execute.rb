# frozen_string_literal: true

require 'logger'
require 'test_helper'

# Tests for the Git::Log#execute method
class TestLogExecute < Test::Unit::TestCase
  def setup
    clone_working_repo
    # @git = Git.open(@wdir, :log => Logger.new(STDOUT))
    @git = Git.open(@wdir)
  end

  def test_log_max_count_default
    assert_equal(30, @git.log.execute.size)
  end

  # In these tests, note that @git.log(n) is equivalent to @git.log.max_count(n)
  def test_log_max_count_twenty
    assert_equal(20, @git.log(20).execute.size)
    assert_equal(20, @git.log.max_count(20).execute.size)
  end

  def test_log_max_count_nil
    assert_equal(72, @git.log(nil).execute.size)
    assert_equal(72, @git.log.max_count(nil).execute.size)
  end

  def test_log_max_count_all
    assert_equal(72, @git.log(:all).execute.size)
    assert_equal(72, @git.log.max_count(:all).execute.size)
  end

  # Note that @git.log.all does not control the number of commits returned. For that,
  # use @git.log.max_count(n)
  def test_log_all
    assert_equal(72, @git.log(100).execute.size)
    assert_equal(76, @git.log(100).all.execute.size)
  end

  def test_log_non_integer_count
    assert_raises(ArgumentError) { @git.log('foo').execute }
  end

  def test_get_first_and_last_entries
    log = @git.log.execute
    assert(log.first.is_a?(Git::Object::Commit))
    assert_equal('46abbf07e3c564c723c7c039a43ab3a39e5d02dd', log.first.objectish)

    assert(log.last.is_a?(Git::Object::Commit))
    assert_equal('b03003311ad3fa368b475df58390353868e13c91', log.last.objectish)
  end

  def test_get_log_entries
    assert_equal(30, @git.log.execute.size)
    assert_equal(50, @git.log(50).execute.size)
    assert_equal(10, @git.log(10).execute.size)
  end

  def test_get_log_to_s
    log = @git.log.execute
    assert_equal(log.to_s.split("\n").first, log.first.sha)
  end

  def test_log_skip
    three1 = @git.log(3).execute.to_a[-1]
    three2 = @git.log(2).skip(1).execute.to_a[-1]
    three3 = @git.log(1).skip(2).execute.to_a[-1]
    assert_equal(three2.sha, three3.sha)
    assert_equal(three1.sha, three2.sha)
  end

  def test_get_log_since
    l = @git.log.since('2 seconds ago').execute
    assert_equal(0, l.size)

    l = @git.log.since("#{Date.today.year - 2006} years ago").execute
    assert_equal(30, l.size)
  end

  def test_get_log_grep
    l = @git.log.grep('search').execute
    assert_equal(2, l.size)
  end

  def test_get_log_author
    l = @git.log(5).author('chacon').execute
    assert_equal(5, l.size)
    l = @git.log(5).author('lazySusan').execute
    assert_equal(0, l.size)
  end

  def test_get_log_since_file
    l = @git.log.path('example.txt').execute
    assert_equal(30, l.size)

    l = @git.log.between('v2.5', 'test').path('example.txt').execute
    assert_equal(1, l.size)
  end

  def test_get_log_path
    log = @git.log.path('example.txt').execute
    assert_equal(30, log.size)
    log = @git.log.path('example*').execute
    assert_equal(30, log.size)
    log = @git.log.path(['example.txt', 'scott/text.txt']).execute
    assert_equal(30, log.size)
  end

  def test_log_file_noexist
    assert_raise Git::FailedError do
      @git.log.object('no-exist.txt').execute
    end
  end

  def test_log_with_empty_commit_message
    Dir.mktmpdir do |dir|
      git = Git.init(dir)
      expected_message = 'message'
      git.commit(expected_message, { allow_empty: true })
      git.commit('', { allow_empty: true, allow_empty_message: true })
      log = git.log.execute
      assert_equal(2, log.to_a.size)
      assert_equal('', log[0].message)
      assert_equal(expected_message, log[1].message)
    end
  end

  def test_log_cherry
    l = @git.log.between('master', 'cherry').cherry.execute
    assert_equal(1, l.size)
  end

  def test_log_merges
    expected_command_line = ['log', '--no-color', '--max-count=30', '--pretty=raw', '--merges', {}]
    assert_command_line_eq(expected_command_line) { |git| git.log.merges.execute }
  end

  def test_execute_returns_immutable_results
    log_query = @git.log(10)
    initial_results = log_query.execute
    assert_equal(10, initial_results.size)

    # Modify the original query object
    log_query.max_count(5)
    new_results = log_query.execute

    # The initial result set should not have changed
    assert_equal(10, initial_results.size)

    # The new result set should reflect the change
    assert_equal(5, new_results.size)
  end
end
