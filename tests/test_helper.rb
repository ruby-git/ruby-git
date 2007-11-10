require 'test/unit'
require 'fileutils'
require File.dirname(__FILE__) + '/../lib/git'

class Test::Unit::TestCase
  
  def set_file_paths
    cwd = `pwd`.chomp
    if File.directory?(File.join(cwd, 'files'))
      @test_dir = File.join(cwd, 'files')
    elsif File.directory?(File.join(cwd, '..', 'files'))
      @test_dir = File.join(cwd, '..', 'files')
    elsif File.directory?(File.join(cwd, 'tests', 'files'))
      @test_dir = File.join(cwd, 'tests', 'files')
    end
    
    @wdir = File.expand_path(File.join(@test_dir, 'working'))
    @wbare = File.expand_path(File.join(@test_dir, 'working.git'))
    @index = File.expand_path(File.join(@test_dir, 'index'))
  end
  
  def in_temp_dir(remove_after = true)
    filename = 'git_test' + Time.now.to_i.to_s + rand(300).to_s
    tmp_path = File.join("/tmp/", filename)
    FileUtils.mkdir(tmp_path)
    Dir.chdir tmp_path do
      yield tmp_path
    end
    FileUtils.rm_r(tmp_path) if remove_after
  end
  
end