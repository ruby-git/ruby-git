# frozen_string_literal: true

require 'test_helper'

# Tests that dir, repo, and index return Pathname objects with expected behavior
class TestGitPath < Test::Unit::TestCase
  def setup
    clone_working_repo
    @git = Git.open(@wdir)
  end

  def test_dir_returns_pathname
    assert_instance_of(Pathname, @git.dir)
    assert_equal(@wdir, @git.dir.to_s)
  end

  def test_repo_returns_pathname
    assert_instance_of(Pathname, @git.repo)
    assert_equal(File.join(@wdir, '.git'), @git.repo.to_s)
  end

  def test_index_returns_pathname
    assert_instance_of(Pathname, @git.index)
    assert_equal(File.join(@wdir, '.git', 'index'), @git.index.to_s)
  end

  def test_readables
    assert(@git.dir.readable?)
    assert(@git.index.readable?)
    assert(@git.repo.readable?)
  end

  def test_writables_in_temp_dir
    in_temp_dir do |dir|
      FileUtils.cp_r(@wdir, 'test')
      g = Git.open(File.join(dir, 'test'))

      assert(g.dir.writable?)
      assert(g.index.writable?)
      assert(g.repo.writable?)
    end
  end
end
