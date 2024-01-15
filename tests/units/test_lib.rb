#!/usr/bin/env ruby

require 'test_helper'
require "fileutils"

# tests all the low level git communication
#
# this will be helpful if we ever figure out how
# to either build these in pure ruby or get git bindings working
# because right now it forks for every call

class TestLib < Test::Unit::TestCase
  def setup
    clone_working_repo
    @lib = Git.open(@wdir).lib
  end

  def test_fetch_unshallow
    in_temp_dir do |dir|
      git = Git.clone("file://#{@wdir}", "shallow", path: dir, depth: 1).lib
      assert_equal(1,  git.log_commits.length)
      git.fetch("file://#{@wdir}", unshallow: true)
      assert_equal(72,  git.log_commits.length)
    end
  end

  def test_commit_data
    data = @lib.commit_data('1cc8667014381')
    assert_equal('scott Chacon <schacon@agadorsparticus.corp.reactrix.com> 1194561188 -0800', data['author'])
    assert_equal('94c827875e2cadb8bc8d4cdd900f19aa9e8634c7', data['tree'])
    assert_equal("test\n", data['message'])
    assert_equal(["546bec6f8872efa41d5d97a369f669165ecda0de"], data['parent'])
  end

  def test_commit_with_date
    create_file("#{@wdir}/test_file_1", 'content tets_file_1')
    @lib.add('test_file_1')

    author_date = Time.new(2016, 8, 3, 17, 37, 0, "-03:00")

    @lib.commit('commit with date', date: author_date.strftime('%Y-%m-%dT%H:%M:%S %z'))

    data = @lib.commit_data('HEAD')

    assert_equal("Scott Chacon <schacon@gmail.com> #{author_date.strftime("%s %z")}", data['author'])
  end

  def test_commit_with_no_verify
    # Backup current pre-commit hook
    pre_commit_path = "#{@wdir}/.git/hooks/pre-commit"
    pre_commit_path_bak = "#{pre_commit_path}-bak"
    move_file(pre_commit_path, pre_commit_path_bak)

    # Adds a pre-commit file that should throw an error
    create_file(pre_commit_path, <<~PRE_COMMIT_SCRIPT)
      #!/bin/sh
      echo "pre-commit script exits with an error"
      exit 1
    PRE_COMMIT_SCRIPT

    FileUtils.chmod("+x", pre_commit_path)

    create_file("#{@wdir}/test_file_2", 'content test_file_2')
    @lib.add('test_file_2')

    # Error raised because of pre-commit hook and no use of no_verify option
    assert_raise Git::FailedError do
      @lib.commit('commit without no verify and pre-commit file')
    end

    # Error is not raised when no_verify is passed
    assert_nothing_raised do
      @lib.commit('commit with no verify and pre-commit file', no_verify: true )
    end

    # Restore pre-commit hook
    move_file(pre_commit_path_bak, pre_commit_path)

    # Verify the commit was created
    data = @lib.commit_data('HEAD')
    assert_equal("commit with no verify and pre-commit file\n", data['message'])
  end

  def test_checkout
    assert(@lib.checkout('test_checkout_b',{:new_branch=>true}))
    assert(@lib.checkout('.'))
    assert(@lib.checkout('master'))
  end

  def test_checkout_with_start_point
    assert(@lib.reset(nil, hard: true)) # to get around worktree status on windows

    expected_command_line = ["checkout", "-b", "test_checkout_b2", "master", {}]
    assert_command_line_eq(expected_command_line) do |git|
      git.checkout('test_checkout_b2', {new_branch: true, start_point: 'master'})
    end
  end

  # takes parameters, returns array of appropriate commit objects
  # :count
  # :since
  # :between
  # :object
  def test_log_commits
    a = @lib.log_commits :count => 10
    assert(a.first.is_a?(String))
    assert_equal(10, a.size)

    a = @lib.log_commits :count => 20, :since => "#{Date.today.year - 2006} years ago"
    assert(a.first.is_a?(String))
    assert_equal(20, a.size)

    a = @lib.log_commits :count => 20, :since => '1 second ago'
    assert_equal(0, a.size)

    a = @lib.log_commits :count => 20, :between => ['v2.5', 'v2.6']
    assert_equal(2, a.size)

    a = @lib.log_commits :count => 20, :path_limiter => 'ex_dir/'
    assert_equal(1, a.size)

    a = @lib.full_log_commits :count => 20
    assert_equal(20, a.size)
  end

  def test_git_ssh_from_environment_is_passed_to_binary
    saved_binary_path = Git::Base.config.binary_path
    saved_git_ssh = Git::Base.config.git_ssh

    Dir.mktmpdir do |dir|
      output_path = File.join(dir, 'git_ssh_value')
      binary_path = File.join(dir, 'my_own_git.bat') # .bat so it works in Windows too
      Git::Base.config.binary_path = binary_path
      Git::Base.config.git_ssh = 'GIT_SSH_VALUE'
      File.write(binary_path, <<~SCRIPT)
        #!/bin/sh
        set > "#{output_path}"
      SCRIPT
      FileUtils.chmod(0700, binary_path)
      @lib.checkout('something')
      env = File.read(output_path)
      assert_match(/^GIT_SSH=(["']?)GIT_SSH_VALUE\1$/, env, 'GIT_SSH should be set in the environment')
    end
  ensure
    Git::Base.config.binary_path = saved_binary_path
    Git::Base.config.git_ssh = saved_git_ssh
  end

  def test_revparse
    assert_equal('1cc8667014381e2788a94777532a788307f38d26', @lib.revparse('1cc8667014381')) # commit
    assert_equal('94c827875e2cadb8bc8d4cdd900f19aa9e8634c7', @lib.revparse('1cc8667014381^{tree}')) #tree
    assert_equal('ba492c62b6227d7f3507b4dcc6e6d5f13790eabf', @lib.revparse('v2.5:example.txt')) #blob
  end

  def test_object_type
    assert_equal('commit', @lib.object_type('1cc8667014381')) # commit
    assert_equal('tree', @lib.object_type('1cc8667014381^{tree}')) #tree
    assert_equal('blob', @lib.object_type('v2.5:example.txt')) #blob
    assert_equal('commit', @lib.object_type('v2.5'))
  end

  def test_object_size
    assert_equal(265, @lib.object_size('1cc8667014381')) # commit
    assert_equal(72, @lib.object_size('1cc8667014381^{tree}')) #tree
    assert_equal(128, @lib.object_size('v2.5:example.txt')) #blob
    assert_equal(265, @lib.object_size('v2.5'))
  end

  def test_object_contents
    commit =  "tree 94c827875e2cadb8bc8d4cdd900f19aa9e8634c7\n"
    commit << "parent 546bec6f8872efa41d5d97a369f669165ecda0de\n"
    commit << "author scott Chacon <schacon@agadorsparticus.corp.reactrix.com> 1194561188 -0800\n"
    commit << "committer scott Chacon <schacon@agadorsparticus.corp.reactrix.com> 1194561188 -0800\n"
    commit << "\ntest"
    assert_equal(commit, @lib.object_contents('1cc8667014381')) # commit

    tree =  "040000 tree 6b790ddc5eab30f18cabdd0513e8f8dac0d2d3ed\tex_dir\n"
    tree << "100644 blob 3aac4b445017a8fc07502670ec2dbf744213dd48\texample.txt"
    assert_equal(tree, @lib.object_contents('1cc8667014381^{tree}')) #tree

    blob = "1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n2"
    assert_equal(blob, @lib.object_contents('v2.5:example.txt')) #blob

  end

  def test_object_contents_with_block
    commit =  "tree 94c827875e2cadb8bc8d4cdd900f19aa9e8634c7\n"
    commit << "parent 546bec6f8872efa41d5d97a369f669165ecda0de\n"
    commit << "author scott Chacon <schacon@agadorsparticus.corp.reactrix.com> 1194561188 -0800\n"
    commit << "committer scott Chacon <schacon@agadorsparticus.corp.reactrix.com> 1194561188 -0800\n"
    commit << "\ntest"

    @lib.object_contents('1cc8667014381') do |f|
      assert_equal(commit, f.read.chomp)
    end

     # commit

    tree =  "040000 tree 6b790ddc5eab30f18cabdd0513e8f8dac0d2d3ed\tex_dir\n"
    tree << "100644 blob 3aac4b445017a8fc07502670ec2dbf744213dd48\texample.txt"

    @lib.object_contents('1cc8667014381^{tree}') do |f|
      assert_equal(tree, f.read.chomp) #tree
    end

    blob = "1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n2"

    @lib.object_contents('v2.5:example.txt') do |f|
      assert_equal(blob, f.read.chomp) #blob
    end
  end

  # returns Git::Branch object array
  def test_branches_all
    branches = @lib.branches_all
    assert(branches.size > 0)
    assert(branches.select { |b| b[1] }.size > 0)  # has a current branch
    assert(branches.select { |b| /\//.match(b[0]) }.size > 0)   # has a remote branch
    assert(branches.select { |b| !/\//.match(b[0]) }.size > 0)  # has a local branch
    assert(branches.select { |b| /master/.match(b[0]) }.size > 0)  # has a master branch
  end

  def test_config_remote
    config = @lib.config_remote('working')
    assert_equal('../working.git', config['url'])
    assert_equal('+refs/heads/*:refs/remotes/working/*', config['fetch'])
  end


  def test_ls_tree
    tree = @lib.ls_tree('94c827875e2cadb8bc8d4cdd900f19aa9e8634c7')
    assert_equal("3aac4b445017a8fc07502670ec2dbf744213dd48", tree['blob']['example.txt'][:sha])
    assert_equal("100644", tree['blob']['example.txt'][:mode])
    assert(tree['tree'])
  end

  def test_ls_remote
    in_temp_dir do |path|
      lib = Git::Lib.new
      ls = lib.ls_remote(BARE_REPO_PATH)

      assert_equal(%w( gitsearch1 v2.5 v2.6 v2.7 v2.8 ), ls['tags'].keys.sort)
      assert_equal("935badc874edd62a8629aaf103418092c73f0a56", ls['tags']['gitsearch1'][:sha])

      assert_equal(%w( git_grep master test test_branches test_object ), ls['branches'].keys.sort)
      assert_equal("5e392652a881999392c2757cf9b783c5d47b67f7", ls['branches']['master'][:sha])

      assert_equal("HEAD", ls['head'][:ref])
      assert_equal("5e392652a881999392c2757cf9b783c5d47b67f7", ls['head'][:sha])
      assert_equal(nil, ls['head'][:name])

      ls = lib.ls_remote(BARE_REPO_PATH, :refs => true)

      assert_equal({}, ls['head']) # head is not a ref
      assert_equal(%w( gitsearch1 v2.5 v2.6 v2.7 v2.8 ), ls['tags'].keys.sort)
      assert_equal(%w( git_grep master test test_branches test_object ), ls['branches'].keys.sort)
    end
  end


  # options this will accept
  #  :treeish
  #  :path_limiter
  #  :ignore_case (bool)
  #  :invert_match (bool)
  def test_grep
    match = @lib.grep('search', :object => 'gitsearch1')
    assert_equal('to search one', match['gitsearch1:scott/text.txt'].assoc(6)[1])
    assert_equal(2, match['gitsearch1:scott/text.txt'].size)
    assert_equal(2, match.size)

    match = @lib.grep('search', :object => 'gitsearch1', :path_limiter => 'scott/new*')
    assert_equal("you can't search me!", match["gitsearch1:scott/newfile"].first[1])
    assert_equal(1, match.size)

    match = @lib.grep('search', :object => 'gitsearch1', :path_limiter => ['scott/new*', 'scott/text.*'])
    assert_equal("you can't search me!", match["gitsearch1:scott/newfile"].first[1])
    assert_equal('to search one', match['gitsearch1:scott/text.txt'].assoc(6)[1])
    assert_equal(2, match['gitsearch1:scott/text.txt'].size)
    assert_equal(2, match.size)

    match = @lib.grep('SEARCH', :object => 'gitsearch1')
    assert_equal(0, match.size)

    match = @lib.grep('SEARCH', :object => 'gitsearch1', :ignore_case => true)
    assert_equal("you can't search me!", match["gitsearch1:scott/newfile"].first[1])
    assert_equal(2, match.size)

    match = @lib.grep('search', :object => 'gitsearch1', :invert_match => true)
    assert_equal(6, match['gitsearch1:scott/text.txt'].size)
    assert_equal(2, match.size)

    match = @lib.grep("you can't search me!|nothing!", :object => 'gitsearch1', :extended_regexp => true)
    assert_equal("you can't search me!", match["gitsearch1:scott/newfile"].first[1])
    assert_equal("nothing!", match["gitsearch1:scott/text.txt"].first[1])
    assert_equal(2, match.size)

    match = @lib.grep('Grep', :object => 'grep_colon_numbers')
    assert_equal("Grep regex doesn't like this:4342: because it is bad", match['grep_colon_numbers:colon_numbers.txt'].first[1])
    assert_equal(1, match.size)
  end

  def test_show
    assert_match(/^commit 46abbf07e3c564c723c7c039a43ab3a39e5d02dd.+\+Grep regex doesn't like this:4342: because it is bad\n$/m, @lib.show)
    assert(/^commit 935badc874edd62a8629aaf103418092c73f0a56.+\+nothing!$/m.match(@lib.show('gitsearch1')))
    assert(/^hello.+nothing!$/m.match(@lib.show('gitsearch1', 'scott/text.txt')))
    assert(@lib.show('gitsearch1', 'scott/text.txt') == "hello\nthis is\na file\nthat is\nput here\nto search one\nto search two\nnothing!\n")
  end

  def test_compare_version_to
    lib = Git::Lib.new(nil, nil)
    current_version = [2, 42, 0]
    lib.define_singleton_method(:current_command_version) { current_version }
    assert lib.compare_version_to(0, 43, 9) == 1
    assert lib.compare_version_to(2, 41, 0) == 1
    assert lib.compare_version_to(2, 42, 0) == 0
    assert lib.compare_version_to(2, 42, 1) == -1
    assert lib.compare_version_to(2, 43, 0) == -1
    assert lib.compare_version_to(3, 0, 0) == -1
  end
end
