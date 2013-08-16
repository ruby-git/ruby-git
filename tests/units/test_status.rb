
#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../test_helper'

class TestStatus < Test::Unit::TestCase

  def setup
    set_file_paths
  end

  def test_dot_files_status
    in_temp_dir do |path|
      git = Git.clone(@wdir, 'test_dot_files_status')
      
      create_file('test_dot_files_status/test_file_1', 'content tets_file_1')
      create_file('test_dot_files_status/.test_file_2', 'content test_file_2')
      
      git.add('test_file_1')
      git.add('.test_file_2')
      
      assert(git.status.added.assoc('test_file_1'))
      assert(git.status.added.assoc('.test_file_2'))
    end
  end

end
