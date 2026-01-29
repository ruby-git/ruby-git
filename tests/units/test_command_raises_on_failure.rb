# frozen_string_literal: true

require 'test_helper'

# Tests that Git::Lib#command raises Git::FailedError on non-zero exit status by default
#
# This behavior is critical for backward compatibility - the original command
# method raised on failure, and raise_on_failure: true (the default) preserves this.
#
class TestCommandRaisesOnFailure < Test::Unit::TestCase
  test 'command raises Git::FailedError on non-zero exit status by default' do
    in_temp_dir do |_path|
      git = Git.init('test_project')

      Dir.chdir('test_project') do
        # Try to show a non-existent ref - this should fail with exit code 128
        assert_raise(Git::FailedError) do
          git.lib.command('show', 'nonexistent-ref-that-does-not-exist')
        end
      end
    end
  end

  test 'command includes exit status in the error' do
    in_temp_dir do |_path|
      git = Git.init('test_project')

      Dir.chdir('test_project') do
        git.lib.command('show', 'nonexistent-ref-that-does-not-exist')
        flunk 'Expected Git::FailedError to be raised'
      rescue Git::FailedError => e
        assert_not_nil e.result
        assert_not_nil e.result.status
        assert_equal false, e.result.status.success?
      end
    end
  end

  test 'command with raise_on_failure: false does not raise on non-zero exit status' do
    in_temp_dir do |_path|
      git = Git.init('test_project')

      Dir.chdir('test_project') do
        # This should NOT raise - raise_on_failure: false suppresses the error
        result = git.lib.command('show', 'nonexistent-ref-that-does-not-exist', raise_on_failure: false)

        assert_instance_of Git::CommandLineResult, result
        assert_equal false, result.status.success?
      end
    end
  end

  test 'config_get raises Git::FailedError for non-existent config key' do
    in_temp_dir do |_path|
      git = Git.init('test_project')

      Dir.chdir('test_project') do
        # git config --get returns exit code 1 when key doesn't exist
        assert_raise(Git::FailedError) do
          git.lib.config_get('nonexistent.config.key.that.does.not.exist')
        end
      end
    end
  end

  test 'tag_sha returns empty string for non-existent tag' do
    in_temp_dir do |_path|
      git = Git.init('test_project')

      Dir.chdir('test_project') do
        # Create a commit so the repo isn't empty
        File.write('test.txt', 'content')
        git.add('test.txt')
        git.commit('Initial commit')

        # tag_sha for non-existent tag should return '' (special handling for exit code 1)
        result = git.lib.tag_sha('nonexistent-tag')
        assert_equal '', result
      end
    end
  end
end
