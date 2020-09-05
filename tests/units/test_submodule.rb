#!/usr/bin/env ruby
require 'fileutils'
require File.dirname(__FILE__) + '/../test_helper'

class TestSubmodule < Test::Unit::TestCase
  def git_working_dir
    cwd = `pwd`.chomp
    if File.directory?(File.join(cwd, 'files'))
      test_dir = File.join(cwd, 'files')
    elsif File.directory?(File.join(cwd, '..', 'files'))
      test_dir = File.join(cwd, '..', 'files')
    elsif File.directory?(File.join(cwd, 'tests', 'files'))
      test_dir = File.join(cwd, 'tests', 'files')
    end

    create_temp_repo(File.expand_path(File.join(test_dir, 'submodule')))
  end

  def create_temp_repo(clone_path)
    filename = 'git_test' + Time.now.to_i.to_s + rand(300).to_s.rjust(3, '0')
    @tmp_path = File.join("/tmp/", filename)
    FileUtils.mkdir_p(@tmp_path)
    FileUtils.cp_r(clone_path, @tmp_path)
    tmp_path = File.join(@tmp_path, File.basename(clone_path))
    Dir.chdir(tmp_path) do
      FileUtils.mv('dot_git', '.git')
    end
    tmp_path_submodule = File.join(tmp_path, 'unlicense_only')
    Dir.chdir(tmp_path_submodule) do
      FileUtils.mv('dot_git', '.git')
    end
    @tmp_path = tmp_path
  end

  def setup
    @git = Git.open(git_working_dir)
    
    @commit = @git.object('1cc8667014381')
    @tree = @git.object('1cc8667014381^{tree}')
    @blob = @git.object('v2.5:example.txt')
  end
  
  def test_submodule_open
    submodule_path = File.join(@tmp_path, 'unlicense_only')
    g = Git.open(submodule_path)
    g.branch('new_branch').checkout
  end
end
