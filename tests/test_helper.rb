require 'test/unit'
require 'fileutils'
require File.dirname(__FILE__) + '/../lib/git'

class Test::Unit::TestCase
  
  def set_file_paths
    @wdir = File.join(File.dirname(__FILE__), 'files', 'working')
    @wbare = File.join(File.dirname(__FILE__), 'files', 'working.git')
    @index = File.join(File.dirname(__FILE__), 'files', 'index')
  end
  
  def in_temp_dir
    filename = 'git_test' + Time.now.to_i.to_s + rand(300).to_s
    tmp_path = File.join("/tmp/", filename)
    FileUtils.mkdir(tmp_path)
    Dir.chdir tmp_path do
      yield tmp_path
    end
    FileUtils.rm_r(tmp_path)
  end
  
end