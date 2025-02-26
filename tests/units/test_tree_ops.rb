# frozen_string_literal: true

require 'test_helper'

class TestTreeOps < Test::Unit::TestCase

  def test_read_tree
    treeish = 'testbranch1'
    expected_command_line = ['read-tree', treeish, {}]
    assert_command_line_eq(expected_command_line) { |git| git.read_tree(treeish) }
  end

  def test_read_tree_with_prefix
    treeish = 'testbranch1'
    prefix = 'foo'
    expected_command_line = ['read-tree', "--prefix=#{prefix}", treeish, {}]
    assert_command_line_eq(expected_command_line) { |git| git.read_tree(treeish, prefix: prefix) }
  end

  def test_write_tree
    expected_output = 'aa7349e'
    actual_output = nil
    expected_command_line = ['write-tree', {}]
    assert_command_line_eq(expected_command_line, mocked_output: expected_output) do |git|
      actual_output = git.write_tree
    end

    # the git output should be returned from Git::Base#write_tree
    assert_equal(expected_output, actual_output)
  end

  def test_commit_tree_with_default_message
    tree = 'tree-ref'
    message = 'commit tree tree-ref'

    expected_command_line = ['commit-tree', tree, '-m', message, {}]

    assert_command_line_eq(expected_command_line) { |git| git.commit_tree(tree) }
  end

  def test_commit_tree_with_message
    tree = 'tree-ref'
    message = 'this is my message'

    expected_command_line = ['commit-tree', tree, '-m', message, {}]

    assert_command_line_eq(expected_command_line) { |git| git.commit_tree(tree, message: message) }
  end

  def test_commit_tree_with_parent
    tree = 'tree-ref'
    message = 'this is my message'
    parent = 'parent-commit'

    expected_command_line = ['commit-tree', tree, "-p", parent, '-m', message, {}]

    assert_command_line_eq(expected_command_line) { |git| git.commit_tree(tree, parent: parent, message: message) }
  end

  def test_commit_tree_with_parents
    tree = 'tree-ref'
    message = 'this is my message'
    parents = 'commit1'

    expected_command_line = ['commit-tree', tree, '-p', 'commit1', '-m', message, {}]

    assert_command_line_eq(expected_command_line) { |git| git.commit_tree(tree, parents: parents, message: message) }
  end

  def test_commit_tree_with_multiple_parents
    tree = 'tree-ref'
    message = 'this is my message'
    parents = ['commit1', 'commit2']

    expected_command_line = ['commit-tree', tree, '-p', 'commit1', '-p', 'commit2', '-m', message, {}]

    assert_command_line_eq(expected_command_line) { |git| git.commit_tree(tree, parents: parents, message: message) }
  end

  # Examples of how to use Git::Base#commit_tree, write_tree, and commit_tree
  #
  # def test_tree_ops
  #   in_bare_repo_clone do |g|
  #     g.branch('testbranch1').in_branch('tb commit 1') do
  #       new_file('test-file1', 'blahblahblah2')
  #       g.add
  #       true
  #     end
  #
  #     g.branch('testbranch2').in_branch('tb commit 2') do
  #       new_file('test-file2', 'blahblahblah3')
  #       g.add
  #       true
  #     end
  #
  #     g.branch('testbranch3').in_branch('tb commit 3') do
  #       new_file('test-file3', 'blahblahblah4')
  #       g.add
  #       true
  #     end
  #
  #     # test some read-trees
  #     tr = g.with_temp_index do
  #       g.read_tree('testbranch1')
  #       g.read_tree('testbranch2', :prefix => 'b2/')
  #       g.read_tree('testbranch3', :prefix => 'b2/b3/')
  #       index = g.ls_files
  #       assert(index['b2/test-file2'])
  #       assert(index['b2/b3/test-file3'])
  #       g.write_tree
  #     end
  #
  #     assert_equal('2423ef1b38b3a140bbebf625ba024189c872e08b', tr)
  #
  #     # only prefixed read-trees
  #     tr = g.with_temp_index do
  #       g.add  # add whats in our working tree
  #       g.read_tree('testbranch1', :prefix => 'b1/')
  #       g.read_tree('testbranch3', :prefix => 'b2/b3/')
  #       index = g.ls_files
  #       assert(index['example.txt'])
  #       assert(index['b1/test-file1'])
  #       assert(!index['b2/test-file2'])
  #       assert(index['b2/b3/test-file3'])
  #       g.write_tree
  #     end
  #
  #     assert_equal('aa7349e1cdaf4b85cc6a6a0cf4f9b3f24879fa42', tr)
  #
  #     # new working directory too
  #     tr = nil
  #     g.with_temp_working do
  #       tr = g.with_temp_index do
  #         begin
  #           g.add
  #         rescue Exception => e
  #           # Adding nothig is now validd on Git 1.7.x
  #           # If an error ocurres (Git 1.6.x) it MUST raise Git::FailedError
  #           assert_equal(e.class, Git::FailedError)
  #         end
  #         g.read_tree('testbranch1', :prefix => 'b1/')
  #         g.read_tree('testbranch3', :prefix => 'b1/b3/')
  #         index = g.ls_files
  #         assert(!index['example.txt'])
  #         assert(index['b1/test-file1'])
  #         assert(!index['b2/test-file2'])
  #         assert(index['b1/b3/test-file3'])
  #         g.write_tree
  #       end
  #       assert_equal('b40f7a9072cdec637725700668f8fdebe39e6d38', tr)
  #     end
  #
  #     c = g.commit_tree(tr, :parents => 'HEAD')
  #     assert(c.commit?)
  #     assert_equal('b40f7a9072cdec637725700668f8fdebe39e6d38', c.gtree.sha)
  #
  #     g.with_temp_index do
  #       g.read_tree('testbranch1', :prefix => 'b1/')
  #       g.read_tree('testbranch3', :prefix => 'b3/')
  #       index = g.ls_files
  #       assert(!index['b2/test-file2'])
  #       assert(index['b3/test-file3'])
  #       g.commit('hi')
  #     end
  #
  #     assert(c.commit?)
  #
  #     files = g.ls_files
  #     assert(!files['b1/example.txt'])
  #
  #     g.branch('newbranch').update_ref(c)
  #     g.checkout('newbranch')
  #     assert(!files['b1/example.txt'])
  #
  #     assert_equal('b40f7a9072cdec637725700668f8fdebe39e6d38', c.gtree.sha)
  #
  #     g.with_temp_working do
  #       assert(!File.directory?('b1'))
  #       g.checkout_index
  #       assert(!File.directory?('b1'))
  #       g.checkout_index(:all => true)
  #       assert(File.directory?('b1'))
  #     end
  #   end
  # end
end
