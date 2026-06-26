# frozen_string_literal: true

require 'test_helper'

# Tests for the deprecated Git::Repository#config method.
# Git::Deprecation.silence is used around each call because the test helper
# configures Git::Deprecation.behavior = :raise and these tests intentionally
# exercise the deprecated method to verify backward-compatible behavior.
class TestConfig < Test::Unit::TestCase
  def setup
    clone_working_repo
    @git = Git.open(@wdir)
  end

  def test_config
    c = Git::Deprecation.silence { @git.config }
    assert_equal('Scott Chacon', c['user.name'])
    assert_equal('false', c['core.bare'])
  end

  def test_read_config
    assert_equal('Scott Chacon', Git::Deprecation.silence { @git.config('user.name') })
    assert_equal('false', Git::Deprecation.silence { @git.config('core.bare') })
  end

  def test_set_config
    assert_not_equal('bully', Git::Deprecation.silence { @git.config('user.name') })
    Git::Deprecation.silence { @git.config('user.name', 'bully') }
    assert_equal('bully', Git::Deprecation.silence { @git.config('user.name') })
  end

  def test_set_config_with_custom_file
    Dir.chdir(@wdir) do
      custom_config_path = "#{Dir.pwd}/.git/custom-config"
      assert_not_equal('bully', Git::Deprecation.silence { @git.config('user.name') })
      Git::Deprecation.silence { @git.config('user.name', 'bully', file: custom_config_path) }
      assert_not_equal('bully', Git::Deprecation.silence { @git.config('user.name') })
      Git::Deprecation.silence { @git.config('include.path', custom_config_path) }
      assert_equal('bully', Git::Deprecation.silence { @git.config('user.name') })
      assert_equal("[user]\n\tname = bully\n", File.read(custom_config_path))
    end
  end

  def test_env_config
    assert_equal('git', Git.config.binary_path)
    assert_nil(Git.config.git_ssh)

    ENV['GIT_PATH'] = '/env/bin'
    ENV['GIT_SSH'] = '/env/git/ssh'

    assert_equal('/env/bin/git', Git.config.binary_path)
    assert_equal('/env/git/ssh', Git.config.git_ssh)

    Git.configure do |config|
      config.binary_path = '/usr/bin/git'
      config.git_ssh = '/path/to/ssh/script'
    end

    assert_equal('/usr/bin/git', Git.config.binary_path)
    assert_equal('/path/to/ssh/script', Git.config.git_ssh)

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
