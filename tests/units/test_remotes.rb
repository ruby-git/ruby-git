# frozen_string_literal: true

require 'test_helper'

class TestRemotes < Test::Unit::TestCase
  def test_add_remote
    in_temp_dir do |_path|
      local = Git.clone(BARE_REPO_PATH, 'local')
      remote = Git.clone(BARE_REPO_PATH, 'remote')

      local.add_remote('testremote', remote)

      assert(!local.branches.map(&:full).include?('testremote/master'))
      assert(local.remotes.map(&:name).include?('testremote'))

      local.add_remote('testremote2', remote, fetch: true)

      assert(local.branches.map(&:full).include?('remotes/testremote2/master'))
      assert(local.remotes.map(&:name).include?('testremote2'))

      local.add_remote('testremote3', remote, track: 'master')

      assert( # We actually a new branch ('test_track') on the remote and track that one intead.
        local.branches.map(&:full).include?('master')
      )
      assert(local.remotes.map(&:name).include?('testremote3'))
    end
  end

  def test_remove_remote_remove
    in_temp_dir do |_path|
      local = Git.clone(BARE_REPO_PATH, 'local')
      remote = Git.clone(BARE_REPO_PATH, 'remote')

      local.add_remote('testremote', remote)
      local.remove_remote('testremote')

      assert(!local.remotes.map(&:name).include?('testremote'))

      local.add_remote('testremote', remote)
      local.remote('testremote').remove

      assert(!local.remotes.map(&:name).include?('testremote'))
    end
  end

  def test_set_remote_url
    in_temp_dir do |_path|
      local = Git.clone(BARE_REPO_PATH, 'local')
      remote1 = Git.clone(BARE_REPO_PATH, 'remote1')
      remote2 = Git.clone(BARE_REPO_PATH, 'remote2')

      local.add_remote('testremote', remote1)
      local.set_remote_url('testremote', remote2)

      assert(local.remotes.map(&:name).include?('testremote'))
      assert(local.remote('testremote').url != remote1.repo.to_s)
      assert(local.remote('testremote').url == remote2.repo.to_s)
    end
  end

  def test_remote_set_branches_command
    expected_command_line = ['remote', 'set-branches', '--add', 'origin', '*', {}]

    assert_command_line_eq(expected_command_line) do |git|
      git.remote_set_branches('origin', '*', add: true)
    end
  end

  def test_remote_set_branches_command_without_add
    expected_command_line = ['remote', 'set-branches', 'origin', 'feature', {}]

    assert_command_line_eq(expected_command_line) do |git|
      git.remote_set_branches('origin', 'feature')
    end
  end

  def test_remote_set_branches_command_with_add_false
    expected_command_line = ['remote', 'set-branches', 'origin', 'feature', {}]

    assert_command_line_eq(expected_command_line) do |git|
      git.remote_set_branches('origin', 'feature', add: false)
    end
  end

  def test_remote_set_branches_command_with_multiple_branches
    expected_command_line = ['remote', 'set-branches', 'origin', 'feature', 'release/*', {}]

    assert_command_line_eq(expected_command_line) do |git|
      git.remote_set_branches('origin', 'feature', 'release/*')
    end
  end

  def test_remote_set_branches_requires_branch_arguments
    in_temp_dir do |_path|
      assert_raise ArgumentError do
        Git.init('test_project').remote_set_branches('origin')
      end
    end
  end

  def test_remote_set_branches_fetches_additional_branch
    in_temp_dir do |_path|
      upstream = Git.clone(BARE_REPO_PATH, 'upstream', config: 'receive.denyCurrentBranch=ignore')
      upstream.config('user.name', 'Test User')
      upstream.config('user.email', 'test@example.com')

      upstream.chdir do
        default_branch = upstream.current_branch
        upstream.branch('nondefault').checkout
        new_file('nondefault.txt', 'branch content')
        upstream.add('nondefault.txt')
        upstream.commit('add nondefault branch', allow_empty: true)
        upstream.checkout(default_branch)
      end

      local = Git.clone(upstream.dir.to_s, 'local', branch: upstream.current_branch, single_branch: true)
      fetch_refspec = "+refs/heads/#{upstream.current_branch}:refs/remotes/origin/#{upstream.current_branch}"
      local.config('remote.origin.fetch', fetch_refspec)

      assert(!local.branches.remote.map(&:full).include?('remotes/origin/nondefault'))

      local.remote_set_branches('origin', '*', add: true)
      local.fetch

      assert(local.branches.remote.map(&:full).include?('remotes/origin/nondefault'))
    end
  end

  def test_remote_set_branches_replaces_fetch_refspecs
    in_temp_dir do |_path|
      upstream = Git.clone(BARE_REPO_PATH, 'upstream', config: 'receive.denyCurrentBranch=ignore')
      upstream.config('user.name', 'Test User')
      upstream.config('user.email', 'test@example.com')

      upstream.chdir do
        default_branch = upstream.current_branch
        upstream.branch('feature/one').checkout
        new_file('feature.txt', 'feature content')
        upstream.add('feature.txt')
        upstream.commit('add feature branch', allow_empty: true)
        upstream.checkout(default_branch)
      end

      local = Git.clone(upstream.dir.to_s, 'local', branch: upstream.current_branch, single_branch: true)

      # create multiple fetch refspecs to ensure a replace operation is observable
      local.remote_set_branches('origin', upstream.current_branch, add: true)
      local.remote_set_branches('origin', 'feature/*', add: true)

      fetch_refspecs_before = local.lib.command('config', '--get-all', 'remote.origin.fetch').stdout.split("\n")
      assert(fetch_refspecs_before.size > 1)
      assert_equal(1, fetch_refspecs_before.count('+refs/heads/feature/*:refs/remotes/origin/feature/*'))

      local.remote_set_branches('origin', 'feature/*')

      fetch_refspecs_after = local.lib.command('config', '--get-all', 'remote.origin.fetch').stdout.split("\n")
      assert_equal(['+refs/heads/feature/*:refs/remotes/origin/feature/*'], fetch_refspecs_after)
    end
  end

  def test_remote_fun
    in_temp_dir do |_path|
      loc = Git.clone(BARE_REPO_PATH, 'local')
      rem = Git.clone(BARE_REPO_PATH, 'remote')

      r = loc.add_remote('testrem', rem)

      Dir.chdir('remote') do
        new_file('test-file1', 'blahblahblah1')
        rem.add
        rem.commit('master commit')

        rem.branch('testbranch').in_branch('tb commit') do
          new_file('test-file3', 'blahblahblah3')
          rem.add
          true
        end
      end
      assert(!loc.status['test-file1'])
      assert(!loc.status['test-file3'])

      r.fetch
      r.merge
      assert(loc.status['test-file1'])

      loc.merge(loc.remote('testrem').branch('testbranch'))
      assert(loc.status['test-file3'])

      # puts loc.remotes.map { |r| r.to_s }.inspect

      # r.remove
      # puts loc.remotes.inspect
    end
  end

  def test_fetch
    in_temp_dir do |_path|
      loc = Git.clone(BARE_REPO_PATH, 'local')
      rem = Git.clone(BARE_REPO_PATH, 'remote')

      r = loc.add_remote('testrem', rem)

      Dir.chdir('remote') do
        rem.branch('testbranch').in_branch('tb commit') do
          new_file('test-file', 'add file')
          rem.add
          true
        end
        rem.branch('testbranch').in_branch do
          rem.add_tag('test-tag-in-deleted-branch')
          false
        end
        rem.branch('testbranch').delete
      end

      r.fetch
      assert(!loc.tags.map(&:name).include?('test-tag-in-deleted-branch'))
      r.fetch tags: true
      assert(loc.tags.map(&:name).include?('test-tag-in-deleted-branch'))
    end
  end

  def test_fetch_cmd_with_no_args
    expected_command_line = ['fetch', '--', 'origin', { merge: true }]
    assert_command_line_eq(expected_command_line, &:fetch)
  end

  def test_fetch_cmd_with_origin_and_branch
    expected_command_line = ['fetch', '--depth', '2', '--', 'origin', 'master', { merge: true }]
    assert_command_line_eq(expected_command_line) { |git| git.fetch('origin', { ref: 'master', depth: '2' }) }
  end

  def test_fetch_cmd_with_all
    expected_command_line = ['fetch', '--all', { merge: true }]
    assert_command_line_eq(expected_command_line) { |git| git.fetch({ all: true }) }
  end

  def test_fetch_cmd_with_all_with_other_args
    expected_command_line = ['fetch', '--all', '--force', '--depth', '2', { merge: true }]
    assert_command_line_eq(expected_command_line) { |git| git.fetch({ all: true, force: true, depth: '2' }) }
  end

  def test_fetch_cmd_with_update_head_ok
    expected_command_line = ['fetch', '--update-head-ok', { merge: true }]
    assert_command_line_eq(expected_command_line) { |git| git.fetch({ 'update-head-ok': true }) }
  end

  def test_fetch_command_injection
    test_file = 'VULNERABILITY_EXISTS'
    vulnerability_exists = false
    in_temp_dir do |_path|
      git = Git.init('test_project')
      origin = "--upload-pack=touch #{test_file};"
      begin
        git.fetch(origin, { ref: 'some/ref/head' })
      rescue Git::Error
        # This is expected
      else
        raise 'Expected Git::FailedError to be raised'
      end

      vulnerability_exists = File.exist?(test_file)
    end
    assert(!vulnerability_exists)
  end

  def test_fetch_ref_adds_ref_option
    in_temp_dir do |_path|
      loc = Git.clone(BARE_REPO_PATH, 'local')
      rem = Git.clone(BARE_REPO_PATH, 'remote', config: 'receive.denyCurrentBranch=ignore')
      loc.add_remote('testrem', rem)

      first_commit_sha = second_commit_sha = nil

      rem.chdir do
        new_file('test-file1', 'gonnaCommitYou')
        rem.add
        rem.commit('master commit 1')
        commits = rem.log.execute
        first_commit_sha = commits.first.sha

        new_file('test-file2', 'gonnaCommitYouToo')
        rem.add
        rem.commit('master commit 2')
        commits = rem.log.execute
        second_commit_sha = commits.first.sha
      end

      loc.chdir do
        # Make sure fetch message only has the first commit when we fetch the first commit
        assert(loc.fetch('testrem', { ref: first_commit_sha }).include?(first_commit_sha))
        assert(!loc.fetch('testrem', { ref: first_commit_sha }).include?(second_commit_sha))

        # Make sure fetch message only has the second commit when we fetch the second commit
        assert(loc.fetch('testrem', { ref: second_commit_sha }).include?(second_commit_sha))
        assert(!loc.fetch('testrem', { ref: second_commit_sha }).include?(first_commit_sha))
      end
    end
  end

  def test_push
    in_temp_dir do |_path|
      loc = Git.clone(BARE_REPO_PATH, 'local')
      rem = Git.clone(BARE_REPO_PATH, 'remote', config: 'receive.denyCurrentBranch=ignore')

      loc.add_remote('testrem', rem)

      loc.chdir do
        new_file('test-file1', 'blahblahblah1')
        loc.add
        loc.commit('master commit')
        loc.add_tag('test-tag')

        loc.branch('testbranch').in_branch('tb commit') do
          new_file('test-file3', 'blahblahblah3')
          loc.add
          true
        end
      end
      assert(!rem.status['test-file1'])
      assert(!rem.status['test-file3'])

      loc.push('testrem', 'master')

      assert(rem.status['test-file1'])
      assert(!rem.status['test-file3'])
      error = assert_raise Git::UnexpectedResultError do
        rem.tag('test-tag')
      end

      assert_equal error.message, "Tag 'test-tag' does not exist."

      loc.push('testrem', 'testbranch', true)

      rem.checkout('testbranch')
      assert(rem.status['test-file1'])
      assert(rem.status['test-file3'])
      assert(rem.tag('test-tag'))
    end
  end

  test 'Remote#branch with no args' do
    in_temp_dir do
      Dir.mkdir 'git'
      Git.init('git', initial_branch: 'first', bare: true)
      r1 = Git.clone('git', 'r1')
      File.write('r1/file1.txt', 'hello world')
      r1.add('file1.txt')
      r1.commit('first commit')
      r1.push

      r2 = Git.clone('git', 'r2')

      File.write('r1/file2.txt', 'hello world')
      r1.add('file2.txt')
      r1.commit('second commit')
      r1.push

      branch = r2.remote('origin').branch

      assert_equal('origin/first', branch.full)
    end
  end

  test 'Remote#merge with no args' do
    in_temp_dir do
      Dir.mkdir 'git'
      Git.init('git', initial_branch: 'first', bare: true)
      r1 = Git.clone('git', 'r1')
      File.write('r1/file1.txt', 'hello world')
      r1.add('file1.txt')
      r1.commit('first commit')
      r1.push

      r2 = Git.clone('git', 'r2')

      File.write('r1/file2.txt', 'hello world')
      r1.add('file2.txt')
      r1.commit('second commit')
      r1.push

      remote = r2.remote('origin')

      remote.fetch
      remote.merge

      assert(File.exist?('r2/file2.txt'))
    end
  end
end
