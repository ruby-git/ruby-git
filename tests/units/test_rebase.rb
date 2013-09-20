#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../test_helper'

class TestRebase < Test::Unit::TestCase
  def setup
    set_file_paths
  end
  
  def test_branch_and_rebase
    in_temp_dir do |path|
      g = Git.clone(@wbare, 'branch_merge_test')
      Dir.chdir('branch_merge_test') do

        branch_message = 'branch_file'
        g.branch('new_branch').in_branch(branch_message) do
          assert_equal('new_branch', g.current_branch)
          new_file('new_file_2', 'hello')
          g.add
          true
        end

        assert_equal('master', g.current_branch)
        new_file('new_file_1', 'hello')
        g.add        
        g.commit 'master'

        assert_equal('master', g.current_branch)
        assert(!g.status['new_file_2']) 
        
        assert(g.branch('new_branch').rebase)
        g.branch('new_branch').in_branch do 
          assert(g.status['new_file_1'])
          assert(g.status['new_file_2'])
          assert_equal(branch_message, g.log.first.message)
        end
      end
    end
  end
  
  # def test_branch_and_merge_two
  #   in_temp_dir do |path|
  #     g = Git.clone(@wbare, 'branch_merge_test')
  #     Dir.chdir('branch_merge_test') do

  #       g.branch('new_branch').in_branch('test') do
  #         assert_equal('new_branch', g.current_branch)
  #         new_file('new_file_1', 'hello')
  #         new_file('new_file_2', 'hello')
  #         g.add
  #         true
  #       end

  #       g.branch('new_branch2').in_branch('test') do
  #         assert_equal('new_branch2', g.current_branch)
  #         new_file('new_file_3', 'hello')
  #         new_file('new_file_4', 'hello')
  #         g.add
  #         true
  #       end

  #       g.branch('new_branch').merge('new_branch2')
  #       assert(!g.status['new_file_3'])  # still in master branch

  #       g.branch('new_branch').checkout
  #       assert(g.status['new_file_3'])  # file has been merged in
        
  #       g.branch('master').checkout
  #       g.merge(g.branch('new_branch'))
  #       assert(g.status['new_file_3'])  # file has been merged in
        
  #     end
  #   end
  # end
  
  # def test_branch_and_merge_multiple
  #   in_temp_dir do |path|
  #     g = Git.clone(@wbare, 'branch_merge_test')
  #     Dir.chdir('branch_merge_test') do

  #       g.branch('new_branch').in_branch('test') do
  #         assert_equal('new_branch', g.current_branch)
  #         new_file('new_file_1', 'hello')
  #         new_file('new_file_2', 'hello')
  #         g.add
  #         true
  #       end

  #       g.branch('new_branch2').in_branch('test') do
  #         assert_equal('new_branch2', g.current_branch)
  #         new_file('new_file_3', 'hello')
  #         new_file('new_file_4', 'hello')
  #         g.add
  #         true
  #       end

  #       assert(!g.status['new_file_1'])  # still in master branch
  #       assert(!g.status['new_file_3'])  # still in master branch

  #       g.merge(['new_branch', 'new_branch2'])

  #       assert(g.status['new_file_1'])  # file has been merged in
  #       assert(g.status['new_file_3'])  # file has been merged in
                
  #     end
  #   end
  # end
  
end