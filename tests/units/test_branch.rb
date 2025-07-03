# frozen_string_literal: true

require 'test_helper'

class TestBranch < Test::Unit::TestCase
  def setup
    clone_working_repo
    @git = Git.open(@wdir)

    @commit = @git.object('1cc8667014381')
    @tree = @git.object('1cc8667014381^{tree}')
    @blob = @git.object('v2.5:example.txt')

    @branches = @git.branches
  end

  test 'Git::Lib#branch with no args should return current branch' do
    in_temp_dir do
      git = Git.init('.', initial_branch: 'my_branch')
      File.write('file.txt', 'hello world')
      git.add('file.txt')
      git.commit('Initial commit')

      b = git.branch
      assert_equal('my_branch', b.name)
    end
  end

  test 'Git::Base#branches' do
    in_temp_dir do
      remote_git = Git.init('remote_git', initial_branch: 'master')
      File.write('remote_git/file.txt', 'hello world')
      remote_git.add('file.txt')
      remote_git.commit('Initial commit')
      remote_branches = remote_git.branches
      assert_equal(1, remote_branches.size)
      assert(remote_branches.first.current)
      assert_equal('master', remote_branches.first.name)

      # Test that remote tracking branches are handled correctly
      #
      local_git = Git.clone('remote_git/.git', 'local_git')
      local_branches = assert_nothing_raised { local_git.branches }
      assert_equal(3, local_branches.size)
      assert(remote_branches.first.current)
      local_branch_refs = local_branches.map(&:full)
      assert_include(local_branch_refs, 'master')
      assert_include(local_branch_refs, 'remotes/origin/master')
      assert_include(local_branch_refs, 'remotes/origin/HEAD')
    end
  end

  test 'Git::Base#branches when checked out branch is a remote branch' do
    in_temp_dir do
      Dir.mkdir('remote_git')
      Dir.chdir('remote_git') do
        run_command 'git', 'init', '--initial-branch=main'
        File.write('file1.txt', 'This is file1')
        run_command 'git', 'add', 'file1.txt'
        run_command 'git', 'commit', '-m', 'Add file1.txt'
      end

      run_command 'git', 'clone', File.join('remote_git', '.git'), 'local_git'

      Dir.chdir('local_git') do
        run_command 'git', 'checkout', 'origin/main'
        git = Git.open('.')
        assert_nothing_raised { git.branches }
      end
    end
  end

  # Git::Lib#current_branch_state

  test 'Git::Lib#current_branch_state -- empty repository' do
    in_temp_dir do
      `git init --initial-branch=my_initial_branch`
      git = Git.open('.')
      expected_state = Git::Lib::HeadState.new(:unborn, 'my_initial_branch')
      assert_equal(expected_state, git.lib.current_branch_state)
    end
  end

  test 'Git::Lib#current_branch_state -- new orphan branch' do
    in_temp_dir do
      `git init --initial-branch=main`
      `echo "hello world" > file1.txt`
      `git add file1.txt`
      `git commit -m "First commit"`
      `git checkout --orphan orphan_branch 2> #{File::NULL}`
      git = Git.open('.')
      expected_state = Git::Lib::HeadState.new(:unborn, 'orphan_branch')
      assert_equal(expected_state, git.lib.current_branch_state)
    end
  end

  test 'Git::Lib#current_branch_state -- active branch' do
    in_temp_dir do
      `git init --initial-branch=my_branch`
      `echo "hello world" > file1.txt`
      `git add file1.txt`
      `git commit -m "First commit"`
      git = Git.open('.')
      expected_state = Git::Lib::HeadState.new(:active, 'my_branch')
      assert_equal(expected_state, git.lib.current_branch_state)
    end
  end

  test 'Git::Lib#current_branch_state -- detached HEAD' do
    in_temp_dir do
      `git init --initial-branch=main`
      `echo "hello world" > file1.txt`
      `git add file1.txt`
      `git commit -m "First commit"`
      `echo "update" > file1.txt`
      `git add file1.txt`
      `git commit -m "Second commit"`
      `git checkout HEAD~1 2> #{File::NULL}`
      git = Git.open('.')
      expected_state = Git::Lib::HeadState.new(:detached, 'HEAD')
      assert_equal(expected_state, git.lib.current_branch_state)
    end
  end

  # Git::Lib#branch_current

  test 'Git::Lib#branch_current -- active branch' do
    in_temp_dir do
      `git init --initial-branch=main`
      `echo "hello world" > file1.txt`
      `git add file1.txt`
      `git commit -m "First commit"`
      git = Git.open('.')
      assert_equal('main', git.lib.branch_current)
    end
  end

  test 'Git::Lib#branch_current -- unborn branch' do
    in_temp_dir do
      `git init --initial-branch=new_branch`
      git = Git.open('.')
      assert_equal('new_branch', git.lib.branch_current)
    end
  end

  test 'Git::Lib#branch_current -- detached HEAD' do
    in_temp_dir do
      `git init --initial-branch=main`
      `echo "hello world" > file1.txt`
      `git add file1.txt`
      `git commit -m "First commit"`
      `echo "update" > file1.txt`
      `git add file1.txt`
      `git commit -m "Second commit"`
      `git checkout HEAD~1 2> #{File::NULL}`
      git = Git.open('.')
      assert_equal('HEAD', git.lib.branch_current)
    end
  end

  # Git::Base#branch

  test 'Git::Base#branch with detached head' do
    in_temp_dir do
      `git init`
      `echo "hello world" > file1.txt`
      `git add file1.txt`
      `git commit -m "Initial commit"`
      `echo "hello to another world" > file2.txt`
      `git add file2.txt`
      `git commit -m "Add another world"`
      `git checkout HEAD~1 2> #{File::NULL}`

      git = Git.open('.')
      branch = git.branch

      assert_equal('HEAD', branch.name)
    end
  end

  # Git::Base#branchs

  test 'Git::Base#branchs with detached head' do
    in_temp_dir do
      git = Git.init('.', initial_branch: 'master')
      File.write('file1.txt', 'hello world')
      git.add('file1.txt')
      git.commit('Initial commit')
      git.add_tag('v1.0.0')
      File.write('file2.txt', 'hello world')
      git.add('file2.txt')
      git.commit('Second commit')

      # This will put us in a detached head state
      git.checkout('v1.0.0')

      branches = assert_nothing_raised { git.branches }
      assert_equal(1, branches.size)
      assert_equal('master', branches.first.name)
    end
  end

  def test_branches_local
    bs = @git.branches.local
    assert(bs.size > 4)
  end

  def test_branches_remote
    bs = @git.branches.remote
    assert_equal(1, bs.size)
  end

  def test_branches_single
    branch = @git.branches[:test_object]
    assert_equal('test_object', branch.name)

    %w[working/master remotes/working/master].each do |branch_name|
      branch = @git.branches[branch_name]

      assert_equal('master', branch.name)
      assert_equal('remotes/working/master', branch.full)
      assert_equal('working', branch.remote.name)
      assert_equal('+refs/heads/*:refs/remotes/working/*', branch.remote.fetch_opts)
      assert_equal('../working.git', branch.remote.url)
    end
  end

  def test_true_branch_contains?
    assert(@git.branch('git_grep').contains?('master'))
  end

  def test_false_branch_contains?
    assert(!@git.branch('master').contains?('git_grep'))
  end

  def test_branch_commit
    assert_equal(270, @git.branches[:test_branches].gcommit.size)
  end

  def test_branch_create_and_switch
    in_bare_repo_clone do |git|
      assert(!git.branch('new_branch').current)
      git.branch('other_branch').create
      assert(!git.branch('other_branch').current)
      git.branch('new_branch').checkout
      assert(git.branch('new_branch').current)

      assert_equal(1, git.branches.select { |b| b.name == 'new_branch' }.size)

      new_file('test-file1', 'blahblahblah1')
      new_file('test-file2', 'blahblahblah2')
      new_file('.test-dot-file1', 'blahblahblahdot1')
      assert(git.status.untracked.assoc('test-file1'))
      assert(git.status.untracked.assoc('.test-dot-file1'))

      git.add(%w[test-file1 test-file2])
      assert(!git.status.untracked.assoc('test-file1'))

      git.reset
      assert(git.status.untracked.assoc('test-file1'))
      assert(!git.status.added.assoc('test-file1'))

      assert_raise Git::FailedError do
        git.branch('new_branch').delete
      end
      assert_equal(1, git.branches.select { |b| b.name == 'new_branch' }.size)

      git.branch('master').checkout
      git.branch('new_branch').delete
      assert_equal(0, git.branches.select { |b| b.name == 'new_branch' }.size)

      git.checkout('other_branch')
      assert(git.branch('other_branch').current)

      git.checkout('master')
      assert(!git.branch('other_branch').current)

      git.checkout(@git.branch('other_branch'))
      assert(git.branch('other_branch').current)
    end
  end

  def test_branch_update_ref
    in_temp_dir do |_path|
      git = Git.init
      File.write('foo', 'rev 1')
      git.add('foo')
      git.commit('rev 1')
      git.branch('testing').create
      File.write('foo', 'rev 2')
      git.add('foo')
      git.commit('rev 2')
      git.branch('testing').update_ref(git.rev_parse('HEAD'))

      # Expect the call to Branch#update_ref to pass the full ref name for the
      # of the testing branch to Lib#update_ref
      assert_equal(git.rev_parse('HEAD'), git.rev_parse('refs/heads/testing'))
    end
  end
end
