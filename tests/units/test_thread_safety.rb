# frozen_string_literal: true

require 'test_helper'

class TestThreadSafety < Test::Unit::TestCase
  def setup
    clone_working_repo
  end

  teardown
  def clean_environment
    # TODO: this was needed because test_thread_safety.rb ocassionally leaks setting GIT_DIR.
    # Once that is fixed, this can be removed.
    # I think it will be fixed by using System.spawn or something similar instead
    # of backticks to run git in Git::Lib#command.
    ENV['GIT_DIR'] = nil
    ENV['GIT_WORK_TREE'] = nil
    ENV['GIT_INDEX_FILE'] = nil
    ENV['GIT_SSH'] = nil
  end

  def test_git_init_bare
    dirs = []
    threads = []

    5.times do
      dirs << Dir.mktmpdir
    end

    dirs.each do |dir|
      threads << Thread.new do
        Git.init(dir, :bare => true)
      end
    end

    threads.each(&:join)

    dirs.each do |dir|
      Git.bare(dir).ls_files
    end
  end
end
