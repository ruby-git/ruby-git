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
end
