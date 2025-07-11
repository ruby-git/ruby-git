# frozen_string_literal: true

require 'rbconfig'
require 'securerandom'
require 'test_helper'

module Git
  # Add methods to the Status class to make it easier to test
  class Status
    def size
      @files.size
    end

    alias count size

    attr_reader :files
  end
end

# A suite of tests for the Status class for the following scenarios
#
# For all tests, the initial state of the repo is one commit with the following
# files:
#
# * { path: 'file1', content: 'contents1', mode: '100644' }
# * { path: 'file2', content: 'contents2', mode: '100755' }
#
# Assume the repo is cloned to a temporary directory (`worktree_path`) and the
# index and worktree are in a clean state before each test.
#
# Assume the Status object is initialized with `base` which is a Git object created
# via `Git.open(worktree_path)`.
#
# Test that the status object returns the expected #files
#
class TestStatusObject < Test::Unit::TestCase
  def logger
    # Change log level to Logger::DEBUG to see the log entries
    @logger ||= Logger.new($stdout, level: Logger::ERROR)
  end

  def test_no_changes
    in_temp_dir do |worktree_path|
      # Given

      setup_worktree(worktree_path)
      git = Git.open(worktree_path)

      log_git_status
      # Output of `git status --porcelain=v2 --untracked-files=all --branch`:
      #
      # # branch.oid (initial)
      # # branch.head main
      # 1 A. N... 000000 100644 100644 0000000000000000000000000000000000000000 146edcbe0a35a475bd97aa6fbf83ecf8b21cfeec file1
      # 1 A. N... 000000 100755 100755 0000000000000000000000000000000000000000 c061beb85924d309fde78d996a7602544e4f69a5 file2

      # When

      status = git.status

      # Then

      expected_status_files = [
        {
          path: 'file1', type: nil, stage: '0', untracked: nil,
          mode_index: expect_read_write_mode, sha_index: '146edcbe0a35a475bd97aa6fbf83ecf8b21cfeec',
          mode_repo: nil, sha_repo: nil
        },
        {
          path: 'file2', type: nil, stage: '0', untracked: nil,
          mode_index: expect_execute_mode, sha_index: 'c061beb85924d309fde78d996a7602544e4f69a5',
          mode_repo: nil, sha_repo: nil
        }
      ]

      assert_has_status_files(expected_status_files, status.files)
    end
  end

  def test_delete_file1_from_worktree
    in_temp_dir do |worktree_path|
      # Given

      setup_worktree(worktree_path)
      File.delete('file1')
      git = Git.open(worktree_path)

      log_git_status
      # Output of `git status --porcelain=v2 --untracked-files=all --branch`:
      #
      # # branch.oid 1d5ec91c189281dbbd97a00451815c8ae288c512
      # # branch.head main
      # 1 .D N... 100644 100644 000000 146edcbe0a35a475bd97aa6fbf83ecf8b21cfeec 146edcbe0a35a475bd97aa6fbf83ecf8b21cfeec file1

      # When

      status = git.status

      # Then

      # ERROR: mode_index and sha_indes for file1 is not returned

      expected_status_files = [
        {
          path: 'file1', type: 'D', stage: '0', untracked: nil,
          mode_index: '000000', sha_index: '0000000000000000000000000000000000000000',
          mode_repo: expect_read_write_mode, sha_repo: '146edcbe0a35a475bd97aa6fbf83ecf8b21cfeec'
        },
        {
          path: 'file2', type: nil, stage: '0', untracked: nil,
          mode_index: expect_execute_mode, sha_index: 'c061beb85924d309fde78d996a7602544e4f69a5',
          mode_repo: nil, sha_repo: nil
        }
      ]

      assert_has_status_files(expected_status_files, status.files)
    end
  end

  def test_delete_file1_from_index
    in_temp_dir do |worktree_path|
      # Given

      setup_worktree(worktree_path)
      `git rm file1`
      git = Git.open(worktree_path)

      log_git_status
      # Output of `git status --porcelain=v2 --untracked-files=all --branch`:
      #
      # # branch.oid 9a6c20a5ca26595796ff5c2ef6e6a806ae4427f3
      # # branch.head main
      # 1 D. N... 100644 000000 000000 146edcbe0a35a475bd97aa6fbf83ecf8b21cfeec 0000000000000000000000000000000000000000 file1

      # When

      status = git.status

      # Then

      expected_status_files = [
        {
          path: 'file1', type: 'D', stage: nil, untracked: nil,
          mode_index: '000000', sha_index: '0000000000000000000000000000000000000000',
          mode_repo: expect_read_write_mode, sha_repo: '146edcbe0a35a475bd97aa6fbf83ecf8b21cfeec'
        },
        {
          path: 'file2', type: nil, stage: '0', untracked: nil,
          mode_index: expect_execute_mode, sha_index: 'c061beb85924d309fde78d996a7602544e4f69a5',
          mode_repo: nil, sha_repo: nil
        }
      ]

      assert_has_status_files(expected_status_files, status.files)
    end
  end

  def test_delete_file1_from_index_and_recreate_in_worktree
    in_temp_dir do |worktree_path|
      # Given

      setup_worktree(worktree_path)
      `git rm file1`
      File.open('file1', 'w', 0o644) { |f| f.write('does_not_matter') }
      git = Git.open(worktree_path)

      log_git_status
      # Output of `git status --porcelain=v2 --untracked-files=all --branch`:
      #
      # # branch.oid 9a6c20a5ca26595796ff5c2ef6e6a806ae4427f3
      # # branch.head main
      # 1 D. N... 100644 000000 000000 146edcbe0a35a475bd97aa6fbf83ecf8b21cfeec 0000000000000000000000000000000000000000 file1
      # ? file1

      # When

      status = git.status

      # Then

      expected_status_files = [
        {
          path: 'file1', type: 'D', stage: nil, untracked: true,
          mode_index: '000000', sha_index: '0000000000000000000000000000000000000000',
          mode_repo: expect_read_write_mode, sha_repo: '146edcbe0a35a475bd97aa6fbf83ecf8b21cfeec'
        },
        {
          path: 'file2', type: nil, stage: '0', untracked: nil,
          mode_index: expect_execute_mode, sha_index: 'c061beb85924d309fde78d996a7602544e4f69a5',
          mode_repo: nil, sha_repo: nil
        }
      ]

      assert_has_status_files(expected_status_files, status.files)
    end
  end

  def test_modify_file1_in_worktree
    in_temp_dir do |worktree_path|
      # Given

      setup_worktree(worktree_path)
      File.open('file1', 'w', 0o644) { |f| f.write('updated_content') }
      git = Git.open(worktree_path)

      log_git_status
      # Output of `git status --porcelain=v2 --untracked-files=all --branch`:
      #
      # # branch.oid 1d5ec91c189281dbbd97a00451815c8ae288c512
      # # branch.head main
      # 1 .M N... 100644 100644 100644 146edcbe0a35a475bd97aa6fbf83ecf8b21cfeec 146edcbe0a35a475bd97aa6fbf83ecf8b21cfeec file1

      # When

      status = git.status

      # Then

      # ERROR: sha_index for file1 is not returned

      expected_status_files = [
        {
          path: 'file1', type: 'M', stage: '0', untracked: nil,
          mode_index: expect_read_write_mode, sha_index: '0000000000000000000000000000000000000000',
          mode_repo: expect_read_write_mode, sha_repo: '146edcbe0a35a475bd97aa6fbf83ecf8b21cfeec'
        },
        {
          path: 'file2', type: nil, stage: '0', untracked: nil,
          mode_index: expect_execute_mode, sha_index: 'c061beb85924d309fde78d996a7602544e4f69a5',
          mode_repo: nil, sha_repo: nil
        }
      ]

      assert_has_status_files(expected_status_files, status.files)
    end
  end

  def test_modify_file1_in_worktree_and_add_to_index
    in_temp_dir do |worktree_path|
      # Given

      setup_worktree(worktree_path)
      File.open('file1', 'w', 0o644) { |f| f.write('updated_content') }
      `git add file1`
      git = Git.open(worktree_path)

      log_git_status
      # Output of `git status --porcelain=v2 --untracked-files=all --branch`:
      #
      # # branch.oid 1d5ec91c189281dbbd97a00451815c8ae288c512
      # # branch.head main
      # 1 M. N... 100644 100644 100644 146edcbe0a35a475bd97aa6fbf83ecf8b21cfeec c6190329af2f07c1a949128b8e962c06eb23cfa4 file1

      # When

      status = git.status

      # Then

      expected_status_files = [
        {
          path: 'file1', type: 'M', stage: '0', untracked: nil,
          mode_index: expect_read_write_mode, sha_index: 'c6190329af2f07c1a949128b8e962c06eb23cfa4',
          mode_repo: expect_read_write_mode, sha_repo: '146edcbe0a35a475bd97aa6fbf83ecf8b21cfeec'
        },
        {
          path: 'file2', type: nil, stage: '0', untracked: nil,
          mode_index: expect_execute_mode, sha_index: 'c061beb85924d309fde78d996a7602544e4f69a5',
          mode_repo: nil, sha_repo: nil
        }
      ]

      assert_has_status_files(expected_status_files, status.files)
    end
  end

  def test_modify_file1_in_worktree_and_add_to_index_and_modify_in_worktree
    in_temp_dir do |worktree_path|
      # Given

      setup_worktree(worktree_path)
      File.open('file1', 'w', 0o644) { |f| f.write('updated_content1') }
      `git add file1`
      File.open('file1', 'w', 0o644) { |f| f.write('updated_content2') }
      git = Git.open(worktree_path)

      log_git_status
      # Output of `git status --porcelain=v2 --untracked-files=all --branch`:
      #
      # # branch.oid 1d5ec91c189281dbbd97a00451815c8ae288c512
      # # branch.head main
      # 1 MM N... 100644 100644 100644 146edcbe0a35a475bd97aa6fbf83ecf8b21cfeec a9114691c7e7d6139fa9558897eeda2c8cb2cd81 file1

      # When

      status = git.status

      # Then

      # ERROR: there shouldn't be a mode_repo or sha_repo for file1

      expected_status_files = [
        {
          path: 'file1', type: 'M', stage: '0', untracked: nil,
          mode_index: expect_read_write_mode, sha_index: '0000000000000000000000000000000000000000',
          mode_repo: expect_read_write_mode, sha_repo: '146edcbe0a35a475bd97aa6fbf83ecf8b21cfeec'
        },
        {
          path: 'file2', type: nil, stage: '0', untracked: nil,
          mode_index: expect_execute_mode, sha_index: 'c061beb85924d309fde78d996a7602544e4f69a5',
          mode_repo: nil, sha_repo: nil
        }
      ]

      assert_has_status_files(expected_status_files, status.files)
    end
  end

  def test_modify_file1_in_worktree_and_add_to_index_and_delete_in_worktree
    in_temp_dir do |worktree_path|
      # Given

      setup_worktree(worktree_path)
      File.open('file1', 'w', 0o644) { |f| f.write('updated_content1') }
      `git add file1`
      File.delete('file1')
      git = Git.open(worktree_path)

      log_git_status
      # Output of `git status --porcelain=v2 --untracked-files=all --branch`:
      #
      # # branch.oid 1d5ec91c189281dbbd97a00451815c8ae288c512
      # # branch.head main
      # 1 MD N... 100644 100644 000000 146edcbe0a35a475bd97aa6fbf83ecf8b21cfeec a9114691c7e7d6139fa9558897eeda2c8cb2cd81 file1

      # When

      status = git.status

      # Then

      # ERROR: Impossible to tell that a change to file1 was already staged and the delete happened in the worktree

      expected_status_files = [
        {
          path: 'file1', type: 'D', stage: '0', untracked: nil,
          mode_index: '000000', sha_index: '0000000000000000000000000000000000000000',
          mode_repo: expect_read_write_mode, sha_repo: '146edcbe0a35a475bd97aa6fbf83ecf8b21cfeec'
        },
        {
          path: 'file2', type: nil, stage: '0', untracked: nil,
          mode_index: expect_execute_mode, sha_index: 'c061beb85924d309fde78d996a7602544e4f69a5',
          mode_repo: nil, sha_repo: nil
        }
      ]

      assert_has_status_files(expected_status_files, status.files)
    end
  end

  def test_add_file3_to_worktree
    in_temp_dir do |worktree_path|
      # Given

      setup_worktree(worktree_path)
      File.open('file3', 'w', 0o644) { |f| f.write('content3') }
      git = Git.open(worktree_path)

      log_git_status
      # Output of `git status --porcelain=v2 --untracked-files=all --branch`:
      #
      # # branch.oid 9a6c20a5ca26595796ff5c2ef6e6a806ae4427f3
      # # branch.head main
      # ? file3

      # When

      status = git.status

      # Then

      expected_status_files = [
        {
          path: 'file1', type: nil, stage: '0', untracked: nil,
          mode_index: expect_read_write_mode, sha_index: '146edcbe0a35a475bd97aa6fbf83ecf8b21cfeec',
          mode_repo: nil, sha_repo: nil
        },
        {
          path: 'file2', type: nil, stage: '0', untracked: nil,
          mode_index: expect_execute_mode, sha_index: 'c061beb85924d309fde78d996a7602544e4f69a5',
          mode_repo: nil, sha_repo: nil
        },
        {
          path: 'file3', type: nil, stage: nil, untracked: true,
          mode_index: nil, sha_index: nil,
          mode_repo: nil, sha_repo: nil
        }
      ]

      assert_has_status_files(expected_status_files, status.files)
    end
  end

  def test_add_file3_to_worktree_and_index
    in_temp_dir do |worktree_path|
      # Given

      setup_worktree(worktree_path)
      File.open('file3', 'w', 0o644) { |f| f.write('content3') }
      `git add file3`
      git = Git.open(worktree_path)

      log_git_status
      # Output of `git status --porcelain=v2 --untracked-files=all --branch`:
      #
      # # branch.oid 9a6c20a5ca26595796ff5c2ef6e6a806ae4427f3
      # # branch.head main
      # 1 A. N... 000000 100644 100644 0000000000000000000000000000000000000000 a2b32293aab475bf50798c7642f0fe0593c167f6 file3

      # When

      status = git.status

      # Then

      expected_status_files = [
        {
          path: 'file1', type: nil, stage: '0', untracked: nil,
          mode_index: expect_read_write_mode, sha_index: '146edcbe0a35a475bd97aa6fbf83ecf8b21cfeec',
          mode_repo: nil, sha_repo: nil
        },
        {
          path: 'file2', type: nil, stage: '0', untracked: nil,
          mode_index: expect_execute_mode, sha_index: 'c061beb85924d309fde78d996a7602544e4f69a5',
          mode_repo: nil, sha_repo: nil
        },
        {
          path: 'file3', type: 'A', stage: '0', untracked: nil,
          mode_index: expect_read_write_mode, sha_index: 'a2b32293aab475bf50798c7642f0fe0593c167f6',
          mode_repo: '000000', sha_repo: '0000000000000000000000000000000000000000'
        }
      ]

      assert_has_status_files(expected_status_files, status.files)
    end
  end

  def test_add_file3_to_worktree_and_index_and_modify_in_worktree
    in_temp_dir do |worktree_path|
      # Given

      setup_worktree(worktree_path)
      File.open('file3', 'w', 0o644) { |f| f.write('content3') }
      `git add file3`
      File.open('file3', 'w', 0o644) { |f| f.write('updated_content3') }
      git = Git.open(worktree_path)

      log_git_status
      # Output of `git status --porcelain=v2 --untracked-files=all --branch`:
      #
      # # branch.oid 9a6c20a5ca26595796ff5c2ef6e6a806ae4427f3
      # # branch.head main
      # 1 AM N... 000000 100644 100644 0000000000000000000000000000000000000000 a2b32293aab475bf50798c7642f0fe0593c167f6 file3

      # When

      status = git.status

      # Then

      # ERROR: the sha_mode and sha_index for file3 is not correct below

      # ERROR: impossible to tell that file3 was modified in the worktree

      expected_status_files = [
        {
          path: 'file1', type: nil, stage: '0', untracked: nil,
          mode_index: expect_read_write_mode, sha_index: '146edcbe0a35a475bd97aa6fbf83ecf8b21cfeec',
          mode_repo: nil, sha_repo: nil
        },
        {
          path: 'file2', type: nil, stage: '0', untracked: nil,
          mode_index: expect_execute_mode, sha_index: 'c061beb85924d309fde78d996a7602544e4f69a5',
          mode_repo: nil, sha_repo: nil
        },
        {
          path: 'file3', type: 'A', stage: '0', untracked: nil,
          mode_index: expect_read_write_mode, sha_index: '0000000000000000000000000000000000000000',
          mode_repo: '000000', sha_repo: '0000000000000000000000000000000000000000'
        }
      ]

      assert_has_status_files(expected_status_files, status.files)
    end
  end

  # * Add { path: 'file3', content: 'content3', mode: expect_read_write_mode } to the worktree, add
  #   file3 to the index, delete file3 in the worktree [DONE]
  def test_add_file3_to_worktree_and_index_and_delete_in_worktree
    in_temp_dir do |worktree_path|
      # Given

      setup_worktree(worktree_path)
      File.open('file3', 'w', 0o644) { |f| f.write('content3') }
      `git add file3`
      File.delete('file3')
      git = Git.open(worktree_path)

      log_git_status
      # Output of `git status --porcelain=v2 --untracked-files=all --branch`:
      #
      # # branch.oid 9a6c20a5ca26595796ff5c2ef6e6a806ae4427f3
      # # branch.head main
      # 1 AD N... 000000 100644 000000 0000000000000000000000000000000000000000 a2b32293aab475bf50798c7642f0fe0593c167f6 file3

      # When

      status = git.status

      # Then

      expected_status_files = [
        {
          path: 'file1', type: nil, stage: '0', untracked: nil,
          mode_index: expect_read_write_mode, sha_index: '146edcbe0a35a475bd97aa6fbf83ecf8b21cfeec',
          mode_repo: nil, sha_repo: nil
        },
        {
          path: 'file2', type: nil, stage: '0', untracked: nil,
          mode_index: expect_execute_mode, sha_index: 'c061beb85924d309fde78d996a7602544e4f69a5',
          mode_repo: nil, sha_repo: nil
        },
        {
          path: 'file3', type: 'D', stage: '0', untracked: nil,
          mode_index: '000000', sha_index: '0000000000000000000000000000000000000000',
          mode_repo: expect_read_write_mode, sha_repo: 'a2b32293aab475bf50798c7642f0fe0593c167f6'
        }
      ]

      assert_has_status_files(expected_status_files, status.files)
    end
  end

  private

  def setup_worktree(_worktree_path)
    `git init`
    File.open('file1', 'w', 0o644) { |f| f.write('contents1') }
    File.open('file2', 'w', 0o755) { |f| f.write('contents2') }
    `git add file1 file2`
    `git commit -m "Initial commit"`
  end

  # Generate a unique string to use as file content
  def random_content
    SecureRandom.uuid
  end

  def assert_has_attributes(expected_attrs, object)
    expected_attrs.each do |expected_attr, expected_value|
      assert_equal(expected_value, object.send(expected_attr), "The #{expected_attr} attribute does not match")
    end
  end

  def assert_has_status_files(expected_status_files, status_files)
    assert_equal(expected_status_files.count, status_files.count)

    expected_status_files.each do |expected_status_file|
      status_file = status_files[expected_status_file[:path]]
      assert_not_nil(status_file, "Status for file #{expected_status_file[:path]} not found")
      assert_has_attributes(expected_status_file, status_file)
    end
  end

  def log_git_status
    logger.debug do
      <<~LOG_ENTRY

        ==========
        #{self.class.name}
        #{caller[3][/`([^']*)'/, 1].split.last}
        ----------
              # Output of `git status --porcelain=v2 --untracked-files=all --branch`:
              #
        #{`git status --porcelain=v2 --untracked-files=all --branch`.split("\n").map { |line| "      # #{line}" }.join("\n")}
        ==========

      LOG_ENTRY
    end
  end

  def expect_read_write_mode
    '100644'
  end

  def expect_execute_mode
    windows? ? expect_read_write_mode : '100755'
  end

  def windows?
    RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/
  end
end
