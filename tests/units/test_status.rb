
#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../test_helper'

class TestStatus < Test::Unit::TestCase

  def setup
    set_file_paths
  end

  def test_status_pretty
    in_temp_dir do |path|
      git = Git.clone(@wdir, 'test_dot_files_status')
      string = "colon_numbers.txt\n\tsha(r)  \n\tsha(i) " \
               "e76778b73006b0dda0dd56e9257c5bf6b6dd3373 100644\n\ttype   \n\tstage  0\n\tuntrac \n" \
               "ex_dir/ex.txt\n\tsha(r)  \n\tsha(i) e69de29bb2d1d6434b8b29ae775ad8c2e48c5391 " \
               "100644\n\ttype   \n\tstage  0\n\tuntrac \nexample.txt\n\tsha(r)  \n\tsha(i) " \
               "8dc79ae7616abf1e2d4d5d97d566f2b2f6cee043 100644\n\ttype   \n\tstage  0\n\tuntrac " \
               "\nscott/newfile\n\tsha(r)  \n\tsha(i) 5d4606820736043f9eed2a6336661d6892c820a5 " \
               "100644\n\ttype   \n\tstage  0\n\tuntrac \nscott/text.txt\n\tsha(r)  \n\tsha(i) " \
               "3cc71b13d906e445da52785ddeff40dad1163d49 100644\n\ttype   \n\tstage  0\n\tuntrac \n\n"

      assert_equal(git.status.pretty, string)
    end
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

  def test_added_boolean
    in_temp_dir do |path|
      git = Git.clone(@wdir, 'test_dot_files_status')

      create_file('test_dot_files_status/test_file_1', 'content tets_file_1')
      create_file('test_dot_files_status/test_file_2', 'content tets_file_2')

      git.add('test_file_1')

      assert(git.status.added?('test_file_1'))
      assert(!git.status.added?('test_file_2'))
    end
  end

  def test_changed_boolean
    in_temp_dir do |path|
      git = Git.clone(@wdir, 'test_dot_files_status')

      create_file('test_dot_files_status/test_file_1', 'content tets_file_1')
      create_file('test_dot_files_status/test_file_2', 'content tets_file_2')

      git.add('test_file_1')
      git.add('test_file_2')
      git.commit('message')
      update_file('test_dot_files_status/test_file_1', 'update_content tets_file_1')

      assert(git.status.changed?('test_file_1'))
      assert(!git.status.changed?('test_file_2'))
    end
  end

  def test_deleted_boolean
    in_temp_dir do |path|
      git = Git.clone(@wdir, 'test_dot_files_status')

      create_file('test_dot_files_status/test_file_1', 'content tets_file_1')
      create_file('test_dot_files_status/test_file_2', 'content tets_file_2')

      git.add('test_file_1')
      git.commit('message')
      delete_file('test_dot_files_status/test_file_1')

      assert(git.status.deleted?('test_file_1'))
      assert(!git.status.deleted?('test_file_2'))
    end
  end

  def test_untracked_boolean
    in_temp_dir do |path|
      git = Git.clone(@wdir, 'test_dot_files_status')

      create_file('test_dot_files_status/test_file_1', 'content tets_file_1')
      create_file('test_dot_files_status/test_file_2', 'content tets_file_2')
      git.add('test_file_2')

      assert(git.status.untracked?('test_file_1'))
      assert(!git.status.untracked?('test_file_2'))
    end
  end

  def test_changed_cache
    in_temp_dir do |path|
      git = Git.clone(@wdir, 'test_dot_files_status')

      create_file('test_dot_files_status/test_file_1', 'hello')

      git.add('test_file_1')
      git.commit('message')

      delete_file('test_dot_files_status/test_file_1')
      create_file('test_dot_files_status/test_file_1', 'hello')

      assert(!git.status.changed?('test_file_1'))
    end
  end
end
