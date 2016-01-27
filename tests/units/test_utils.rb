#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../test_helper'

class TestUtils < Test::Unit::TestCase

  def test_uri_to_ssh
    assert_equal('git@github.com:project/repo.git',
                 Git::Utils.url_to_ssh('https://github.com/project/repo.git').to_s)
    assert_equal('git@bitbucket.org:project/repo.git',
                 Git::Utils.url_to_ssh('https://bitbucket.org/project/repo.git').to_s)
    assert_equal('git@github.com:project/repo.git',
                 Git::Utils.url_to_ssh('git@github.com:project/repo.git').to_s)
    assert_equal('user@github.com:project/repo.git',
                 Git::Utils.url_to_ssh('https://user@github.com/project/repo.git').to_s)
  end

end
