#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../test_helper'

# tests all the low level git communication
#
# this will be helpful if we ever figure out how
# to either build these in pure ruby or get git bindings working
# because right now it forks for every call

class TestLib < Test::Unit::TestCase
  def setup
    set_file_paths
    @lib = Git.open(@wdir).lib
  end

  def test_fetch_unshallow
    in_temp_dir do |dir|
      git = Git.clone("file://#{@wdir}", "shallow", path: dir, depth: 1).lib
      assert_equal(1,  git.log_commits.length)
      git.fetch("file://#{@wdir}", unshallow: true)
      assert_equal(71,  git.log_commits.length)
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

  def test_checkout
    assert(@lib.checkout('test_checkout_b',{:new_branch=>true}))
    assert(@lib.checkout('master'))
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

  def test_environment_reset
    ENV['GIT_DIR'] = '/my/git/dir'
    ENV['GIT_WORK_TREE'] = '/my/work/tree'
    ENV['GIT_INDEX_FILE'] = 'my_index'

    @lib.log_commits :count => 10

    assert_equal(ENV['GIT_DIR'], '/my/git/dir')
    assert_equal(ENV['GIT_WORK_TREE'], '/my/work/tree')
    assert_equal(ENV['GIT_INDEX_FILE'],'my_index')
  end

  def test_git_ssh_from_environment_is_passed_to_binary
    ENV['GIT_SSH'] = 'my/git-ssh-wrapper'

    Dir.mktmpdir do |dir|
      output_path = File.join(dir, 'git_ssh_value')
      binary_path = File.join(dir, 'git')
      Git::Base.config.binary_path = binary_path
      File.open(binary_path, 'w') { |f|
        f << "echo $GIT_SSH > #{output_path}"
      }
      FileUtils.chmod(0700, binary_path)
      @lib.checkout('something')
      assert_equal("my/git-ssh-wrapper\n", File.read(output_path))
    end
  ensure
    Git.configure do |config|
      config.binary_path = nil
      config.git_ssh = nil
    end

    ENV['GIT_SSH'] = nil
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
      ls = lib.ls_remote(@wbare)

      assert_equal(%w( gitsearch1 v2.5 v2.6 v2.7 v2.8 ), ls['tags'].keys.sort)
      assert_equal("935badc874edd62a8629aaf103418092c73f0a56", ls['tags']['gitsearch1'][:sha])

      assert_equal(%w( git_grep master test test_branches test_object ), ls['branches'].keys.sort)
      assert_equal("5e392652a881999392c2757cf9b783c5d47b67f7", ls['branches']['master'][:sha])

      assert_equal("HEAD", ls['head'][:ref])
      assert_equal("5e392652a881999392c2757cf9b783c5d47b67f7", ls['head'][:sha])
      assert_equal(nil, ls['head'][:name])
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

    match = @lib.grep('SEARCH', :object => 'gitsearch1')
    assert_equal(0, match.size)

    match = @lib.grep('SEARCH', :object => 'gitsearch1', :ignore_case => true)
    assert_equal("you can't search me!", match["gitsearch1:scott/newfile"].first[1])
    assert_equal(2, match.size)

    match = @lib.grep('search', :object => 'gitsearch1', :invert_match => true)
    assert_equal(6, match['gitsearch1:scott/text.txt'].size)
    assert_equal(2, match.size)
  end

  def test_show
    assert(/^commit 5e53019b3238362144c2766f02a2c00d91fcc023.+\+replace with new text - diff test$/m.match(@lib.show))
    assert(/^commit 935badc874edd62a8629aaf103418092c73f0a56.+\+nothing!$/m.match(@lib.show('gitsearch1')))
    assert(/^hello.+nothing!$/m.match(@lib.show('gitsearch1', 'scott/text.txt')))
  end

end
