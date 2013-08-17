#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../test_helper'

class TestBase < Test::Unit::TestCase

  def setup
    set_file_paths
  end

  def test_add
    in_temp_dir do |path|
      git = Git.clone(@wdir, 'test_add')
      
      create_file('test_add/test_file_1', 'content tets_file_1')
      create_file('test_add/test_file_2', 'content test_file_2')
      create_file('test_add/test_file_3', 'content test_file_3')
      create_file('test_add/test_file_4', 'content test_file_4')
      
      assert(!git.status.added.assoc('test_file_1'))
      
      # Adding a single file, usign String
      git.add('test_file_1')

      assert(git.status.added.assoc('test_file_1'))
      assert(!git.status.added.assoc('test_file_2'))

      # Adding a single file, using Array
      git.add(['test_file_2'])

      assert(git.status.added.assoc('test_file_2'))
      assert(!git.status.added.assoc('test_file_3'))
      assert(!git.status.added.assoc('test_file_4'))

      # Adding multiple files, using Array
      git.add(['test_file_3','test_file_4'])

      assert(git.status.added.assoc('test_file_3'))
      assert(git.status.added.assoc('test_file_4'))
      
      git.commit('test_add commit #1')

      assert(git.status.added.empty?)
       
      delete_file('test_add/test_file_3')
      update_file('test_add/test_file_4', 'content test_file_4 update #1')
      create_file('test_add/test_file_5', 'content test_file_5')

      # Adding all files (new, updated or deleted), using :all
      git.add(:all => true)

      assert(git.status.deleted.assoc('test_file_3'))
      assert(git.status.changed.assoc('test_file_4'))
      assert(git.status.added.assoc('test_file_5'))
      
      git.commit('test_add commit #2')
      
      assert(git.status.deleted.empty?)
      assert(git.status.changed.empty?)
      assert(git.status.added.empty?)
      
      delete_file('test_add/test_file_4')
      update_file('test_add/test_file_5', 'content test_file_5 update #1')
      create_file('test_add/test_file_6', 'content test_fiile_6')
      
      # Adding all files (new or updated), without params
      git.add
      
      assert(git.status.deleted.assoc('test_file_4'))
      assert(git.status.changed.assoc('test_file_5'))
      assert(git.status.added.assoc('test_file_6'))
      
      git.commit('test_add commit #3')

      assert(!git.status.deleted.empty?)
      assert(git.status.changed.empty?)
      assert(git.status.added.empty?)
    end
  end

  def test_commit
    in_temp_dir do |path|
      git = Git.clone(@wdir, 'test_commit')
      
      create_file('test_commit/test_file_1', 'content tets_file_1')
      create_file('test_commit/test_file_2', 'content test_file_2')

      git.add('test_file_1')
      git.add('test_file_2')

      base_commit_id = git.log[0].objectish

      git.commit("Test Commit")

      original_commit_id = git.log[0].objectish

      create_file('test_commit/test_file_3', 'content test_file_3')
      
      git.add('test_file_3')

      git.commit(nil, :amend => true)

      assert(git.log[0].objectish != original_commit_id)
      assert(git.log[1].objectish == base_commit_id)
    end
  end

end
