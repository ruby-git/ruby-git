#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../test_helper'

require 'logger'
require 'stringio'

# Tests for Git::Lib#repository_default_branch
#
class TestLibRepositoryDefaultBranch < Test::Unit::TestCase
  def test_default_branch
    repository = 'new_repo'
    in_temp_dir do
      create_local_repository(repository, initial_branch: 'main')
      assert_equal('main', Git.default_branch(repository))
    end
  end

  def test_default_branch_with_logging
    repository = 'new_repo'
    in_temp_dir do
      create_local_repository(repository, initial_branch: 'main')
      log_device = StringIO.new
      logger = Logger.new(log_device, level: Logger::INFO)
      Git.default_branch(repository, log: logger)
      assert_match(/git.*ls-remote/, log_device.string)
    end
  end

  private

  def create_local_repository(subdirectory, initial_branch: 'main')
    git = Git.init(subdirectory, initial_branch: initial_branch)

    FileUtils.cd(subdirectory) do
      File.write('README.md', '# This is a README')
      git.add('README.md')
      git.commit('Initial commit')
    end
  end
end
