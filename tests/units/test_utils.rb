#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../test_helper'

class TestUtils < Test::Unit::TestCase

  def test_uri_to_ssh
    assert_equal('user',
                 Git::Utils.url_to_ssh('https://user@github.com/project/repo.git/branch/develop').user)
    assert_equal('git',
                 Git::Utils.url_to_ssh('https://github.com/project/repo.git/branch/develop').user)
    assert_equal('project/repo.git',
                 Git::Utils.url_to_ssh('https://user@github.com/project/repo.git').repo)
    assert_equal('project/repo.git',
                 Git::Utils.url_to_ssh('https://user@github.com/project/repo.git/branch/develop').repo)
    assert_equal('develop',
                 Git::Utils.url_to_ssh('https://user@github.com/project/repo.git/branch/develop').branch)
    assert_equal(nil,
                 Git::Utils.url_to_ssh('https://user@github.com/project/repo.git').branch)
    assert_equal('user@github.com:project/repo.git',
                 Git::Utils.url_to_ssh('https://user@github.com/project/repo.git').to_repo_s)
    assert_equal('user@github.com:project/repo.git',
                 Git::Utils.url_to_ssh('https://user@github.com/project/repo.git/branch/develop').to_repo_s)
    assert_equal('git@github.com:project/repo.git',
                 Git::Utils.url_to_ssh('https://github.com/project/repo.git').to_s)
    assert_equal('git@bitbucket.org:project/repo.git',
                 Git::Utils.url_to_ssh('https://bitbucket.org/project/repo.git').to_s)
    assert_equal('git@github.com:project/repo.git',
                 Git::Utils.url_to_ssh('git@github.com:project/repo.git').to_s)
    assert_equal('user@github.com:project/repo.git',
                 Git::Utils.url_to_ssh('https://user@github.com/project/repo.git').to_s)
    assert_equal('user@github.com:project/repo.git/branch/develop',
                 Git::Utils.url_to_ssh('https://user@github.com/project/repo.git/branch/develop').to_s)
  end

end
