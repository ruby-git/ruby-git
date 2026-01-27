# frozen_string_literal: true

module Git
  # Integration test file helpers for RSpec shared contexts.
  #
  # These helpers require a `repo_dir` method/let that returns the absolute path
  # to the test repository directory. All file paths are relative to `repo_dir`.
  #
  # @example Usage in a shared context
  #   RSpec.shared_context 'in an empty repository' do
  #     include Git::IntegrationTestHelpers
  #     let(:repo_dir) { Dir.mktmpdir }
  #     # ...
  #   end
  module IntegrationTestHelpers
    # Create a file with content, auto-creating parent directories
    #
    # @param name [String] path relative to repo_dir
    #
    # @param content [String] file content
    #
    # @param encoding [String] file encoding (default: 'UTF-8')
    #
    # @return [void]
    #
    # @example Create a UTF-8 text file
    #   write_file('README.md', '# Hello')
    #
    # @example Create a file with specific encoding
    #   write_file('latin1.txt', 'café', encoding: 'ISO-8859-1')
    #
    # @example Create a binary file
    #   write_file('binary.dat', "\x00\xFF", encoding: 'ASCII-8BIT')
    #
    # @example Create a file in a subdirectory (auto-creates parent)
    #   write_file('lib/git/version.rb', 'VERSION = "1.0.0"')
    #
    def write_file(name, content = '', encoding: 'UTF-8')
      path = File.join(repo_dir, name)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, content, encoding: encoding)
    end

    # Create an empty file if it doesn't exist, or update timestamps if it does
    #
    # @param name [String] path relative to repo_dir
    #
    # @return [void]
    #
    # @example Create an empty file
    #   touch('empty.txt')
    #
    # @example Update file modification time
    #   write_file('old.txt', 'content')
    #   sleep 1
    #   touch('old.txt')  # updates mtime
    #
    def touch(name)
      path = File.join(repo_dir, name)
      FileUtils.mkdir_p(File.dirname(path))
      FileUtils.touch(path)
    end

    # Append content to a file (no automatic newline)
    #
    # @param name [String] path relative to repo_dir
    #
    # @param content [String] content to append
    #
    # @return [void]
    #
    # @example Append to a file
    #   write_file('log.txt', 'Line 1')
    #   append_to_file('log.txt', "\nLine 2")
    #
    def append_to_file(name, content)
      File.open(File.join(repo_dir, name), 'a') { |f| f << content }
    end

    # Read file content
    #
    # @param name [String] path relative to repo_dir
    #
    # @return [String] file content
    #
    # @example Read a file
    #   write_file('test.txt', 'hello')
    #   read_file('test.txt')  # => 'hello'
    #
    # @example Follows symlinks
    #   write_file('target.txt', 'content')
    #   symlink('target.txt', 'link.txt')
    #   read_file('link.txt')  # => 'content'
    #
    def read_file(name)
      File.read(File.join(repo_dir, name))
    end

    # Create a directory
    #
    # @param name [String] path relative to repo_dir
    #
    # @return [void]
    #
    # @example Create nested directories
    #   create_directory('lib/git/commands')
    #
    def create_directory(name)
      FileUtils.mkdir_p(File.join(repo_dir, name))
    end

    # Remove a file or directory
    #
    # @param name [String] path relative to repo_dir
    #
    # @return [void]
    #
    # @example Remove a file
    #   write_file('temp.txt', 'content')
    #   remove('temp.txt')
    #
    # @example Remove a directory tree
    #   create_directory('lib/git')
    #   remove('lib')  # removes lib and all contents
    #
    def remove(name)
      FileUtils.rm_rf(File.join(repo_dir, name))
    end

    # Change file permissions
    #
    # @param mode [Integer] octal permission mode (e.g., 0o755, 0o644)
    #
    # @param name [String] path relative to repo_dir
    #
    # @return [void]
    #
    # @example Make file executable
    #   write_file('script.sh', '#!/bin/bash')
    #   chmod(0o755, 'script.sh')
    #   stat('script.sh').executable?  # => true
    #
    # @example Make file read-only
    #   write_file('readonly.txt', 'content')
    #   chmod(0o444, 'readonly.txt')
    #
    def chmod(mode, name)
      FileUtils.chmod(mode, File.join(repo_dir, name))
    end

    # Change file owner/group (typically requires root privileges)
    #
    # @param user [String, Integer, nil] user name or UID (nil to skip)
    #
    # @param group [String, Integer, nil] group name or GID (nil to skip)
    #
    # @param name [String] path relative to repo_dir
    #
    # @return [void]
    #
    # @example Change owner (requires root)
    #   chown('nobody', nil, 'file.txt')
    #
    def chown(user, group, name)
      FileUtils.chown(user, group, File.join(repo_dir, name))
    end

    # Get file status (size, mode, timestamps, etc.)
    #
    # @param name [String] path relative to repo_dir
    #
    # @return [File::Stat] file status object
    #
    # @example Check file size
    #   write_file('test.txt', 'hello')
    #   stat('test.txt').size  # => 5
    #
    # @example Check permissions
    #   chmod(0o755, 'script.sh')
    #   stat('script.sh').mode.to_s(8)  # => '100755'
    #
    # @example Check modification time
    #   stat('file.txt').mtime  # => 2026-01-27 10:30:00 -0800
    #
    def stat(name)
      File.stat(File.join(repo_dir, name))
    end

    # Get file status without following symlinks
    #
    # @param name [String] path relative to repo_dir
    #
    # @return [File::Stat] file status object for the link itself
    #
    # @example Check if path is a symlink
    #   write_file('target.txt', 'content')
    #   symlink('target.txt', 'link.txt')
    #   lstat('link.txt').symlink?  # => true
    #   stat('link.txt').symlink?   # => false (checks target)
    #
    def lstat(name)
      File.lstat(File.join(repo_dir, name))
    end

    # Create a symbolic link
    #
    # @param target [String] path the symlink points to (can be relative)
    #
    # @param name [String] path of the symlink to create (relative to repo_dir)
    #
    # @return [void]
    #
    # @example Create a symlink to a file
    #   write_file('target.txt', 'content')
    #   symlink('target.txt', 'link.txt')
    #   lstat('link.txt').symlink?  # => true
    #
    # @example Create a symlink to a directory
    #   create_directory('lib')
    #   symlink('lib', 'link_to_lib')
    #
    def symlink(target, name)
      File.symlink(target, File.join(repo_dir, name))
    end

    # Read the target of a symbolic link
    #
    # @param name [String] path relative to repo_dir
    #
    # @return [String] the path the symlink points to
    #
    # @example Get symlink target
    #   symlink('target.txt', 'link.txt')
    #   readlink('link.txt')  # => 'target.txt'
    #
    # @example Compare with read_file
    #   write_file('target.txt', 'hello')
    #   symlink('target.txt', 'link.txt')
    #   readlink('link.txt')  # => 'target.txt' (link path)
    #   read_file('link.txt')  # => 'hello' (target content)
    #
    def readlink(name)
      File.readlink(File.join(repo_dir, name))
    end

    # Find files matching a glob pattern
    #
    # @param pattern [String] glob pattern
    #
    # @return [Array<String>] paths relative to repo_dir
    #
    # @example Find all Ruby files
    #   write_file('lib/git.rb', '')
    #   write_file('lib/git/base.rb', '')
    #   glob('**/*.rb')  # => ['lib/git.rb', 'lib/git/base.rb']
    #
    # @example List directory contents
    #   write_file('src/file.txt', '')
    #   create_directory('src/subdir')
    #   glob('src/*')  # => ['src/file.txt', 'src/subdir']
    #
    # @example Find files by extension
    #   write_file('README.md', '')
    #   write_file('CHANGELOG.md', '')
    #   glob('*.md')  # => ['CHANGELOG.md', 'README.md']
    #
    def glob(pattern)
      Dir.glob(pattern, base: repo_dir)
    end

    # Check if file exists
    #
    # @param name [String] path relative to repo_dir
    #
    # @return [Boolean] true if path exists and is a regular file
    #
    # @example Check file existence
    #   write_file('test.txt', '')
    #   file_exist?('test.txt')  # => true
    #   file_exist?('missing.txt')  # => false
    #
    # @example Directories return false
    #   create_directory('lib')
    #   file_exist?('lib')  # => false
    #
    def file_exist?(name)
      File.file?(File.join(repo_dir, name))
    end

    # Check if directory exists
    #
    # @param name [String] path relative to repo_dir
    #
    # @return [Boolean] true if path exists and is a directory
    #
    # @example Check directory existence
    #   create_directory('lib')
    #   directory_exist?('lib')  # => true
    #   directory_exist?('missing')  # => false
    #
    # @example Files return false
    #   write_file('test.txt', '')
    #   directory_exist?('test.txt')  # => false
    #
    def directory_exist?(name)
      File.directory?(File.join(repo_dir, name))
    end
  end
end

RSpec.shared_context 'in an empty repository' do
  include Git::IntegrationTestHelpers

  let(:repo_dir) { Dir.mktmpdir }
  let(:initial_branch) { 'main' }
  let(:repo) { Git.init(repo_dir, initial_branch:) }
  let(:execution_context) { repo.lib }

  before do
    repo.config('user.email', 'test@example.com')
    repo.config('user.name', 'Test User')
    repo.config('commit.gpgsign', 'false')
    repo.config('core.editor', 'false') # fail fast if editor is invoked
  end

  after do
    FileUtils.rm_rf(repo_dir)
  end
end
