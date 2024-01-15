#!/usr/bin/env ruby

require 'test_helper'

class TestConfig < Test::Unit::TestCase
  def setup
    clone_working_repo
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
    assert_not_equal('bully', @git.config('user.name'))
    @git.config('user.name', 'bully')
    assert_equal('bully', @git.config('user.name'))
  end

  def test_set_config_with_custom_file
    Dir.chdir(@wdir) do
      custom_config_path = "#{Dir.pwd}/.git/custom-config"
      assert_not_equal('bully', @git.config('user.name'))
      @git.config('user.name', 'bully', file: custom_config_path)
      assert_not_equal('bully', @git.config('user.name'))
      @git.config('include.path', custom_config_path)
      assert_equal('bully', @git.config('user.name'))
      assert_equal("[user]\n\tname = bully\n", File.read(custom_config_path))
    end
  end

  def test_env_config
    begin
      assert_equal(Git::Base.config.binary_path, 'git')
      assert_equal(Git::Base.config.git_ssh, nil)

      ENV['GIT_PATH'] = '/env/bin'
      ENV['GIT_SSH'] = '/env/git/ssh'

      assert_equal(Git::Base.config.binary_path, '/env/bin/git')
      assert_equal(Git::Base.config.git_ssh, '/env/git/ssh')

      Git.configure do |config|
        config.binary_path = '/usr/bin/git'
        config.git_ssh = '/path/to/ssh/script'
      end

      assert_equal(Git::Base.config.binary_path, '/usr/bin/git')
      assert_equal(Git::Base.config.git_ssh, '/path/to/ssh/script')

      @git.log
    ensure
      ENV['GIT_SSH'] = nil
      ENV['GIT_PATH'] = nil

      Git.configure do |config|
        config.binary_path = nil
        config.git_ssh = nil
      end
    end
  end
end
