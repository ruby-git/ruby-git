# frozen_string_literal: true

require 'test_helper'

class TestPerInstanceConfig < Test::Unit::TestCase
  test 'Git.clone passes git_ssh through execution context' do
    git_ssh = '/custom/ssh'

    in_temp_dir do |path|
      source = Git.init(path, initial_branch: 'main')
      source.commit('initial', allow_empty: true)

      clone_dir = Dir.mktmpdir
      begin
        repo = Git.clone(path, 'cloned', chdir: clone_dir, git_ssh: git_ssh)
        assert_equal git_ssh, repo.execution_context.git_ssh
      ensure
        FileUtils.rm_rf(clone_dir)
      end
    end
  end

  test 'per-instance git_ssh: nil overrides global SSH key' do
    previous_git_ssh = Git.config.git_ssh
    Git.configure { |c| c.git_ssh = '/global/ssh' }

    begin
      in_temp_dir do |path|
        repo = Git.init(path, git_ssh: nil)
        assert_nil repo.execution_context.git_ssh,
                   'GIT_SSH should not be set when git_ssh: nil is passed'
      end
    ensure
      Git.configure { |c| c.git_ssh = previous_git_ssh }
    end
  end

  test 'Git.init passes git_ssh through execution context' do
    git_ssh = '/custom/ssh'

    in_temp_dir do |path|
      repo = Git.init(path, git_ssh: git_ssh)

      assert_equal git_ssh, repo.execution_context.git_ssh
    end
  end
end
