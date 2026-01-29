# frozen_string_literal: true

require 'logger'
require 'test_helper'

class TestLog < Test::Unit::TestCase
  def setup
    clone_working_repo
    # @git = Git.open(@wdir, :log => Logger.new(STDOUT))
    @git = Git.open(@wdir)
  end

  def test_log_max_count_default
    # Default max_count is 30
    commits = @git.log.execute
    assert_equal(30, commits.size)
  end

  # In these tests, note that @git.log(n) is equivalent to @git.log.max_count(n)
  def test_log_max_count_twenty
    max_count = 20
    commits = @git.log(max_count).execute
    assert_equal(20, commits.size)
    commits = @git.log.max_count(max_count).execute
    assert_equal(20, commits.size)
  end

  def test_log_max_count_nil
    # nil should return all commits
    max_count = nil
    commits = @git.log(max_count).execute
    assert_equal(72, commits.size)
    commits = @git.log.max_count(max_count).execute
    assert_equal(72, commits.size)
  end

  def test_log_max_count_all
    max_count = :all
    commits = @git.log(max_count).execute
    assert_equal(72, commits.size)
    commits = @git.log.max_count(max_count).execute
    assert_equal(72, commits.size)
  end

  # Note that @git.log.all does not control the number of commits returned. For that,
  # use @git.log.max_count(n)
  def test_log_all
    commits = @git.log(100).execute
    assert_equal(72, commits.size)
    commits = @git.log(100).all.execute
    assert_equal(76, commits.size)
  end

  def test_log_non_integer_count
    assert_raises(ArgumentError) do
      commits = @git.log('foo').execute
      commits.size
    end
  end

  def test_get_first_and_last_entries
    log = @git.log
    commits = log.execute
    assert(commits.first.is_a?(Git::Object::Commit))
    assert_equal('46abbf07e3c564c723c7c039a43ab3a39e5d02dd', commits.first.objectish)

    assert(commits.last.is_a?(Git::Object::Commit))
    assert_equal('b03003311ad3fa368b475df58390353868e13c91', commits.last.objectish)
  end

  def test_get_log_entries
    assert_equal(30, @git.log.execute.size)
    assert_equal(50, @git.log(50).execute.size)
    assert_equal(10, @git.log(10).execute.size)
  end

  def test_get_log_to_s
    commits = @git.log.execute
    first_line = commits.to_s.split("\n").first
    first_sha = commits.first.sha
    assert_equal(first_line, first_sha)
  end

  def test_log_skip
    three1 = @git.log(3).execute.to_a[-1]
    three2 = @git.log(2).skip(1).execute.to_a[-1]
    three3 = @git.log(1).skip(2).execute.to_a[-1]
    assert_equal(three2.sha, three3.sha)
    assert_equal(three1.sha, three2.sha)
  end

  def test_get_log_since
    commits = @git.log.since('2 seconds ago').execute
    assert_equal(0, commits.size)

    commits = @git.log.since("#{Date.today.year - 2006} years ago").execute
    assert_equal(30, commits.size)
  end

  def test_get_log_grep
    commits = @git.log.grep('search').execute
    assert_equal(2, commits.size)
  end

  def test_get_log_author
    commits = @git.log(5).author('chacon').execute
    assert_equal(5, commits.size)
    commits = @git.log(5).author('lazySusan').execute
    assert_equal(0, commits.size)
  end

  def test_get_log_since_file
    commits = @git.log.path('example.txt').execute
    assert_equal(30, commits.size)

    commits = @git.log.between('v2.5', 'test').path('example.txt').execute
    assert_equal(1, commits.size)
  end

  def test_get_log_path
    commits = @git.log.path('example.txt').execute
    assert_equal(30, commits.size)
    commits = @git.log.path('example*').execute
    assert_equal(30, commits.size)
    commits = @git.log.path(['example.txt', 'scott/text.txt']).execute
    assert_equal(30, commits.size)
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
      commits = git.log.execute
      assert_equal(2, commits.size)
      assert_equal('', commits[0].message)
      assert_equal(expected_message, commits[1].message)
    end
  end

  def test_log_cherry
    commits = @git.log.between('master', 'cherry').cherry.execute
    assert_equal(1, commits.size)
  end

  def test_log_merges
    expected_command_line = ['log', '--no-color', '--max-count=30', '--pretty=raw', '--merges', {}]
    assert_command_line_eq(expected_command_line) do |git|
      git.log.merges.execute
    end
  end
end
