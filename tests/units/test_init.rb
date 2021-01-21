#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../test_helper'
require 'stringio'
require 'logger'

class TestInit < Test::Unit::TestCase
  def setup
    set_file_paths
  end

  def test_open_simple
    g = Git.open(@wdir)
    assert_match(/^C?:?#{@wdir}$/, g.dir.path)
    assert_match(/^C?:?#{File.join(@wdir, '.git')}$/, g.repo.path)
    assert_match(/^C?:?#{File.join(@wdir, '.git', 'index')}$/, g.index.path)
  end

  def test_open_opts
    g = Git.open @wdir, :repository => @wbare, :index => @index
    assert_equal(g.repo.path, @wbare)
    assert_equal(g.index.path, @index)
  end

  def test_git_bare
    g = Git.bare @wbare
    assert_equal(g.repo.path, @wbare)
  end

  #g = Git.init
  #  Git.init('project')
  #  Git.init('/home/schacon/proj',
  #		{ :git_dir => '/opt/git/proj.git',
  #		  :index_file => '/tmp/index'} )
  def test_git_init
    in_temp_dir do |path|
      repo = Git.init(path)
      assert(File.directory?(File.join(path, '.git')))
      assert(File.exist?(File.join(path, '.git', 'config')))
      assert_equal('false', repo.config('core.bare'))
    end
  end

  def test_git_init_bare
    in_temp_dir do |path|
      repo = Git.init(path, :bare => true)
      assert(File.exist?(File.join(path, 'config')))
      assert_equal('true', repo.config('core.bare'))
    end
  end

  def test_git_init_remote_git
    in_temp_dir do |dir|
      assert(!File.exist?(File.join(dir, 'config')))

      in_temp_dir do |path|
        Git.init(path, :repository => dir)
        assert(File.exist?(File.join(dir, 'config')))
      end
    end
  end

  def test_git_clone
    in_temp_dir do |path|
      g = Git.clone(@wbare, 'bare-co')
      assert(File.exist?(File.join(g.repo.path, 'config')))
      assert(g.dir)
    end
  end

  def test_git_clone_with_branch
    in_temp_dir do |path|
      g = Git.clone(@wbare, 'clone-branch', :branch => 'test')
      assert_equal(g.current_branch, 'test')
    end
  end

  def test_git_clone_bare
    in_temp_dir do |path|
      g = Git.clone(@wbare, 'bare.git', :bare => true)
      assert(File.exist?(File.join(g.repo.path, 'config')))
      assert_nil(g.dir)
    end
  end

  def test_git_clone_mirror
    in_temp_dir do |path|
      g = Git.clone(@wbare, 'bare.git', :mirror => true)
      assert(File.exist?(File.join(g.repo.path, 'config')))
      assert_nil(g.dir)
    end
  end

  def test_git_clone_config
    in_temp_dir do |path|
      g = Git.clone(@wbare, 'config.git', :config => "receive.denyCurrentBranch=ignore")
      assert_equal('ignore', g.config['receive.denycurrentbranch'])
      assert(File.exist?(File.join(g.repo.path, 'config')))
      assert(g.dir)
    end
  end

  # If the :log option is not passed to Git.clone, the result should not
  # have a logger
  #
  def test_git_clone_without_log
    in_temp_dir do |path|
      g = Git.clone(@wbare, 'bare-co')
      actual_logger = g.instance_variable_get(:@logger)
      assert_equal(nil, actual_logger)
    end
  end

  # If the :log option is passed to Git.clone, the result should have
  # a logger set to the value of :log
  #
  def test_git_clone_log
    log_io = StringIO.new
    expected_logger = Logger.new(log_io)

    in_temp_dir do |path|
      g = Git.clone(@wbare, 'bare-co', { log: expected_logger })
      actual_logger = g.instance_variable_get(:@logger)
      assert_equal(expected_logger.object_id, actual_logger.object_id)

      # Ensure that both the clone and Git::Base creation are logged to the logger
      #
      assert_includes(log_io.string, "Cloning into 'bare-co'...")
      assert_includes(log_io.string, 'Starting Git')
    end
  end

  # trying to open a git project using a bare repo - rather than using Git.repo
  def test_git_open_error
    assert_raise ArgumentError do
      Git.open @wbare
    end
  end

end
