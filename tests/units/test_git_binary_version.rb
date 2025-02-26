# frozen_string_literal: true

require 'test_helper'

class TestGitBinaryVersion < Test::Unit::TestCase
  def mocked_git_script_windows = <<~GIT_SCRIPT
    @echo off
    # Loop through the arguments and check for the version command
    for %%a in (%*) do (
      if "%%a" == "version" (
        echo git version 1.2.3
        exit /b 0
      )
    )
    exit /b 1
  GIT_SCRIPT

  def mocked_git_script_linux = <<~GIT_SCRIPT
    #!/bin/sh
    # Loop through the arguments and check for the version command
    for arg in "$@"; do
      if [ "$arg" = "version" ]; then
        echo "git version 1.2.3"
        exit 0
      fi
    done
    exit 1
  GIT_SCRIPT

  def mocked_git_script
    if windows_platform?
      mocked_git_script_windows
    else
      mocked_git_script_linux
    end
  end

  def test_binary_version
    in_temp_dir do |path|
      mock_git_binary(mocked_git_script) do |git_binary_path|
        assert_equal([1, 2, 3], Git.binary_version(git_binary_path))
      end
    end
  end

  def test_binary_version_with_spaces
    in_temp_dir do |path|
      subdir = 'Git Bin Directory'
      mock_git_binary(mocked_git_script, subdir: subdir) do |git_binary_path|
        assert_equal([1, 2, 3], Git.binary_version(git_binary_path))
      end
    end
  end

  def test_binary_version_bad_binary_path
    assert_raise RuntimeError do
      Git.binary_version('/path/to/nonexistent/git')
    end
  end
end
