#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../test_helper'

class TestIndexOps < Test::Unit::TestCase
  
  def setup
    set_file_paths
    @git = Git.open(@wdir)
  end
  
  def test_add
    in_temp_dir do |path|
      g = Git.clone(@wbare, 'new')
      Dir.chdir('new') do
        assert_equal('100644', g.status['example.txt'].mode_index)
        
        new_file('test-file', 'blahblahblah')
        assert(g.status.untracked.assoc('test-file'))
        
        g.add
        assert(g.status.added.assoc('test-file'))
        assert(!g.status.untracked.assoc('test-file'))
        assert(!g.status.changed.assoc('example.txt'))
        
        new_file('example.txt', 'hahahaha')
        assert(g.status.changed.assoc('example.txt'))
        
        g.add
        assert(g.status.changed.assoc('example.txt'))
        
        g.commit('my message')
        assert(!g.status.changed.assoc('example.txt'))
        assert(!g.status.added.assoc('test-file'))
        assert(!g.status.untracked.assoc('test-file')) 
        assert_equal('hahahaha', g.status['example.txt'].blob.contents)
      end
    end
  end

  def test_clean
    in_temp_dir do |path|
      g = Git.clone(@wbare, 'clean_me')
      Dir.chdir('clean_me') do
        new_file('test-file', 'blahblahbal')
        g.add
        g.commit("first commit")

        new_file('file-to-clean', 'blablahbla')
        FileUtils.mkdir_p("dir_to_clean")

        Dir.chdir('dir_to_clean') do
          new_file('clean-me-too', 'blablahbla')
        end

        assert(File.exists?('file-to-clean'))
        assert(File.exists?('dir_to_clean'))
        
        g.clean(:force => true)
        
        assert(!File.exists?('file-to-clean'))
        assert(File.exists?('dir_to_clean'))
        
        new_file('file-to-clean', 'blablahbla')
        
        g.clean(:force => true, :d => true)

        assert(!File.exists?('file-to-clean'))
        assert(!File.exists?('dir_to_clean'))
      end
    end
  end
  
  def test_revert
    in_temp_dir do |path|
      g = Git.clone(@wbare, 'new')
      Dir.chdir('new') do
        new_file('test-file', 'blahblahbal')
        g.add
        g.commit("first commit")
        first_commit = g.gcommit('HEAD')

        new_file('test-file2', 'blablahbla')
        g.add
        g.commit("second-commit")
        g.gcommit('HEAD')

        commits = g.log(1e4).count
        g.revert(first_commit.sha)
        assert_equal(commits + 1, g.log(1e4).count)
        assert(!File.exists?('test-file2'))
      end
    end
  end

  def test_add_array
    in_temp_dir do |path|
      g = Git.clone(@wbare, 'new')
      Dir.chdir('new') do
        
        new_file('test-file1', 'blahblahblah1')
        new_file('test-file2', 'blahblahblah2')
        assert(g.status.untracked.assoc('test-file1'))
        
        g.add(['test-file1', 'test-file2'])
        assert(g.status.added.assoc('test-file1'))
        assert(g.status.added.assoc('test-file1'))
        assert(!g.status.untracked.assoc('test-file1'))
                
        g.commit('my message')
        assert(!g.status.added.assoc('test-file1'))
        assert(!g.status.untracked.assoc('test-file1')) 
        assert_equal('blahblahblah1', g.status['test-file1'].blob.contents)
      end
    end
  end
  
  def test_remove
    in_temp_dir do |path|
      g = Git.clone(@wbare, 'remove_test')
      Dir.chdir('remove_test') do
        assert(g.status['example.txt'])
        g.remove('example.txt')
        assert(g.status.deleted.assoc('example.txt')) 
        g.commit('deleted file')
        assert(!g.status['example.txt'])
      end
    end
  end
  
  def test_reset
    in_temp_dir do |path|
      g = Git.clone(@wbare, 'reset_test')
      Dir.chdir('reset_test') do
        new_file('test-file1', 'blahblahblah1')
        new_file('test-file2', 'blahblahblah2')
        assert(g.status.untracked.assoc('test-file1'))
        
        g.add(['test-file1', 'test-file2'])
        assert(!g.status.untracked.assoc('test-file1'))
        
        g.reset
        assert(g.status.untracked.assoc('test-file1'))
        assert(!g.status.added.assoc('test-file1'))
      end
    end
  end
  
end
