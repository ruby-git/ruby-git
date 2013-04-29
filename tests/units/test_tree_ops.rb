#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../test_helper'

class TestTreeOps < Test::Unit::TestCase

  def setup
    set_file_paths
    @git = Git.open(@wdir)
  end
  
  def test_read_tree
    
    in_temp_dir do
      g = Git.clone(@wbare, 'test')

      g.chdir do
        g.branch('testbranch1').in_branch('tb commit 1') do
          new_file('test-file1', 'blahblahblah2')
          g.add
          true          
        end

        g.branch('testbranch2').in_branch('tb commit 2') do
          new_file('test-file2', 'blahblahblah3')
          g.add
          true          
        end

        g.branch('testbranch3').in_branch('tb commit 3') do
          new_file('test-file3', 'blahblahblah4')
          g.add
          true          
        end
    
        # test some read-trees
        tr = g.with_temp_index do
          g.read_tree('testbranch1')
          g.read_tree('testbranch2', :prefix => 'b2/')
          g.read_tree('testbranch3', :prefix => 'b2/b3/')
          index = g.ls_files
          assert(index['b2/test-file2'])
          assert(index['b2/b3/test-file3'])
          g.write_tree
        end

        assert_equal('2423ef1b38b3a140bbebf625ba024189c872e08b', tr)
              
        # only prefixed read-trees
        tr = g.with_temp_index do
          g.add  # add whats in our working tree
          g.read_tree('testbranch1', :prefix => 'b1/')
          g.read_tree('testbranch3', :prefix => 'b2/b3/')
          index = g.ls_files
          assert(index['example.txt'])
          assert(index['b1/test-file1'])
          assert(!index['b2/test-file2'])
          assert(index['b2/b3/test-file3'])
          g.write_tree
        end

        assert_equal('aa7349e1cdaf4b85cc6a6a0cf4f9b3f24879fa42', tr)
        
        # new working directory too
        tr = nil
        g.with_temp_working do
          tr = g.with_temp_index do
            begin 
              g.add
            rescue Exception => e
              # Adding nothig is now validd on Git 1.7.x
              # If an error ocurres (Git 1.6.x) it MUST rise Git::GitExecuteError
              assert_equal(e.class, Git::GitExecuteError)
            end
            g.read_tree('testbranch1', :prefix => 'b1/')
            g.read_tree('testbranch3', :prefix => 'b1/b3/')
            index = g.ls_files
            assert(!index['example.txt'])
            assert(index['b1/test-file1'])
            assert(!index['b2/test-file2'])
            assert(index['b1/b3/test-file3'])
            g.write_tree
          end
          assert_equal('b40f7a9072cdec637725700668f8fdebe39e6d38', tr)
        end
        
        c = g.commit_tree(tr, :parents => 'HEAD')
        assert(c.commit?)
        assert_equal('b40f7a9072cdec637725700668f8fdebe39e6d38', c.gtree.sha)
        
        tmp = Tempfile.new('tesxt')
        tmppath = tmp.path
        tmp.close
        tmp.unlink
        
        g.with_index(tmppath) do
          g.read_tree('testbranch1', :prefix => 'b1/')
          g.read_tree('testbranch3', :prefix => 'b3/')
          index = g.ls_files
          assert(!index['b2/test-file2'])
          assert(index['b3/test-file3'])
          g.commit('hi')
        end

        assert(c.commit?)

        files = g.ls_files
        assert(!files['b1/example.txt'])
        
        g.branch('newbranch').update_ref(c)        
        g.checkout('newbranch')
        assert(!files['b1/example.txt'])
        
        assert_equal('b40f7a9072cdec637725700668f8fdebe39e6d38', c.gtree.sha)
        
        g.with_temp_working do 
          assert(!File.directory?('b1'))
          g.checkout_index
          assert(!File.directory?('b1'))
          g.checkout_index(:all => true)
          assert(File.directory?('b1'))
        end
        
      end
    end
  end

end
