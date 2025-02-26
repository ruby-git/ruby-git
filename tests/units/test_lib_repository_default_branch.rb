# frozen_string_literal: true

require File.dirname(__FILE__) + '/../test_helper'

# Tests for Git::Lib#repository_default_branch
#
class TestLibRepositoryDefaultBranch < Test::Unit::TestCase
  def setup
    clone_working_repo
    @git = Git.open(@wdir)

    @lib = Git.open(@wdir).lib
  end

  # This is the one real test that actually calls git.  The rest of the tests
  # mock Git::Lib#command to return specific responses.
  #
  def test_local_repository
    in_temp_dir do
      git = Git.init('new_repo', initial_branch: 'main')
      FileUtils.cd('new_repo') do
        File.write('README.md', '# This is a README')
        git.add('README.md')
        git.commit('Initial commit')
      end
      FileUtils.touch('new_repo/README.md')

      assert_equal('main', @lib.repository_default_branch('new_repo'))
    end
  end

  def mock_command(lib, repository, response)
    test_case = self
    lib.define_singleton_method(:command) do |cmd, *opts, &_block|
      test_case.assert_equal('ls-remote', cmd)
      test_case.assert_equal(['--symref', '--', repository, 'HEAD'], opts.flatten)
      response
    end
  end

  def test_remote_repository
    repository = 'https://github.com/ruby-git/ruby-git'
    mock_command(@lib, repository, <<~RESPONSE)
      ref: refs/heads/default_branch\tHEAD
      292087efabc8423c3cf616d78fac5311d58e7425\tHEAD
    RESPONSE
    assert_equal('default_branch', @lib.repository_default_branch(repository))
  end

  def test_local_repository_with_origin
    repository = 'https://github.com/ruby-git/ruby-git'
    mock_command(@lib, repository, <<~RESPONSE)
      ref: refs/heads/master\tHEAD
      292087efabc8423c3cf616d78fac5311d58e7425\tHEAD
      ref: refs/remotes/origin/default_branch\trefs/remotes/origin/HEAD
      292087efabc8423c3cf616d78fac5311d58e7425\trefs/remotes/origin/HEAD
    RESPONSE
    assert_equal('default_branch', @lib.repository_default_branch(repository))
  end

  def test_local_repository_without_remotes
    repository = '.'
    mock_command(@lib, repository, <<~RESPONSE)
      ref: refs/heads/default_branch\tHEAD
      d7b79c31113c42c7aa3fe915186c1d6bcd3fbd39\tHEAD
    RESPONSE
    assert_equal('default_branch', @lib.repository_default_branch(repository))
  end

  def test_repository_with_no_commits
    # Local or remote, the result is the same
    repository = '.'
    mock_command(@lib, repository, '')
    assert_raise_with_message(Git::UnexpectedResultError, 'Unable to determine the default branch') do
      @lib.repository_default_branch(repository)
    end
  end

  def test_repository_not_found
    # Local or remote, the result is the same
    repository = 'does_not_exist'
    assert_raise(Git::FailedError) do
      @lib.repository_default_branch(repository)
    end
  end

  def test_not_a_repository
    in_temp_dir do
      repository = 'exists_but_not_a_repository'
      FileUtils.mkdir repository
      assert_raise(Git::FailedError) do
        @lib.repository_default_branch(repository)
      end
    end
  end
end
