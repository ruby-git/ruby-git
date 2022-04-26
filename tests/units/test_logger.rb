#!/usr/bin/env ruby
require 'logger'
require File.dirname(__FILE__) + '/../test_helper'

class TestLogger < Test::Unit::TestCase

  def setup
    set_file_paths
  end

  def missing_log_entry
    'Did not find expected log entry.'
  end

  def unexpected_log_entry
    'Unexpected log entry found'
  end

  def test_logger
    log = Tempfile.new('logfile')
    log.close

    logger = Logger.new(log.path)
    logger.level = Logger::DEBUG

    @git = Git.open(@wdir, :log => logger)
    @git.branches.size

    logc = File.read(log.path)

    expected_log_entry = /INFO -- : git (?<global_options>.*?) branch ['"]-a['"]/
    assert_match(expected_log_entry, logc, missing_log_entry)

    expected_log_entry = /DEBUG -- :   cherry/
    assert_match(expected_log_entry, logc, missing_log_entry)
  end

  def test_logging_at_info_level_should_not_show_debug_messages
    log = Tempfile.new('logfile')
    log.close
    logger = Logger.new(log.path)
    logger.level = Logger::INFO

    @git = Git.open(@wdir, :log => logger)
    @git.branches.size

    logc = File.read(log.path)

    expected_log_entry = /INFO -- : git (?<global_options>.*?) branch ['"]-a['"]/
    assert_match(expected_log_entry, logc, missing_log_entry)

    expected_log_entry = /DEBUG -- :   cherry/
    assert_not_match(expected_log_entry, logc, unexpected_log_entry)
  end
end
