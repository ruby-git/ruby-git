# frozen_string_literal: true

require 'test_helper'

class TestCommandLineEnvOverrides < Test::Unit::TestCase
  test 'it should set the expected environment variables' do
    expected_command_line = nil
    expected_command_line_proc = -> { expected_command_line }
    assert_command_line_eq(expected_command_line_proc, include_env: true) do |git|
      expected_env = {
        'GIT_DIR' => git.lib.git_dir,
        'GIT_INDEX_FILE' => git.lib.git_index_file,
        'GIT_SSH' => nil,
        'GIT_WORK_TREE' => git.lib.git_work_dir,
        'LC_ALL' => 'en_US.UTF-8'
      }
      expected_command_line = [expected_env, 'checkout', {}]

      git.checkout
    end
  end

  test 'it should set the GIT_SSH environment variable from Git::Base.config.git_ssh' do
    expected_command_line = nil
    expected_command_line_proc = -> { expected_command_line }

    saved_git_ssh = Git::Base.config.git_ssh
    begin
      Git::Base.config.git_ssh = 'ssh -i /path/to/key'

      assert_command_line_eq(expected_command_line_proc, include_env: true) do |git|
        expected_env = {
          'GIT_DIR' => git.lib.git_dir,
          'GIT_INDEX_FILE' => git.lib.git_index_file,
          'GIT_SSH' => 'ssh -i /path/to/key',
          'GIT_WORK_TREE' => git.lib.git_work_dir,
          'LC_ALL' => 'en_US.UTF-8'
        }
        expected_command_line = [expected_env, 'checkout', {}]

        git.checkout
      end
    ensure
      Git::Base.config.git_ssh = saved_git_ssh
    end
  end

  test 'env_overrides should return default environment variables' do
    in_temp_dir do |_path|
      git = Git.init('test_project')

      env = git.lib.send(:env_overrides)

      assert_equal git.lib.git_dir, env['GIT_DIR']
      assert_equal git.lib.git_work_dir, env['GIT_WORK_TREE']
      assert_equal git.lib.git_index_file, env['GIT_INDEX_FILE']
      assert_equal 'en_US.UTF-8', env['LC_ALL']
      assert_equal Git::Base.config.git_ssh, env['GIT_SSH']
    end
  end

  test 'env_overrides should allow adding additional environment variables' do
    in_temp_dir do |_path|
      git = Git.init('test_project')

      env = git.lib.send(:env_overrides, 'GIT_TRACE' => '1', 'GIT_CURL_VERBOSE' => '1')

      # Original variables should still be present
      assert_equal git.lib.git_dir, env['GIT_DIR']
      assert_equal git.lib.git_work_dir, env['GIT_WORK_TREE']
      assert_equal git.lib.git_index_file, env['GIT_INDEX_FILE']

      # Additional variables should be present
      assert_equal '1', env['GIT_TRACE']
      assert_equal '1', env['GIT_CURL_VERBOSE']
    end
  end

  test 'env_overrides should allow overriding existing environment variables' do
    in_temp_dir do |_path|
      git = Git.init('test_project')

      env = git.lib.send(:env_overrides, 'LC_ALL' => 'C', 'GIT_SSH' => '/custom/ssh')

      # Overridden variables should have new values
      assert_equal 'C', env['LC_ALL']
      assert_equal '/custom/ssh', env['GIT_SSH']

      # Other variables should remain unchanged
      assert_equal git.lib.git_dir, env['GIT_DIR']
      assert_equal git.lib.git_work_dir, env['GIT_WORK_TREE']
    end
  end

  test 'env_overrides should allow excluding environment variables by setting to nil' do
    in_temp_dir do |_path|
      git = Git.init('test_project')

      env = git.lib.send(:env_overrides, 'GIT_INDEX_FILE' => nil, 'GIT_SSH' => nil)

      # Excluded variables should be set to nil
      assert_nil env['GIT_INDEX_FILE']
      assert_nil env['GIT_SSH']

      # Other variables should remain unchanged
      assert_equal git.lib.git_dir, env['GIT_DIR']
      assert_equal git.lib.git_work_dir, env['GIT_WORK_TREE']
      assert_equal 'en_US.UTF-8', env['LC_ALL']
    end
  end

  test 'worktree_command_line should exclude GIT_INDEX_FILE from environment' do
    in_temp_dir do |_path|
      git = Git.init('test_project')

      # Get the worktree command line instance
      worktree_cmd_line = git.lib.send(:worktree_command_line)

      # Extract the env_overrides from the command line instance
      env = worktree_cmd_line.instance_variable_get(:@env)

      # GIT_INDEX_FILE should be set to nil (will be unset per Process.spawn semantics)
      assert_nil env['GIT_INDEX_FILE']

      # Other environment variables should still be present
      assert_equal git.lib.git_dir, env['GIT_DIR']
      assert_equal git.lib.git_work_dir, env['GIT_WORK_TREE']
      assert_equal 'en_US.UTF-8', env['LC_ALL']
    end
  end

  test 'env_overrides should allow both adding and excluding variables simultaneously' do
    in_temp_dir do |_path|
      git = Git.init('test_project')

      env = git.lib.send(:env_overrides,
                         'GIT_TRACE' => '1',           # Add new variable
                         'GIT_INDEX_FILE' => nil,      # Exclude existing variable
                         'LC_ALL' => 'C')              # Override existing variable

      # Added variable should be present
      assert_equal '1', env['GIT_TRACE']

      # Excluded variable should be nil
      assert_nil env['GIT_INDEX_FILE']

      # Overridden variable should have new value
      assert_equal 'C', env['LC_ALL']

      # Unchanged variables should remain
      assert_equal git.lib.git_dir, env['GIT_DIR']
      assert_equal git.lib.git_work_dir, env['GIT_WORK_TREE']
    end
  end
end
