# frozen_string_literal: true

require 'test_helper'

class TestLsTree < Test::Unit::TestCase
  def test_ls_tree_with_submodules
    in_temp_dir do
      submodule = Git.init('submodule', initial_branch: 'main')
      File.write('submodule/README.md', '# Submodule')
      submodule.add('README.md')
      submodule.commit('Add README.md')

      repo = Git.init('repo', initial_branch: 'main')
      File.write('repo/README.md', '# Main Repository')
      repo.add('README.md')
      repo.commit('Add README.md')

      Dir.mkdir('repo/subdir')
      File.write('repo/subdir/file.md', 'Content in subdir')
      repo.add('subdir/file.md')
      repo.commit('Add subdir/file.md')

      # ls_tree
      default_tree = assert_nothing_raised { repo.ls_tree('HEAD') }
      assert_equal(default_tree['blob'].keys.sort, ['README.md'])
      assert_equal(default_tree['tree'].keys.sort, ['subdir'])
      # ls_tree with recursion into sub-trees
      recursive_tree = assert_nothing_raised { repo.ls_tree('HEAD', recursive: true) }
      assert_equal(recursive_tree['blob'].keys.sort, ['README.md', 'subdir/file.md'])
      assert_equal(recursive_tree['tree'].keys.sort, [])

      Dir.chdir('repo') do
        assert_child_process_success { `git -c protocol.file.allow=always submodule add ../submodule submodule 2>&1` }
        assert_child_process_success { `git commit -am "Add submodule" 2>&1` }
      end

      expected_submodule_sha = submodule.object('HEAD').sha

      # Make sure the ls_tree command can handle submodules (which show up as a commit object in the tree)
      tree = assert_nothing_raised { repo.ls_tree('HEAD') }
      actual_submodule_sha = tree.dig('commit', 'submodule', :sha)

      # Make sure the submodule commit was parsed correctly
      assert_equal(expected_submodule_sha, actual_submodule_sha, 'Submodule SHA was not returned')
    end
  end
end
