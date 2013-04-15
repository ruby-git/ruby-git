require 'date'
require 'fileutils'
require 'logger'
require 'test/unit'

require "#{File.expand_path(File.dirname(__FILE__))}/../lib/git"

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
    
    @wdir_dot = File.expand_path(File.join(@test_dir, 'working'))
    @wbare = File.expand_path(File.join(@test_dir, 'working.git'))
    @index = File.expand_path(File.join(@test_dir, 'index'))
    
    @wdir = create_temp_repo(@wdir_dot)
  end
  
  def teardown
    if @tmp_path
      FileUtils.rm_r(@tmp_path)
    end
  end
  
  def create_temp_repo(clone_path)
    filename = 'git_test' + Time.now.to_i.to_s + rand(300).to_s.rjust(3, '0')
    @tmp_path = File.join("/tmp/", filename)
    FileUtils.mkdir_p(@tmp_path)
    FileUtils.cp_r(clone_path, @tmp_path)
    tmp_path = File.join(@tmp_path, 'working')
    Dir.chdir(tmp_path) do
      FileUtils.mv('dot_git', '.git')
    end
    tmp_path
  end
  
  def in_temp_dir(remove_after = true) # :yields: the temporary dir's path
    tmp_path = nil
    while tmp_path.nil? || File.directory?(tmp_path)
      filename = 'git_test' + Time.now.to_i.to_s + rand(300).to_s.rjust(3, '0')
      tmp_path = File.join("/tmp/", filename)
    end
    FileUtils.mkdir(tmp_path)
    Dir.chdir tmp_path do
      yield tmp_path
    end
    FileUtils.rm_r(tmp_path) if remove_after
  end
  
  def create_file(path, content)
    File.open(path,'w') do |file|
      file.puts(content)
    end
  end

  def update_file(path, content)
    create_file(path,content)
  end

  def delete_file(path)
    File.delete(path)
  end
  
  def new_file(name, contents)
    create_file(name,contents)
  end

  def append_file(name, contents)
    File.open(name, 'a') do |f|
      f.puts contents
    end
  end
  
end
