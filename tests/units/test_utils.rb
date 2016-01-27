#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../test_helper'

class TestUtils < Test::Unit::TestCase

  def test_uri_to_ssh
    assert_equal('git@github.com:user/repo.git', Git::Utils.url_to_ssh('https://github.com/user/repo.git'))
    assert_equal('git@bitbucket.org:user/repo.git', Git::Utils.url_to_ssh('https://bitbucket.org/user/repo.git'))
    assert_equal('git@github.com:user/repo.git', Git::Utils.url_to_ssh('git@github.com:user/repo.git'))
    assert_equal('git@bitbucket.org:user/repo.git', Git::Utils.url_to_ssh('git@bitbucket.org:user/repo.git'))
  end

end
