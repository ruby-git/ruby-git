<!--
# @markup markdown
# @title README
-->

# The Git Gem

[![Gem Version](https://badge.fury.io/rb/git.svg)](https://badge.fury.io/rb/git)
[![Documentation](https://img.shields.io/badge/Documentation-Latest-green)](https://rubydoc.info/gems/git/)
[![Change Log](https://img.shields.io/badge/CHANGELOG-Latest-green)](https://rubydoc.info/gems/git/file/CHANGELOG.md)
[![Build Status](https://github.com/ruby-git/ruby-git/workflows/CI/badge.svg?branch=master)](https://github.com/ruby-git/ruby-git/actions?query=workflow%3ACI)
[![Code Climate](https://codeclimate.com/github/ruby-git/ruby-git.png)](https://codeclimate.com/github/ruby-git/ruby-git)

* [Summary](#summary)
* [v2.x Release](#v2x-release)
* [Install](#install)
* [Major Objects](#major-objects)
* [Errors Raised By This Gem](#errors-raised-by-this-gem)
* [Specifying And Handling Timeouts](#specifying-and-handling-timeouts)
* [Examples](#examples)
* [Ruby version support policy](#ruby-version-support-policy)
* [License](#license)

## Summary

The [git gem](https://rubygems.org/gems/git) provides a Ruby interface to the `git`
command line.

Get started by obtaining a repository object by:

* opening an existing working copy with [Git.open](https://rubydoc.info/gems/git/Git#open-class_method)
* initializing a new repository with [Git.init](https://rubydoc.info/gems/git/Git#init-class_method)
* cloning a repository with [Git.clone](https://rubydoc.info/gems/git/Git#clone-class_method)

Methods that can be called on a repository object are documented in [Git::Base](https://rubydoc.info/gems/git/Git/Base)

## v2.x Release

git 2.0.0 has recently been released. Please give it a try.

**If you have problems with the 2.x release, open an issue and use the 1.x version
instead.** We will do our best to fix your issues in a timely fashion.

**JRuby on Windows is not yet supported by the 2.x release line. Users running JRuby
on Windows should continue to use the 1.x release line.**

The changes in this major release include:

* Added a dependency on the activesupport gem to use the deprecation functionality
* Create a policy of supported Ruby versions to support only non-EOL Ruby versions
* Create a policy of supported Git CLI versions (released 2020-12-25)
* Update the required Ruby version to at least 3.0 (released 2020-07-27)
* Update the required Git command line version to at least 2.28
* Update how CLI commands are called to use the [process_executer](https://github.com/main-branch/process_executer)
  gem which is built on top of [Kernel.spawn](https://ruby-doc.org/3.3.0/Kernel.html#method-i-spawn).
  See [PR #684](https://github.com/ruby-git/ruby-git/pull/684) for more details
  on the motivation for this implementation.

The `master` branch will be used for `2.x` development. If needed, fixes for `1.x`
version will be done on the `v1` branch.

## Install

Install the gem and add to the application's Gemfile by executing:

```shell
bundle add git
```

to install version 1.x:

```shell
bundle add git --version "~> 1.19"
```

If bundler is not being used to manage dependencies, install the gem by executing:

```shell
gem install git
```

to install version 1.x:

```shell
gem install git --version "~> 1.19"
```

## Major Objects

**Git::Base** - The object returned from a `Git.open` or `Git.clone`. Most major actions are called from this object.

**Git::Object** - The base object for your tree, blob and commit objects, returned from `@git.gtree` or `@git.object` calls.  the `Git::AbstractObject` will have most of the calls in common for all those objects.

**Git::Diff** - returns from a `@git.diff` command.  It is an Enumerable that returns `Git::Diff:DiffFile` objects from which you can get per file patches and insertion/deletion statistics.  You can also get total statistics from the Git::Diff object directly.

**Git::Status** - returns from a `@git.status` command.  It is an Enumerable that returns
`Git:Status::StatusFile` objects for each object in git, which includes files in the working
directory, in the index and in the repository.  Similar to running 'git status' on the command line to determine untracked and changed files.

**Git::Branches** - Enumerable object that holds `Git::Branch objects`.  You can call .local or .remote on it to filter to just your local or remote branches.

**Git::Remote**- A reference to a remote repository that is tracked by this repository.

**Git::Log** - An Enumerable object that references all the `Git::Object::Commit`
objects that encompass your log query, which can be constructed through methods on
the `Git::Log object`, like:

```ruby
git.log
  .max_count(:all)
  .object('README.md')
  .since('10 years ago')
  .between('v1.0.7', 'HEAD')
  .map { |commit| commit.sha }
```

A maximum of 30 commits are returned if `max_count` is not called. To get all commits
that match the log query, call `max_count(:all)`.

Note that `git.log.all` adds the `--all` option to the underlying `git log` command.
This asks for the logs of all refs (basically all commits reachable by HEAD,
branches, and tags). This does not control the maximum number of commits returned. To
control how many commits are returned, you should call `max_count`.

**Git::Worktrees** - Enumerable object that holds `Git::Worktree objects`.

## Errors Raised By This Gem

The git gem will only raise an `ArgumentError` or an error that is a subclass of
`Git::Error`. It does not explicitly raise any other types of errors.

It is recommended to rescue `Git::Error` to catch any runtime error raised by
this gem unless you need more specific error handling.

```ruby
begin
  # some git operation
rescue Git::Error => e
  puts "An error occurred: #{e.message}"
end
```

See [`Git::Error`](https://rubydoc.info/gems/git/Git/Error) for more information.

## Specifying And Handling Timeouts

The timeout feature was added in git gem version `2.0.0`.

A timeout for git command line operations can be set either globally or for specific
method calls that accept a `:timeout` parameter.

The timeout value must be a real, non-negative `Numeric` value that specifies a
number of seconds a `git` command will be given to complete before being sent a KILL
signal. This library may hang if the `git` command does not terminate after receiving
the KILL signal.

When a command times out, it is killed by sending it the `SIGKILL` signal and a
`Git::TimeoutError` is raised. This error derives from the `Git::SignaledError` and
`Git::Error`.

If the timeout value is `0` or `nil`, no timeout will be enforced.

If a method accepts a `:timeout` parameter and a receives a non-nil value, the value
of this parameter will override the global timeout value. In this context, a value of
`nil` (which is usually the default) will use the global timeout value and a value of
`0` will turn off timeout enforcement for that method call no matter what the global
value is.

To set a global timeout, use the `Git.config` object:

```ruby
Git.config.timeout = nil # a value of nil or 0 means no timeout is enforced
Git.config.timeout = 1.5 # can be any real, non-negative Numeric interpreted as number of seconds
```

The global timeout can be overridden for a specific method if the method accepts a
`:timeout` parameter:

```ruby
repo_url = 'https://github.com/ruby-git/ruby-git.git'
Git.clone(repo_url) # Use the global timeout value
Git.clone(repo_url, timeout: nil) # Also uses the global timeout value
Git.clone(repo_url, timeout: 0) # Do not enforce a timeout
Git.clone(repo_url, timeout: 10.5)  # Timeout after 10.5 seconds raising Git::SignaledError
```

If the command takes too long, a `Git::TimeoutError` will be raised:

```ruby
begin
  Git.clone(repo_url, timeout: 10)
rescue Git::TimeoutError => e
  e.result.tap do |r|
    r.class #=> Git::CommandLineResult
    r.status #=> #<Process::Status: pid 62173 SIGKILL (signal 9)>
    r.status.timeout? #=> true
    r.git_cmd # The git command ran as an array of strings
    r.stdout # The command's output to stdout until it was terminated
    r.stderr # The command's output to stderr until it was terminated
  end
end
```

## Examples

Here are a bunch of examples of how to use the Ruby/Git package.

Require the 'git' gem.

```ruby
require 'git'
```

Git env config

```ruby
Git.configure do |config|
  # If you want to use a custom git binary
  config.binary_path = '/git/bin/path'

  # If you need to use a custom SSH script
  config.git_ssh = '/path/to/ssh/script'
end
```

_NOTE: Another way to specify where is the `git` binary is through the environment variable `GIT_PATH`_

Here are the operations that need read permission only.

```ruby
g = Git.open(working_dir, :log => Logger.new(STDOUT))

g.index
g.index.readable?
g.index.writable?
g.repo
g.dir

# ls-tree with recursion into subtrees (list files)
g.ls_tree("HEAD", recursive: true)

# log - returns a Git::Log object, which is an Enumerator of Git::Commit objects
# default configuration returns a max of 30 commits
g.log
g.log(200) # 200 most recent commits
g.log.since('2 weeks ago') # default count of commits since 2 weeks ago.
g.log(200).since('2 weeks ago') # commits since 2 weeks ago, limited to 200.
g.log.between('v2.5', 'v2.6')
g.log.each {|l| puts l.sha }
g.gblob('v2.5:Makefile').log.since('2 weeks ago')

g.object('HEAD^').to_s  # git show / git rev-parse
g.object('HEAD^').contents
g.object('v2.5:Makefile').size
g.object('v2.5:Makefile').sha

g.gtree(treeish)
g.gblob(treeish)
g.gcommit(treeish)


commit = g.gcommit('1cc8667014381')

commit.gtree
commit.parent.sha
commit.parents.size
commit.author.name
commit.author.email
commit.author.date.strftime("%m-%d-%y")
commit.committer.name
commit.date.strftime("%m-%d-%y")
commit.message

tree = g.gtree("HEAD^{tree}")

tree.blobs
tree.subtrees
tree.children # blobs and subtrees

g.rev_parse('v2.0.0:README.md')

g.branches # returns Git::Branch objects
g.branches.local
g.current_branch
g.branches.remote
g.branches[:master].gcommit
g.branches['origin/master'].gcommit

g.grep('hello')  # implies HEAD
g.blob('v2.5:Makefile').grep('hello')
g.tag('v2.5').grep('hello', 'docs/')
g.describe()
g.describe('0djf2aa')
g.describe('HEAD', {:all => true, :tags => true})

g.diff(commit1, commit2).size
g.diff(commit1, commit2).stats
g.diff(commit1, commit2).name_status
g.gtree('v2.5').diff('v2.6').insertions
g.diff('gitsearch1', 'v2.5').path('lib/')
g.diff('gitsearch1', @git.gtree('v2.5'))
g.diff('gitsearch1', 'v2.5').path('docs/').patch
g.gtree('v2.5').diff('v2.6').patch

g.gtree('v2.5').diff('v2.6').each do |file_diff|
  puts file_diff.path
  puts file_diff.patch
  puts file_diff.blob(:src).contents
end

g.worktrees # returns Git::Worktree objects
g.worktrees.count
g.worktrees.each do |worktree|
  worktree.dir
  worktree.gcommit
  worktree.to_s
end

g.config('user.name')  # returns 'Scott Chacon'
g.config # returns whole config hash

# Configuration can be set when cloning using the :config option.
# This option can be an single configuration String or an Array
# if multiple config items need to be set.
#
g = Git.clone(
  git_uri, destination_path,
  :config => [
    'core.sshCommand=ssh -i /home/user/.ssh/id_rsa',
    'submodule.recurse=true'
  ]
)

g.tags # returns array of Git::Tag objects

g.show()
g.show('HEAD')
g.show('v2.8', 'README.md')

Git.ls_remote('https://github.com/ruby-git/ruby-git.git') # returns a hash containing the available references of the repo.
Git.ls_remote('/path/to/local/repo')
Git.ls_remote() # same as Git.ls_remote('.')

Git.default_branch('https://github.com/ruby-git/ruby-git') #=> 'master'
```

And here are the operations that will need to write to your git repository.

```ruby
g = Git.init
  Git.init('project')
  Git.init('/home/schacon/proj',
  { :repository => '/opt/git/proj.git',
      :index => '/tmp/index'} )

# Clone from a git url
git_url = 'https://github.com/ruby-git/ruby-git.git'
# Clone into the ruby-git directory
g = Git.clone(git_url)

# Clone into /tmp/clone/ruby-git-clean
name = 'ruby-git-clean'
path = '/tmp/clone'
g = Git.clone(git_url, name, :path => path)
g.dir #=> /tmp/clone/ruby-git-clean

g.config('user.name', 'Scott Chacon')
g.config('user.email', 'email@email.com')

# Clone can take a filter to tell the serve to send a partial clone
g = Git.clone(git_url, name, :path => path, :filter => 'tree:0')

# Clone can take an optional logger
logger = Logger.new
g = Git.clone(git_url, NAME, :log => logger)

g.add                                   # git add -- "."
g.add(:all=>true)                       # git add --all -- "."
g.add('file_path')                      # git add -- "file_path"
g.add(['file_path_1', 'file_path_2'])   # git add -- "file_path_1" "file_path_2"

g.remove()                                # git rm -f -- "."
g.remove('file.txt')                      # git rm -f -- "file.txt"
g.remove(['file.txt', 'file2.txt'])       # git rm -f -- "file.txt" "file2.txt"
g.remove('file.txt', :recursive => true)  # git rm -f -r -- "file.txt"
g.remove('file.txt', :cached => true)     # git rm -f --cached -- "file.txt"

g.commit('message')
g.commit_all('message')

# Sign a commit using the gpg key configured in the user.signingkey config setting
g.config('user.signingkey', '0A46826A')
g.commit('message', gpg_sign: true)

# Sign a commit using a specified gpg key
key_id = '0A46826A'
g.commit('message', gpg_sign: key_id)

# Skip signing a commit (overriding any global gpgsign setting)
g.commit('message', no_gpg_sign: true)

g = Git.clone(repo, 'myrepo')
g.chdir do
new_file('test-file', 'blahblahblah')
g.status.changed.each do |file|
  puts file.blob(:index).contents
end
end

g.reset # defaults to HEAD
g.reset_hard(Git::Commit)

g.branch('new_branch') # creates new or fetches existing
g.branch('new_branch').checkout
g.branch('new_branch').delete
g.branch('existing_branch').checkout
g.branch('master').contains?('existing_branch')

# delete remote branch
g.push('origin', 'remote_branch_name', force: true, delete: true)

g.checkout('new_branch')
g.checkout('new_branch', new_branch: true, start_point: 'master')
g.checkout(g.branch('new_branch'))

g.branch(name).merge(branch2)
g.branch(branch2).merge  # merges HEAD with branch2

g.branch(name).in_branch(message) { # add files }  # auto-commits
g.merge('new_branch')
g.merge('new_branch', 'merge commit message', no_ff: true)
g.merge('origin/remote_branch')
g.merge(g.branch('master'))
g.merge([branch1, branch2])

g.merge_base('branch1', 'branch2')

r = g.add_remote(name, uri)  # Git::Remote
r = g.add_remote(name, Git::Base)  # Git::Remote

g.remotes  # array of Git::Remotes
g.remote(name).fetch
g.remote(name).remove
g.remote(name).merge
g.remote(name).merge(branch)

g.fetch
g.fetch(g.remotes.first)
g.fetch('origin', {:ref => 'some/ref/head'} )
g.fetch(all: true, force: true, depth: 2)
g.fetch('origin', {:'update-head-ok' => true})

g.pull
g.pull(Git::Repo, Git::Branch) # fetch and a merge

g.add_tag('tag_name') # returns Git::Tag
g.add_tag('tag_name', 'object_reference')
g.add_tag('tag_name', 'object_reference', {:options => 'here'})
g.add_tag('tag_name', {:options => 'here'})

Options:
  :a | :annotate
  :d
  :f
  :m | :message
  :s

g.delete_tag('tag_name')

g.repack

g.push
g.push(g.remote('name'))

# delete remote branch
g.push('origin', 'remote_branch_name', force: true, delete: true)

# push all branches to remote at one time
g.push('origin', all: true)

g.worktree('/tmp/new_worktree').add
g.worktree('/tmp/new_worktree', 'branch1').add
g.worktree('/tmp/new_worktree').remove
g.worktrees.prune
```

Some examples of more low-level index and tree operations

```ruby
g.with_temp_index do

  g.read_tree(tree3) # calls self.index.read_tree
  g.read_tree(tree1, :prefix => 'hi/')

  c = g.commit_tree('message')
  # or #
  t = g.write_tree
  c = g.commit_tree(t, :message => 'message', :parents => [sha1, sha2])

  g.branch('branch_name').update_ref(c)
  g.update_ref(branch, c)

  g.with_temp_working do # new blank working directory
    g.checkout
    g.checkout(another_index)
    g.commit # commits to temp_index
  end
end

g.set_index('/path/to/index')


g.with_index(path) do
  # calls set_index, then switches back after
end

g.with_working(dir) do
# calls set_working, then switches back after
end

g.with_temp_working(dir) do
  g.checkout_index(:prefix => dir, :path_limiter => path)
  # do file work
  g.commit # commits to index
end
```

## Ruby version support policy

This gem will be expected to function correctly on:

* All non-EOL versions of the MRI Ruby on Mac, Linux, and Windows
* The latest version of JRuby on Linux
* The latest version of Truffle Ruby on Linus

It is this project's intent to support the latest version of JRuby on Windows
once the following JRuby bug is fixed:

jruby/jruby#7515

## License

Licensed under MIT License Copyright (c) 2008  Scott Chacon. See LICENSE for further
details.
