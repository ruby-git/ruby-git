#!/usr/bin/env ruby
require 'logger'
require File.dirname(__FILE__) + '/../test_helper'

class TestLogger < Test::Unit::TestCase

  def setup
    set_file_paths
  end

  def test_logger
    log = Tempfile.new('logfile')
    log.close

    logger = Logger.new(log.path)
    logger.level = Logger::DEBUG

    @git = Git.open(@wdir, :log => logger)
    @git.branches.size

    logc = File.read(log.path)
    assert_match(/INFO -- : git '--git-dir=[^']+' '--work-tree=[^']+' branch '-a'/, logc)
    assert_match(/DEBUG -- :   diff_over_patches/, logc)

    log = Tempfile.new('logfile')
    log.close
    logger = Logger.new(log.path)
    logger.level = Logger::INFO

    @git = Git.open(@wdir, :log => logger)
    @git.branches.size

    logc = File.read(log.path)
    assert_match(/INFO -- : git '--git-dir=[^']+' '--work-tree=[^']+' branch '-a'/, logc)
    assert_not_match(/DEBUG -- :   diff_over_patches/, logc)
  end

end
