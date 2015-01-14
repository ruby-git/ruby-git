#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../test_helper'

class TestConfig < Test::Unit::TestCase
  def setup
    set_file_paths
    @git = Git.open(@wdir)
  end
  
  def test_config
    c = @git.config
    assert_equal('Scott Chacon', c['user.name'])
    assert_equal('false', c['core.bare'])
  end
  
  def test_read_config
    assert_equal('Scott Chacon', @git.config('user.name'))
    assert_equal('false', @git.config('core.bare'))
  end
  
  def test_set_config
    in_temp_dir do |path|
      g = Git.clone(@wbare, 'bare')
      assert_not_equal('bully', g.config('user.name'))
      g.config('user.name', 'bully')
      assert_equal('bully', g.config('user.name'))
    end
  end  

  def test_env_config
    assert_equal(Git::Base.config.git_ssh, nil)
    
    ENV['GIT_SSH'] = '/env/git/ssh'

    assert_equal(Git::Base.config.git_ssh, '/env/git/ssh')

    Git.configure do |config|
      config.binary_path = '/usr/bin/git'
      config.git_ssh = '/path/to/ssh/script'
    end
    
    assert_equal(Git::Base.config.git_ssh, '/path/to/ssh/script')

    @git.log
  ensure
    ENV['GIT_SSH'] = nil

    Git.configure do |config|
      config.binary_path = nil
      config.git_ssh = nil
    end
  end
  
end
