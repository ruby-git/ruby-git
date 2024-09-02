require 'test_helper'

class TestGitBinaryVersion < Test::Unit::TestCase
  def windows_mocked_git_binary = <<~GIT_SCRIPT
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

  def linux_mocked_git_binary = <<~GIT_SCRIPT
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

  def test_binary_version_windows
    omit('Only implemented for Windows') unless windows_platform?

    in_temp_dir do |path|
      git_binary_path = File.join(path, 'my_git.bat')
      File.write(git_binary_path, windows_mocked_git_binary)
      assert_equal([1, 2, 3], Git.binary_version(git_binary_path))
    end
  end

  def test_binary_version_linux
    omit('Only implemented for Linux') if windows_platform?

    in_temp_dir do |path|
      git_binary_path = File.join(path, 'my_git.bat')
      File.write(git_binary_path, linux_mocked_git_binary)
      File.chmod(0755, git_binary_path)
      assert_equal([1, 2, 3], Git.binary_version(git_binary_path))
    end
  end

  def test_binary_version_bad_binary_path
    assert_raise RuntimeError do
      Git.binary_version('/path/to/nonexistent/git')
    end
  end
end
