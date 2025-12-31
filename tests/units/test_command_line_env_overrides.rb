# frozen_string_literal: true

require 'test_helper'

class TestCommandLineEnvOverrides < Test::Unit::TestCase
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

  test 'instance git_ssh option should override global config in Git.bare' do
    saved_git_ssh = Git::Base.config.git_ssh
    begin
      Git::Base.config.git_ssh = '/global/ssh/script'

      in_temp_dir do |path|
        bare_repo_path = File.join(path, 'test_project.git')
        Git.init(bare_repo_path, bare: true)
        git = Git.bare(bare_repo_path, git_ssh: '/instance/ssh/script')

        env = git.lib.send(:env_overrides)
        assert_equal '/instance/ssh/script', env['GIT_SSH']
      end
    ensure
      Git::Base.config.git_ssh = saved_git_ssh
    end
  end

  test 'instance git_ssh option should override global config in Git.open' do
    saved_git_ssh = Git::Base.config.git_ssh
    begin
      Git::Base.config.git_ssh = '/global/ssh/script'

      in_temp_dir do |path|
        create_and_init_repo(path)
        git = Git.open(path, git_ssh: '/instance/ssh/script')

        env = git.lib.send(:env_overrides)
        assert_equal '/instance/ssh/script', env['GIT_SSH']
      end
    ensure
      Git::Base.config.git_ssh = saved_git_ssh
    end
  end

  test 'instance git_ssh option should override global config in Git.init' do
    saved_git_ssh = Git::Base.config.git_ssh
    begin
      Git::Base.config.git_ssh = '/global/ssh/script'

      in_temp_dir do |_path|
        git = Git.init('test_project', git_ssh: '/instance/ssh/script')

        env = git.lib.send(:env_overrides)
        assert_equal '/instance/ssh/script', env['GIT_SSH']
      end
    ensure
      Git::Base.config.git_ssh = saved_git_ssh
    end
  end

  test 'instance git_ssh option should override global config in Git.clone' do
    saved_git_ssh = Git::Base.config.git_ssh
    begin
      Git::Base.config.git_ssh = '/global/ssh/script'

      in_temp_dir do |path|
        source_repo = create_and_init_repo(File.join(path, 'source'))
        target_path = File.join(path, 'target')

        expected_command_line = nil
        expected_command_line_proc = -> { expected_command_line }

        assert_command_line_eq(expected_command_line_proc, include_env: true) do
          git = Git.clone(source_repo, target_path, git_ssh: '/instance/ssh/script')

          # Verify the env_overrides has the instance git_ssh
          env = git.lib.send(:env_overrides)
          assert_equal '/instance/ssh/script', env['GIT_SSH']
        end
      end
    ensure
      Git::Base.config.git_ssh = saved_git_ssh
    end
  end

  test 'instance git_ssh: nil should disable SSH (not use global config)' do
    saved_git_ssh = Git::Base.config.git_ssh
    begin
      Git::Base.config.git_ssh = '/global/ssh/script'

      in_temp_dir do |path|
        create_and_init_repo(path)
        git = Git.open(path, git_ssh: nil)

        env = git.lib.send(:env_overrides)
        assert_nil env['GIT_SSH'], 'GIT_SSH should be nil when git_ssh: nil is passed'
      end
    ensure
      Git::Base.config.git_ssh = saved_git_ssh
    end
  end

  test 'no instance git_ssh option should use global config' do
    saved_git_ssh = Git::Base.config.git_ssh
    begin
      Git::Base.config.git_ssh = '/global/ssh/script'

      in_temp_dir do |path|
        create_and_init_repo(path)
        git = Git.open(path)

        env = git.lib.send(:env_overrides)
        assert_equal '/global/ssh/script', env['GIT_SSH']
      end
    ensure
      Git::Base.config.git_ssh = saved_git_ssh
    end
  end

  test 'instance git_ssh: nil should disable SSH in Git.clone' do
    saved_git_ssh = Git::Base.config.git_ssh
    begin
      Git::Base.config.git_ssh = '/global/ssh/script'

      in_temp_dir do |path|
        source_repo = create_and_init_repo(File.join(path, 'source'))
        target_path = File.join(path, 'target')

        git = Git.clone(source_repo, target_path, git_ssh: nil)

        env = git.lib.send(:env_overrides)
        assert_nil env['GIT_SSH'], 'GIT_SSH should be nil when git_ssh: nil is passed to Git.clone'
      end
    ensure
      Git::Base.config.git_ssh = saved_git_ssh
    end
  end

  test 'Git.clone without git_ssh option should use global config' do
    saved_git_ssh = Git::Base.config.git_ssh
    begin
      Git::Base.config.git_ssh = '/global/ssh/script'

      in_temp_dir do |path|
        source_repo = create_and_init_repo(File.join(path, 'source'))
        target_path = File.join(path, 'target')

        git = Git.clone(source_repo, target_path)

        env = git.lib.send(:env_overrides)
        assert_equal '/global/ssh/script', env['GIT_SSH']
      end
    ensure
      Git::Base.config.git_ssh = saved_git_ssh
    end
  end

  private

  def create_and_init_repo(path)
    FileUtils.mkdir_p(path)
    Dir.chdir(path) do
      `git init`
      `git config user.name "Test User"`
      `git config user.email "test@example.com"`
    end
    path
  end
end
