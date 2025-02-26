# frozen_string_literal: true

require 'test_helper'

class TestSubmodule < Test::Unit::TestCase
  test 'Git.open should be able to open a submodule' do
    in_temp_dir do
      submodule = Git.init('submodule', initial_branch: 'main')
      File.write('submodule/README.md', '# Submodule')
      submodule.add('README.md')
      submodule.commit('Add README.md')

      repo = Git.init('repo', initial_branch: 'main')
      File.write('repo/README.md', '# Main Repository')
      repo.add('README.md')
      repo.commit('Add README.md')

      Dir.chdir('repo') do
        assert_child_process_success { `git -c protocol.file.allow=always submodule add ../submodule submodule 2>&1` }
        assert_child_process_success { `git commit -am "Add submodule" 2>&1` }
      end

      submodule_repo = assert_nothing_raised { Git.open('repo/submodule') }

      assert_equal(submodule.object('HEAD').sha, submodule_repo.object('HEAD').sha)
    end
  end

  test 'Git.open should be able to open a submodule from a subdirectory within the submodule' do
    in_temp_dir do
      submodule = Git.init('submodule', initial_branch: 'main')
      Dir.mkdir('submodule/subdir')
      File.write('submodule/subdir/README.md', '# Submodule')
      submodule.add('subdir/README.md')
      submodule.commit('Add README.md')

      repo = Git.init('repo', initial_branch: 'main')
      File.write('repo/README.md', '# Main Repository')
      repo.add('README.md')
      repo.commit('Add README.md')

      Dir.chdir('repo') do
        assert_child_process_success { `git -c protocol.file.allow=always submodule add ../submodule submodule 2>&1` }
        assert_child_process_success { `git commit -am "Add submodule" 2>&1` }
      end

      submodule_repo = assert_nothing_raised { Git.open('repo/submodule/subdir') }

      repo_files = submodule_repo.ls_files
      assert(repo_files.include?('subdir/README.md'))
    end
  end
end
