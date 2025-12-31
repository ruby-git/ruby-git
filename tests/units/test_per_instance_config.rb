# frozen_string_literal: true

require 'test_helper'

class TestPerInstanceConfig < Test::Unit::TestCase
  test 'Git::Lib initialized from hash sets git_ssh' do
    lib = Git::Lib.new(git_ssh: '/custom/ssh')
    env = lib.send(:env_overrides)
    assert_equal '/custom/ssh', env['GIT_SSH']
  end

  test 'Git.clone passes git_ssh to Git::Lib for execution' do
    git_ssh = '/custom/ssh'

    # Git.clone calls Git::Lib.new({git_ssh: ...}, ...).clone(...)
    # We verify that Git::Lib.new is called with the correct git_ssh option

    Git::Lib.expects(:new).with(has_entry(git_ssh: git_ssh), anything).returns(stub_everything(clone: {}))

    begin
      Git.clone('url', 'dir', git_ssh: git_ssh)
    rescue StandardError
      # Ignore errors after the part we are testing
    end
  end

  test 'per-instance git_ssh: nil overrides global SSH key' do
    # Set a global SSH key
    Git.configure do |config|
      config.git_ssh = '/global/ssh'
    end

    # When git_ssh: nil is passed, GIT_SSH should not be set for clone
    Git::Lib.stubs(:new).with(has_entry(git_ssh: nil), anything).returns(stub_everything(clone: {}))
    begin
      Git.clone('url', 'dir', git_ssh: nil)
    rescue StandardError
      # Ignore errors after the part we are testing
    end

    # For env_overrides, use the real class
    lib_real = Git::Lib.allocate
    lib_real.send(:initialize_from_hash, { git_ssh: nil })
    env = lib_real.send(:env_overrides)
    assert_nil env['GIT_SSH'], 'GIT_SSH should not be set when git_ssh: nil is passed'
  end

  test 'Git.init passes git_ssh to Git::Lib for execution' do
    git_ssh = '/custom/ssh'

    # Git.init calls Git::Lib.new(options).init(init_options)

    Git::Lib.expects(:new).with(has_entry(git_ssh: git_ssh)).returns(stub_everything(init: true))

    begin
      Git.init('dir', git_ssh: git_ssh)
    rescue StandardError
      # Ignore errors
    end
  end
end
