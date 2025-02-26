# frozen_string_literal: true

require 'test_helper'

class TestGitBaseRootOfWorktree < Test::Unit::TestCase
  def mocked_git_script(toplevel) = <<~GIT_SCRIPT
    #!/bin/sh
    # Loop through the arguments and check for the "rev-parse --show-toplevel" args
    for arg in "$@"; do
      if [ "$arg" = "version" ]; then
        echo "git version 1.2.3"
        exit 0
      elif [ "$arg" = "rev-parse" ]; then
        REV_PARSE_ARG=true
      elif [ "$REV_PARSE_ARG" = "true" ] && [ $arg = "--show-toplevel" ]; then
        echo #{toplevel}
        exit 0
      fi
    done
    exit 1
  GIT_SCRIPT

  def test_root_of_worktree
    omit('Only implemented for non-windows platforms') if windows_platform?

    in_temp_dir do |toplevel|
      `git init`

      mock_git_binary(mocked_git_script(toplevel)) do
        working_dir = File.join(toplevel, 'config')
        Dir.mkdir(working_dir)

        assert_equal(toplevel, Git::Base.root_of_worktree(working_dir))
      end
    end
  end

  def test_working_dir_has_spaces
    omit('Only implemented for non-windows platforms') if windows_platform?

    in_temp_dir do |toplevel|
      `git init`

      mock_git_binary(mocked_git_script(toplevel)) do
        working_dir = File.join(toplevel, 'app config')
        Dir.mkdir(working_dir)

        assert_equal(toplevel, Git::Base.root_of_worktree(working_dir))
      end
    end
  end

  def test_working_dir_does_not_exist
    assert_raise ArgumentError do
      Git::Base.root_of_worktree('/path/to/nonexistent/work_dir')
    end
  end

  def mocked_git_script2 = <<~GIT_SCRIPT
    #!/bin/sh
    # Loop through the arguments and check for the "rev-parse --show-toplevel" args
    for arg in "$@"; do
      if [ "$arg" = "version" ]; then
        echo "git version 1.2.3"
        exit 0
      elif [ "$arg" = "rev-parse" ]; then
        REV_PARSE_ARG=true
      elif [ "$REV_PARSE_ARG" = "true" ] && [ $arg = "--show-toplevel" ]; then
        echo fatal: not a git repository 1>&2
        exit 128
      fi
    done
    exit 1
  GIT_SCRIPT

  def test_working_dir_not_in_work_tree
    omit('Only implemented for non-windows platforms') if windows_platform?

    in_temp_dir do |temp_dir|
      toplevel = File.join(temp_dir, 'my_repo')
      Dir.mkdir(toplevel) do
        `git init`
      end

      mock_git_binary(mocked_git_script2) do
        assert_raise ArgumentError do
          Git::Base.root_of_worktree(temp_dir)
        end
      end
    end
  end
end
