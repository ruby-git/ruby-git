# frozen_string_literal: true

require 'test/unit'
require File.join(File.dirname(__dir__), 'test_helper')

# Tests Git::URL.clone_to
#
class TestURLCloneTo < Test::Unit::TestCase
  def test_clone_to_full_repo
    GIT_URLS.each do |url_data|
      url = url_data[:url]
      expected_path = url_data[:expected_path]
      actual_path = Git::URL.clone_to(url)
      assert_equal(
        expected_path, actual_path,
        "Failed to determine the clone path for URL '#{url}' correctly"
      )
    end
  end

  def test_clone_to_bare_repo
    GIT_URLS.each do |url_data|
      url = url_data[:url]
      expected_path = url_data[:expected_bare_path]
      actual_path = Git::URL.clone_to(url, bare: true)
      assert_equal(
        expected_path, actual_path,
        "Failed to determine the clone path for URL '#{url}' correctly"
      )
    end
  end

  def test_clone_to_mirror_repo
    GIT_URLS.each do |url_data|
      url = url_data[:url]
      # The expected_path is the same for bare and mirror repos
      expected_path = url_data[:expected_bare_path]
      actual_path = Git::URL.clone_to(url, mirror: true)
      assert_equal(
        expected_path, actual_path,
        "Failed to determine the clone path for URL '#{url}' correctly"
      )
    end
  end

  GIT_URLS = [
    {
      url: 'https://github.com/org/repo',
      expected_path: 'repo',
      expected_bare_path: 'repo.git'
    },
    {
      url: 'https://github.com/org/repo.git',
      expected_path: 'repo',
      expected_bare_path: 'repo.git'
    },
    {
      url: 'https://git.mydomain.com/org/repo/.git',
      expected_path: 'repo',
      expected_bare_path: 'repo.git'
    }
  ].freeze

  # Git::URL.clone_to makes some assumptions about how the `git` command names
  # the directory to clone to.  This test ensures that the assumptions are
  # correct.
  #
  def test_git_clone_naming_assumptions
    in_temp_dir do |_path|
      setup_test_repositories

      GIT_CLONE_COMMANDS.each do |command_data|
        command = command_data[:command]
        expected_path = command_data[:expected_path]

        output = `#{command} 2>&1`

        assert_match(/Cloning into (?:bare repository )?'#{expected_path}'/, output)
        FileUtils.rm_rf(expected_path)
      end
    end
  end

  GIT_CLONE_COMMANDS = [
    # Clone to full repository
    { command: 'git clone server/my_project', expected_path: 'my_project' },
    { command: 'git clone server/my_project/.git', expected_path: 'my_project' },
    { command: 'git clone server/my_project.git', expected_path: 'my_project' },

    # Clone to bare repository
    { command: 'git clone --bare server/my_project', expected_path: 'my_project.git' },
    { command: 'git clone --bare server/my_project/.git', expected_path: 'my_project.git' },
    { command: 'git clone --bare server/my_project.git', expected_path: 'my_project.git' },

    # Clone to mirror repository
    { command: 'git clone --mirror server/my_project', expected_path: 'my_project.git' },
    { command: 'git clone --mirror server/my_project/.git', expected_path: 'my_project.git' },
    { command: 'git clone --mirror server/my_project.git', expected_path: 'my_project.git' }
  ].freeze

  def setup_test_repositories
    # Create a repository to clone from
    Dir.mkdir 'server'
    remote = Git.init('server/my_project')
    Dir.chdir('server/my_project') do
      new_file('README.md', '# My New Project')
      remote.add
      remote.commit('Initial version')
    end

    # Create a bare repository to clone from
    Git.clone('server/my_project', 'server/my_project.git', bare: true)
  end
end
