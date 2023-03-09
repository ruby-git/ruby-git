require 'date'
require 'fileutils'
require 'minitar'
require 'test/unit'
require 'tmpdir'

require "git"

class Test::Unit::TestCase

  TEST_ROOT = File.expand_path(__dir__)
  TEST_FIXTURES = File.join(TEST_ROOT, 'files')

  BARE_REPO_PATH = File.join(TEST_FIXTURES, 'working.git')

  def clone_working_repo
    @wdir = create_temp_repo('working')
  end

  teardown
  def git_teardown
    FileUtils.rm_r(@tmp_path) if instance_variable_defined?(:@tmp_path)
  end

  def in_bare_repo_clone
    in_temp_dir do |path|
      git = Git.clone(BARE_REPO_PATH, 'bare')
      Dir.chdir('bare') do
        yield git
      end
    end
  end

  def in_temp_repo(clone_name)
    clone_path = create_temp_repo(clone_name)
    Dir.chdir(clone_path) do
      yield
    end
  end

  def create_temp_repo(clone_name)
    clone_path = File.join(TEST_FIXTURES, clone_name)
    filename = 'git_test' + Time.now.to_i.to_s + rand(300).to_s.rjust(3, '0')
    path = File.expand_path(File.join("/tmp/", filename))
    FileUtils.mkdir_p(path)
    @tmp_path = File.realpath(path)
    FileUtils.cp_r(clone_path, @tmp_path)
    tmp_path = File.join(@tmp_path, File.basename(clone_path))
    FileUtils.cd tmp_path do
      FileUtils.mv('dot_git', '.git')
    end
    tmp_path
  end

  # Creates a temp directory and yields that path to the passed block
  #
  # On Windows, using Dir.mktmpdir with a block sometimes raises an error:
  # `Errno::ENOTEMPTY: Directory not empty @ dir_s_rmdir`. I think this might
  # be a configuration issue with the Windows CI environment.
  #
  # This was worked around by using the non-block form of Dir.mktmpdir and
  # then removing the directory manually in an ensure block.
  #
  def in_temp_dir
    tmpdir = Dir.mktmpdir
    tmpdir_realpath = File.realpath(tmpdir)
    Dir.chdir(tmpdir_realpath) do
      yield tmpdir_realpath
    end
  ensure
    FileUtils.rm_rf(tmpdir_realpath) if tmpdir_realpath
    # raise "Temp dir #{tmpdir} not removed. Remaining files : #{Dir["#{tmpdir}/**/*"]}" if File.exist?(tmpdir)
  end

  def create_file(path, content)
    File.open(path,'w') do |file|
      file.puts(content)
    end
  end

  def update_file(path, content)
    create_file(path,content)
  end

  def delete_file(path)
    File.delete(path)
  end

  def move_file(source_path, target_path)
    File.rename source_path, target_path
  end

  def new_file(name, contents)
    create_file(name,contents)
  end

  def append_file(name, contents)
    File.open(name, 'a') do |f|
      f.puts contents
    end
  end

  # Runs a block inside an environment with customized ENV variables.
  # It restores the ENV after execution.
  #
  # @param [Proc] block block to be executed within the customized environment
  #
  def with_custom_env_variables(&block)
    saved_env = {}
    begin
      Git::Lib::ENV_VARIABLE_NAMES.each { |k| saved_env[k] = ENV[k] }
      return block.call
    ensure
      Git::Lib::ENV_VARIABLE_NAMES.each { |k| ENV[k] = saved_env[k] }
    end
  end

  # Assert that the expected command line args are generated for a given Git::Lib method
  #
  # This assertion generates an empty git repository and then runs calls
  # Git::Base method named by `git_cmd` passing that method `git_cmd_args`.
  #
  # Before calling `git_cmd`, this method stubs the `Git::Lib#command` method to
  # capture the args sent to it by `git_cmd`. These args are captured into
  # `actual_command_line`.
  #
  # assert_equal is called comparing the given `expected_command_line` to
  # `actual_command_line`.
  #
  # @example Fetch with no args
  #   expected_command_line = ['fetch', '--', 'origin']
  #   git_cmd = :fetch
  #   git_cmd_args = []
  #   assert_command_line(expected_command_line, git_cmd, git_cmd_args)
  #
  # @example Fetch with some args
  #   expected_command_line = ['fetch', '--depth', '2', '--', 'origin', 'master']
  #   git_cmd = :fetch
  #   git_cmd_args = ['origin', ref: 'master', depth: '2']
  #   assert_command_line(expected_command_line, git_cmd, git_cmd_args)
  #
  # @example Fetch all
  #   expected_command_line = ['fetch', '--all']
  #   git_cmd = :fetch
  #   git_cmd_args = [all: true]
  #   assert_command_line(expected_command_line, git_cmd, git_cmd_args)
  #
  # @param expected_command_line [Array<String>] The expected arguments to be sent to Git::Lib#command
  # @param git_cmd [Symbol] the method to be called on the Git::Base object
  # @param git_cmd_args [Array<Object>] The arguments to be sent to the git_cmd method
  #
  # @yield [git] An initialization block
  #   The initialization block is called after a test project is created with Git.init.
  #   The current working directory is set to the root of the test project's working tree.
  # @yieldparam git [Git::Base] The Git::Base object resulting from initializing the test project
  # @yieldreturn [void] the return value of the block is ignored
  #
  # @return [void]
  #
  def assert_command_line(expected_command_line, git_cmd, git_cmd_args)
    actual_command_line = nil

    in_temp_dir do |path|
      git = Git.init('test_project')

      Dir.chdir 'test_project' do
        yield(git) if block_given?

        # Mock the Git::Lib#command method to capture the actual command line args
        git.lib.define_singleton_method(:command) do |cmd, *opts, &block|
          actual_command_line = [cmd, *opts.flatten]
        end

        git.send(git_cmd, *git_cmd_args)
      end
    end

    assert_equal(expected_command_line, actual_command_line)
  end

  def assert_child_process_success(&block)
    yield
    assert_equal 0, $CHILD_STATUS.exitstatus, "Child process failed with exitstatus #{$CHILD_STATUS.exitstatus}"
  end
end
