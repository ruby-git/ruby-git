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

    def files
      @files
    end
  end
end

# This is the same suite of tests as TestStatusObject, but the repo has no commits.
# The worktree and index are setup with the same files as TestStatusObject, but the
# repo is in a clean state with no commits.
#
class TestStatusObjectEmptyRepo < Test::Unit::TestCase
  def logger
    # Change log level to Logger::DEBUG to see the log entries
    @logger ||= Logger.new(STDOUT, level: Logger::ERROR)
  end

  def test_no_changes
    in_temp_dir do |worktree_path|

      # Given

      setup_worktree(worktree_path)
      git = Git.open(worktree_path)

      log_git_status
      # Output of `git status --porcelain=v2 --untracked-files=all --branch`:
      #
      # # branch.oid 45bcb25ceb9c69b66337d63e2c1c5b520d8a003d
      # # branch.head main

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
      # # branch.oid (initial)
      # # branch.head main
      # 1 AD N... 000000 100644 000000 0000000000000000000000000000000000000000 146edcbe0a35a475bd97aa6fbf83ecf8b21cfeec file1
      # 1 A. N... 000000 100755 100755 0000000000000000000000000000000000000000 c061beb85924d309fde78d996a7602544e4f69a5 file2

      # When

      status = git.status

      # Then

      # ERROR: mode_index/shw_index are switched with mod_repo/sha_repo

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
      `git rm -f file1`
      git = Git.open(worktree_path)

      log_git_status
      # Output of `git status --porcelain=v2 --untracked-files=all --branch`:
      #
      # # branch.oid (initial)
      # # branch.head main
      # 1 A. N... 000000 100755 100755 0000000000000000000000000000000000000000 c061beb85924d309fde78d996a7602544e4f69a5 file2

      # When

      status = git.status

      # Then

      # ERROR: file2 type should be 'A'

      expected_status_files = [
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
      `git rm -f file1`
      File.open('file1', 'w', 0o644) { |f| f.write('does_not_matter') }
      git = Git.open(worktree_path)

      log_git_status
      # Output of `git status --porcelain=v2 --untracked-files=all --branch`:
      #
      # # branch.oid (initial)
      # # branch.head main
      # 1 A. N... 000000 100755 100755 0000000000000000000000000000000000000000 c061beb85924d309fde78d996a7602544e4f69a5 file2
      # ? file1

      # When

      status = git.status

      # Then

      # ERROR: file2 type should be 'A'

      expected_status_files = [
        {
          path: 'file1', type: nil, stage: nil, untracked: true,
          mode_index: nil, sha_index: nil,
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

  def test_modify_file1_in_worktree
    in_temp_dir do |worktree_path|

      # Given

      setup_worktree(worktree_path)
      File.open('file1', 'w', 0o644) { |f| f.write('updated_content') }
      git = Git.open(worktree_path)

      log_git_status
      # Output of `git status --porcelain=v2 --untracked-files=all --branch`:
      #
      # # branch.oid (initial)
      # # branch.head main
      # 1 AM N... 000000 100644 100644 0000000000000000000000000000000000000000 146edcbe0a35a475bd97aa6fbf83ecf8b21cfeec file1
      # 1 A. N... 000000 100755 100755 0000000000000000000000000000000000000000 c061beb85924d309fde78d996a7602544e4f69a5 file2

      # When

      status = git.status

      # Then

      # ERROR: file1 sha_index is not returned as sha_repo
      # ERROR: file1 sha_repo/sha_index should be zeros

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
      # # branch.oid (initial)
      # # branch.head main
      # 1 A. N... 000000 100644 100644 0000000000000000000000000000000000000000 c6190329af2f07c1a949128b8e962c06eb23cfa4 file1
      # 1 A. N... 000000 100755 100755 0000000000000000000000000000000000000000 c061beb85924d309fde78d996a7602544e4f69a5 file2

      # When

      status = git.status

      # Then

      # ERROR: file1 type should be 'A'
      # ERROR: file2 type should be 'A'
      # ERROR: file1 and file2 mode_repo/show_repo should be zeros instead of nil

      expected_status_files = [
        {
          path: 'file1', type: nil, stage: '0', untracked: nil,
          mode_index: expect_read_write_mode, sha_index: 'c6190329af2f07c1a949128b8e962c06eb23cfa4',
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
      # # branch.oid (initial)
      # # branch.head main
      # 1 AM N... 000000 100644 100644 0000000000000000000000000000000000000000 a9114691c7e7d6139fa9558897eeda2c8cb2cd81 file1
      # 1 A. N... 000000 100755 100755 0000000000000000000000000000000000000000 c061beb85924d309fde78d996a7602544e4f69a5 file2

      # When

      status = git.status

      # Then

      # ERROR: file1 mode_repo and sha_repo should be zeros
      # ERROR: file1 sha_index is not set to the actual sha
      # ERROR: impossible to tell that file1 was added to the index and modified in the worktree
      # ERROR: file2 type should be 'A'

      expected_status_files = [
        {
          path: 'file1', type: 'M', stage: '0', untracked: nil,
          mode_index: expect_read_write_mode, sha_index: '0000000000000000000000000000000000000000',
          mode_repo: expect_read_write_mode, sha_repo: 'a9114691c7e7d6139fa9558897eeda2c8cb2cd81'
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
      # # branch.oid (initial)
      # # branch.head main
      # 1 AD N... 000000 100644 000000 0000000000000000000000000000000000000000 a9114691c7e7d6139fa9558897eeda2c8cb2cd81 file1
      # 1 A. N... 000000 100755 100755 0000000000000000000000000000000000000000 c061beb85924d309fde78d996a7602544e4f69a5 file2

      # When

      status = git.status

      # Then

      # ERROR: impossible to tell that file1 was added to the index
      # ERROR: file1 sha_index/sha_repo are swapped
      # ERROR: file1 mode_repo should be all zeros
      # ERROR: impossible to tell that file1 or file2 was added to the index and are not in the repo
      # ERROR: inconsistent use of all zeros (in file1) and nils (in file2)

      expected_status_files = [
        {
          path: 'file1', type: 'D', stage: '0', untracked: nil,
          mode_index: '000000', sha_index: '0000000000000000000000000000000000000000',
          mode_repo: expect_read_write_mode, sha_repo: 'a9114691c7e7d6139fa9558897eeda2c8cb2cd81'
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
      # # branch.oid (initial)
      # # branch.head main
      # 1 A. N... 000000 100644 100644 0000000000000000000000000000000000000000 146edcbe0a35a475bd97aa6fbf83ecf8b21cfeec file1
      # 1 A. N... 000000 100755 100755 0000000000000000000000000000000000000000 c061beb85924d309fde78d996a7602544e4f69a5 file2
      # ? file3

      # When

      status = git.status

      # Then

      # ERROR: hard to tell that file1 and file2 were aded to the index but are not in the repo

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
      # # branch.oid (initial)
      # # branch.head main
      # 1 A. N... 000000 100644 100644 0000000000000000000000000000000000000000 146edcbe0a35a475bd97aa6fbf83ecf8b21cfeec file1
      # 1 A. N... 000000 100755 100755 0000000000000000000000000000000000000000 c061beb85924d309fde78d996a7602544e4f69a5 file2
      # 1 A. N... 000000 100644 100644 0000000000000000000000000000000000000000 a2b32293aab475bf50798c7642f0fe0593c167f6 file3

      # When

      status = git.status

      # Then

      # WARNING: hard to tell that file1/file2/file3 were added to the index but are not in the repo

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
          path: 'file3', type: nil, stage: '0', untracked: nil,
          mode_index: expect_read_write_mode, sha_index: 'a2b32293aab475bf50798c7642f0fe0593c167f6',
          mode_repo: nil, sha_repo: nil
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
      # # branch.oid (initial)
      # # branch.head main
      # 1 A. N... 000000 100644 100644 0000000000000000000000000000000000000000 146edcbe0a35a475bd97aa6fbf83ecf8b21cfeec file1
      # 1 A. N... 000000 100755 100755 0000000000000000000000000000000000000000 c061beb85924d309fde78d996a7602544e4f69a5 file2
      # 1 AM N... 000000 100644 100644 0000000000000000000000000000000000000000 a2b32293aab475bf50798c7642f0fe0593c167f6 file3

      # When

      status = git.status

      # Then

      # WARNING: hard to tell that file3 was added to the index and is not in the repo
      # ERROR: sha_index/sha_repo are swapped
      # ERROR: mode_repo should be all zeros

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
          path: 'file3', type: 'M', stage: '0', untracked: nil,
          mode_index: expect_read_write_mode, sha_index: '0000000000000000000000000000000000000000',
          mode_repo: expect_read_write_mode, sha_repo: 'a2b32293aab475bf50798c7642f0fe0593c167f6'
        }
      ]

      assert_has_status_files(expected_status_files, status.files)
    end
  end

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
      # # branch.oid (initial)
      # # branch.head main
      # 1 A. N... 000000 100644 100644 0000000000000000000000000000000000000000 146edcbe0a35a475bd97aa6fbf83ecf8b21cfeec file1
      # 1 A. N... 000000 100755 100755 0000000000000000000000000000000000000000 c061beb85924d309fde78d996a7602544e4f69a5 file2
      # 1 AD N... 000000 100644 000000 0000000000000000000000000000000000000000 a2b32293aab475bf50798c7642f0fe0593c167f6 file3

      # When

      status = git.status

      # Then

      # ERROR: mode_index/sha_index are switched with mod_repo/sha_repo
      # WARNING: hard to tell that file3 was added to the index and deleted in the worktree

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

  def setup_worktree(worktree_path)
    `git init`
    File.open('file1', 'w', 0o644) { |f| f.write('contents1') }
    File.open('file2', 'w', 0o755) { |f| f.write('contents2') }
    `git add file1 file2`
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
