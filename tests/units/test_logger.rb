# frozen_string_literal: true

require 'logger'
require 'test_helper'

class TestLogger < Test::Unit::TestCase
  def setup
    clone_working_repo
  end

  def missing_log_entry
    'Did not find expected log entry.'
  end

  def unexpected_log_entry
    'Unexpected log entry found'
  end

  def test_logger
    in_temp_dir do |_path|
      log_path = 'logfile.log'

      logger = Logger.new(log_path, level: Logger::DEBUG)

      @git = Git.open(@wdir, log: logger)
      @git.branches.size

      logc = File.read(log_path)

      expected_log_entry = /INFO -- : \[\{[^}]+}, "git", "(?<global_options>.*?)", "branch", "-a"/
      assert_match(expected_log_entry, logc, missing_log_entry)

      expected_log_entry = /DEBUG -- : stdout:\n"  cherry/
      assert_match(expected_log_entry, logc, missing_log_entry)
    end
  end

  def test_logging_at_info_level_should_not_show_debug_messages
    in_temp_dir do |_path|
      log_path = 'logfile.log'

      logger = Logger.new(log_path, level: Logger::INFO)

      @git = Git.open(@wdir, log: logger)
      @git.branches.size

      logc = File.read(log_path)

      expected_log_entry = /INFO -- : \[\{[^}]+}, "git", "(?<global_options>.*?)", "branch", "-a"/
      assert_match(expected_log_entry, logc, missing_log_entry)

      expected_log_entry = /DEBUG -- : stdout:\n"  cherry/
      assert_not_match(expected_log_entry, logc, unexpected_log_entry)
    end
  end
end
