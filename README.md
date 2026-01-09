<!--
# @markup markdown
# @title README
-->

# The Git Gem

[![Gem Version](https://badge.fury.io/rb/git.svg)](https://badge.fury.io/rb/git)
[![Documentation](https://img.shields.io/badge/Documentation-Latest-green)](https://rubydoc.info/gems/git/)
[![Change
Log](https://img.shields.io/badge/CHANGELOG-Latest-green)](https://rubydoc.info/gems/git/file/CHANGELOG.md)
[![Build
Status](https://github.com/ruby-git/ruby-git/workflows/CI/badge.svg?branch=main)](https://github.com/ruby-git/ruby-git/actions?query=workflow%3ACI)
[![Conventional
Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-%23FE5196?logo=conventionalcommits&logoColor=white)](https://conventionalcommits.org)
[![AI Policy](https://img.shields.io/badge/AI%20Policy-Required-blue)](AI_POLICY.md)

- [Summary](#summary)
- [Install](#install)
- [Quick Start](#quick-start)
- [Examples](#examples)
  - [Configuration](#configuration)
  - [Read Operations](#read-operations)
  - [Write Operations](#write-operations)
  - [Index and Tree Operations](#index-and-tree-operations)
- [Errors Raised By This Gem](#errors-raised-by-this-gem)
- [Specifying And Handling Timeouts](#specifying-and-handling-timeouts)
- [Deprecations](#deprecations)
- [Project Policies](#project-policies)
  - [Ruby Version Support Policy](#ruby-version-support-policy)
  - [Git Version Support Policy](#git-version-support-policy)
- [📢 Project Announcements 📢](#-project-announcements-)
  - [2026-01-07: AI Policy Introduced](#2026-01-07-ai-policy-introduced)
  - [2025-07-09: Architectural Redesign](#2025-07-09-architectural-redesign)
  - [2025-07-07: We Now Use RuboCop](#2025-07-07-we-now-use-rubocop)
  - [2025-06-06: Default Branch Rename](#2025-06-06-default-branch-rename)
  - [2025-05-15: We've Switched to Conventional Commits](#2025-05-15-weve-switched-to-conventional-commits)

## Summary

The [git gem](https://rubygems.org/gems/git) provides a Ruby interface to the `git`
command line.

Get started by obtaining a repository object by:

- opening an existing working copy with
  [Git.open](https://rubydoc.info/gems/git/Git#open-class_method)
- initializing a new repository with
  [Git.init](https://rubydoc.info/gems/git/Git#init-class_method)
- cloning a repository with
  [Git.clone](https://rubydoc.info/gems/git/Git#clone-class_method)

Methods that can be called on a repository object are documented in
[Git::Base](https://rubydoc.info/gems/git/Git/Base)

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

## Quick Start

All functionality for this gem starts with the top-level
[`Git`](https://rubydoc.info/gems/git/Git) module. This module can be used to run
non-repo scoped `git` commands such as `config`.

The `Git` module also has factory methods such as `open`, `clone`, and `init` which
return a [`Git::Base`](https://rubydoc.info/gems/git/Git/Base) object. The
`Git::Base` object is used to run repo-specific `git` commands such as `add`,
`commit`, `push`, and `log`.

Clone, read status, and log:

```ruby
require 'git'

repo = Git.clone('https://github.com/ruby-git/ruby-git.git', 'ruby-git')
repo.status.changed.each { |f| puts "changed: #{f.path}" }
repo.log(5).each { |c| puts c.message }
```

Open an existing repo and commit:

```ruby
require 'git'

repo = Git.open('/path/to/repo')
repo.add(all: true)
repo.commit('chore: update files')
repo.push
```

Initialize a new repo and make the first commit:

```ruby
require 'git'

repo = Git.init('my_project')
repo.add(all: true)
repo.commit('initial commit')
```

## Examples

Beyond the basics covered in Quick Start, these examples show the full range of
options and variations for each operation.

### Configuration

Configure the `git` command line:

```ruby
# Global config (in ~/.gitconfig)
settings = Git.global_config # returns a Hash
username = Git.global_config('user.email')
Git.global_config('user.email', 'user@example.com')

# Repository config
repo = Git.open('path/to/repo')
settings = repo.config # returns a Hash
username = repo.config('user.email')
repo.config('user.email', 'anotheruser@example.com')
```

Configure the git gem:

```ruby
Git.configure do |config|
  config.binary_path = '/usr/local/bin/git'
  config.git_ssh = 'ssh -i ~/.ssh/id_rsa'
end

# or

Git.config.binary_path = '/usr/local/bin/git'
Git.config.git_ssh = 'ssh -i ~/.ssh/id_rsa'
```

**How SSH configuration is determined:**

- If `git_ssh` is not specified in the API call, the global config (`Git.configure {
  |c| c.git_ssh = ... }`) is used.
- If `git_ssh: nil` is specified, SSH is disabled for that instance (no SSH key or
  script will be used).
- If `git_ssh` is a non-empty string, it is used for that instance (overriding the
  global config).

You can also specify a custom SSH script on a per-repository basis:

```ruby
# Use a specific SSH key for a single repository
git = Git.open('/path/to/repo', git_ssh: 'ssh -i /path/to/private_key')

# Or when cloning
git = Git.clone('git@github.com:user/repo.git', 'local-dir',
                git_ssh: 'ssh -i /path/to/private_key')

# Or when initializing
git = Git.init('new-repo', git_ssh: 'ssh -i /path/to/private_key')
```

This is especially useful in multi-threaded applications where different repositories
require different SSH credentials.

### Read Operations

Here are the operations that need read permission only:

```ruby
repo = Git.open(working_dir, :log => Logger.new(STDOUT))

repo.index
repo.index.readable?
repo.index.writable?
repo.repo
repo.dir

# ls-tree with recursion into subtrees (list files)
repo.ls_tree("HEAD", recursive: true)

# log - returns a Git::Log object, which is an Enumerator of Git::Commit objects
# default configuration returns a max of 30 commits
repo.log
repo.log(200) # 200 most recent commits
repo.log.since('2 weeks ago') # default count of commits since 2 weeks ago.
repo.log(200).since('2 weeks ago') # commits since 2 weeks ago, limited to 200.
repo.log.between('v2.5', 'v2.6')
repo.log.each {|l| puts l.sha }
repo.gblob('v2.5:Makefile').log.since('2 weeks ago')

repo.object('HEAD^').to_s  # git show / git rev-parse
repo.object('HEAD^').contents
repo.object('v2.5:Makefile').size
repo.object('v2.5:Makefile').sha

repo.gtree(treeish)
repo.gblob(treeish)
repo.gcommit(treeish)


commit = repo.gcommit('1cc8667014381')

commit.gtree
commit.parent.sha
commit.parents.size
commit.author.name
commit.author.email
commit.author.date.strftime("%m-%d-%y")
commit.committer.name
commit.date.strftime("%m-%d-%y")
commit.message

tree = repo.gtree("HEAD^{tree}")

tree.blobs
tree.subtrees
tree.children # blobs and subtrees

repo.rev_parse('v2.0.0:README.md')

repo.branches # returns Git::Branch objects
repo.branches.local
repo.current_branch
repo.branches.remote
repo.branches[:main].gcommit
repo.branches['origin/main'].gcommit

repo.grep('hello')  # implies HEAD
repo.blob('v2.5:Makefile').grep('hello')
repo.tag('v2.5').grep('hello', 'docs/')
repo.describe()
repo.describe('0djf2aa')
repo.describe('HEAD', {:all => true, :tags => true})

repo.diff(commit1, commit2).size
repo.diff(commit1, commit2).stats
repo.diff(commit1, commit2).name_status
repo.gtree('v2.5').diff('v2.6').insertions
repo.diff('gitsearch1', 'v2.5').path('lib/')
repo.diff('gitsearch1', 'v2.5').path('lib/', 'docs/', 'README.md')  # multiple paths
repo.diff('gitsearch1', repo.gtree('v2.5'))
repo.diff('gitsearch1', 'v2.5').path('docs/').patch
repo.gtree('v2.5').diff('v2.6').patch

repo.gtree('v2.5').diff('v2.6').each do |file_diff|
  puts file_diff.path
  puts file_diff.patch
  puts file_diff.blob(:src).contents
end

repo.worktrees # returns Git::Worktree objects
repo.worktrees.count
repo.worktrees.each do |worktree|
  worktree.dir
  worktree.gcommit
  worktree.to_s
end

repo.config('user.name')  # returns 'Scott Chacon'
repo.config # returns whole config hash

# Configuration can be set when cloning using the :config option.
# This option can be an single configuration String or an Array
# if multiple config items need to be set.
#
repo = Git.clone(
  git_uri, destination_path,
  :config => [
    'core.sshCommand=ssh -i /home/user/.ssh/id_rsa',
    'submodule.recurse=true'
  ]
)

repo.tags # returns array of Git::Tag objects

repo.show()
repo.show('HEAD')
repo.show('v2.8', 'README.md')

Git.ls_remote('https://github.com/ruby-git/ruby-git.git') # returns a hash containing the available references of the repo.
Git.ls_remote('/path/to/local/repo')
Git.ls_remote() # same as Git.ls_remote('.')

Git.default_branch('https://github.com/ruby-git/ruby-git') #=> 'main'
```

### Write Operations

And here are the operations that will need to write to your git repository.

```ruby
repo = Git.init # default is the current directory
repo = Git.init('project')
repo = Git.init(
  '/home/schacon/proj',
  { :repository => '/opt/git/proj.git', :index => '/tmp/index'}
)

# Clone from a git url
git_url = 'https://github.com/ruby-git/ruby-git.git'
repo = Git.clone(git_url)

# Clone into /tmp/clone/ruby-git-clean
name = 'ruby-git-clean'
path = '/tmp/clone'
repo = Git.clone(git_url, name, :path => path)
repo.dir #=> /tmp/clone/ruby-git-clean

repo.config('user.name', 'Scott Chacon')
repo.config('user.email', 'email@email.com')

# Clone can take a filter to tell the serve to send a partial clone
repo = Git.clone(git_url, name, :path => path, :filter => 'tree:0')

# Clone can control single-branch behavior (nil default keeps current git behavior)
repo = Git.clone(git_url, name, :path => path, :depth => 1, :single_branch => false)

# Clone can take an optional logger
logger = Logger.new(STDOUT)
repo = Git.clone(git_url, 'my-repo', :log => logger)

repo.add                                   # git add -- "."
repo.add(:all=>true)                       # git add --all -- "."
repo.add('file_path')                      # git add -- "file_path"
repo.add(['file_path_1', 'file_path_2'])   # git add -- "file_path_1" "file_path_2"

repo.remove()                                # git rm -f -- "."
repo.remove('file.txt')                      # git rm -f -- "file.txt"
repo.remove(['file.txt', 'file2.txt'])       # git rm -f -- "file.txt" "file2.txt"
repo.remove('file.txt', :recursive => true)  # git rm -f -r -- "file.txt"
repo.remove('file.txt', :cached => true)     # git rm -f --cached -- "file.txt"

repo.commit('message')
repo.commit_all('message')

# Sign a commit using the gpg key configured in the user.signingkey config setting
repo.config('user.signingkey', '0A46826A')
repo.commit('message', gpg_sign: true)

# Sign a commit using a specified gpg key
key_id = '0A46826A'
repo.commit('message', gpg_sign: key_id)

# Skip signing a commit (overriding any global gpgsign setting)
repo.commit('message', no_gpg_sign: true)

repo = Git.clone(git_url, 'myrepo')
repo.chdir do
  File.write('test-file', 'blahblahblah')
  repo.status.changed.each do |file|
    puts file.blob(:index).contents
  end
end

repo.reset # defaults to HEAD
repo.reset_hard(Git::Commit)

repo.branch('new_branch') # creates new or fetches existing
repo.branch('new_branch').checkout
repo.branch('new_branch').delete
repo.branch('existing_branch').checkout
repo.branch('main').contains?('existing_branch')

# delete remote branch
repo.push('origin', 'remote_branch_name', force: true, delete: true)

repo.checkout('new_branch')
repo.checkout('new_branch', new_branch: true, start_point: 'main')
repo.checkout(repo.branch('new_branch'))

repo.branch(name).merge(branch2)
repo.branch(branch2).merge  # merges HEAD with branch2

repo.branch(name).in_branch(message) { # add files }  # auto-commits
repo.merge('new_branch')
repo.merge('new_branch', 'merge commit message', no_ff: true)
repo.merge('origin/remote_branch')
repo.merge(repo.branch('main'))
repo.merge([branch1, branch2])

repo.merge_base('branch1', 'branch2')

r = repo.add_remote(name, uri)  # Git::Remote
r = repo.add_remote(name, Git::Base)  # Git::Remote

repo.remotes  # array of Git::Remotes
repo.remote(name).fetch
repo.remote(name).remove
repo.remote(name).merge
repo.remote(name).merge(branch)

repo.remote_set_branches('origin', '*', add: true) # append additional fetch refspecs
repo.remote_set_branches('origin', 'feature', 'release/*') # replace fetch refspecs

repo.fetch
repo.fetch(repo.remotes.first)
repo.fetch('origin', {:ref => 'some/ref/head'} )
repo.fetch(all: true, force: true, depth: 2)
repo.fetch('origin', {:'update-head-ok' => true})

repo.pull
repo.pull(Git::Repo, Git::Branch) # fetch and a merge

repo.add_tag('tag_name') # returns Git::Tag
repo.add_tag('tag_name', 'object_reference')
repo.add_tag('tag_name', 'object_reference', {:options => 'here'})
repo.add_tag('tag_name', {:options => 'here'})

repo.delete_tag('tag_name')

repo.repack

repo.push
repo.push(repo.remote('name'))

# delete remote branch
repo.push('origin', 'remote_branch_name', force: true, delete: true)

# push all branches to remote at one time
repo.push('origin', all: true)

repo.worktree('/tmp/new_worktree').add
repo.worktree('/tmp/new_worktree', 'branch1').add
repo.worktree('/tmp/new_worktree').remove
repo.worktrees.prune
```

### Index and Tree Operations

Some examples of more low-level index and tree operations

```ruby
repo.with_temp_index do

  repo.read_tree(tree3) # calls self.index.read_tree
  repo.read_tree(tree1, :prefix => 'hi/')

  c = repo.commit_tree('message')
  # or #
  t = repo.write_tree
  c = repo.commit_tree(t, :message => 'message', :parents => [sha1, sha2])

  repo.branch('branch_name').update_ref(c)
  repo.update_ref(branch, c)

  repo.with_temp_working do # new blank working directory
    repo.checkout
    repo.checkout(another_index)
    repo.commit # commits to temp_index
  end
end

repo.set_index('/path/to/index')

repo.with_index(path) do
  # calls set_index, then switches back after
end

repo.with_working(dir) do
# calls set_working, then switches back after
end

repo.with_temp_working(dir) do
  repo.checkout_index(:prefix => dir, :path_limiter => path)
  # do file work
  repo.commit # commits to index
end
```

## Errors Raised By This Gem

The git gem will only raise an `ArgumentError` or an error that is a subclass of
`Git::Error`. It does not explicitly raise any other types of errors.

It is recommended to rescue `Git::Error` to catch any runtime error raised by this
gem unless you need more specific error handling.

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

## Deprecations

This gem uses ActiveSupport's deprecation mechanism to report deprecation warnings.

You can silence deprecation warnings by adding this line to your source code:

```ruby
Git::Deprecation.behavior = :silence
```

See [the Active Support Deprecation
documentation](https://api.rubyonrails.org/classes/ActiveSupport/Deprecation.html)
for more details.

If deprecation warnings are silenced, you should reenable them before upgrading the
git gem to the next major version. This will make it easier to identify changes
needed for the upgrade.

## Project Policies

These documents set expectations for behavior, contribution workflows, AI-assisted
changes, decision making, maintainer roles, and licensing. Please review them before
opening issues or pull requests.

| Document | Description |
| -------- | ----------- |
| [CODE_OF_CONDUCT](CODE_OF_CONDUCT.md) | We follow the Ruby community Code of Conduct; expect respectful, harassment-free participation and report concerns to maintainers. |
| [CONTRIBUTING](CONTRIBUTING.md) | How to report issues, submit PRs with Conventional Commits, meet coding/testing standards, and follow the Code of Conduct. |
| [AI_POLICY](AI_POLICY.md) | AI-assisted contributions are welcome. Contributors are expected to read and apply the AI Policy, and ensure any AI-assisted work meets our quality, security, and licensing standards. |
| [Ruby version support policy](#ruby-version-support-policy) | Supported Ruby runtimes and platforms; bump decisions and CI coverage expectations. |
| [Git version support policy](#git-version-support-policy) | Minimum supported git version and how version bumps are communicated and enforced. |
| [GOVERNANCE](GOVERNANCE.md) | Principles-first governance defining maintainer/project lead roles, least-privilege access, consensus/majority decisions, and nomination/emeritus steps. |
| [MAINTAINERS](MAINTAINERS.md) | Lists active maintainers (Project Lead noted) and emeritus alumni with links; see governance for role scope. |
| [LICENSE](LICENSE) | MIT License terms for using, modifying, and redistributing this project. |

### Ruby Version Support Policy

This gem is expected to function correctly on:

- All [non-EOL versions](https://www.ruby-lang.org/en/downloads/branches/) of the MRI
  Ruby on Mac, Linux, and Windows
- The latest version of JRuby 9.4+ on Linux
- The latest version of TruffleRuby 24+ on Linux

It is this project's intent to support the latest version of JRuby on Windows once
the [process_executer](https://github.com/main-branch/process_executer) gem properly
supports subprocess status reporting on JRuby for Windows (see
[main-branch/process_executer#156](https://github.com/main-branch/process_executer/issues/156)).

### Git Version Support Policy

This gem requires git version 2.28.0 or greater as specified in the gemspec. This
requirement reflects:

- The minimum git version necessary to support all features provided by this gem
- A reasonable balance between supporting older systems and leveraging modern git
  capabilities
- The practical limitations of testing across multiple git versions in CI

Git 2.28.0 was released on July 27, 2020. While this gem may work with earlier
versions of git, compatibility with versions prior to 2.28.0 is not tested or
guaranteed. Users on older git versions should upgrade to at least 2.28.0.

The supported git version may be increased in future major or minor releases of this
gem as new git features are adopted or as maintaining backward compatibility becomes
impractical. Such changes will be clearly documented in the CHANGELOG and release
notes.

## 📢 Project Announcements 📢

### 2026-01-07: AI Policy Introduced

We have adopted a formal [AI Policy](AI_POLICY.md) to clarify expectations for
AI-assisted contributions. Please review it before opening a PR to ensure your
changes are fully understood, meet our quality bar, and respect licensing
requirements.

We chose a principles-based policy to respect contributors’ time and expertise. It’s
quick to read, easy to remember, and avoids unnecessary policy overhead while still
setting clear expectations.

### 2025-07-09: Architectural Redesign

The git gem is undergoing a significant architectural redesign for the upcoming
v5.0.0 release. The current architecture has several design challenges that make it
difficult to maintain and evolve. This redesign aims to address these issues by
introducing a clearer, more robust, and more testable structure.

We have prepared detailed documents outlining the analysis of the current
architecture and the proposed changes. We encourage our community and contributors to
review them:

1. [Analysis of the Current Architecture](redesign/1_architecture_existing.md): A
   breakdown of the existing design and its challenges.
2. [The Proposed Redesign](redesign/2_architecture_redesign.md): An overview of the
   new three-layered architecture.
3. [Implementation Plan](redesign/3_architecture_implementation.md): The step-by-step
   plan for implementing the redesign.

Your feedback is welcome! Please feel free to open an issue to discuss the proposed
changes.

> **DON'T PANIC!**
>
> While this is a major internal refactoring, our goal is to keep the primary public
API on the main repository object as stable as possible. Most users who rely on
documented methods like `g.commit`, `g.add`, and `g.status` should find the
transition to v5.0.0 straightforward.
>
> The breaking changes will primarily affect users who have been relying on the
internal g.lib accessor, which will be removed as part of this cleanup. For more
details, please see the "Impact on Users" section in [the redesign
document](redesign/2_architecture_redesign.md).

### 2025-07-07: We Now Use RuboCop

To improve code consistency and maintainability, the `ruby-git` project has now
adopted [RuboCop](https://rubocop.org/) as our static code analyzer and formatter.

This integration is a key part of our ongoing commitment to making `ruby-git` a
high-quality, stable, and easy-to-contribute-to project. All new contributions will
be expected to adhere to the style guidelines enforced by our RuboCop configuration.

 RuboCop can be run from the project's Rakefile:

```shell
rake rubocop
```

RuboCop is also run  as part of the default rake task (by running `rake`) that is run
in our Continuous Integration workflow.

Going forward, any PRs that have any Robocop offenses will not be merged. In certain
rare cases, it might be acceptable to disable a  RuboCop check for the most limited
scope possible.

If you have a problem fixing a  RuboCop offense, don't be afraid to ask a
contributor.

### 2025-06-06: Default Branch Rename

On June 6th, 2025, the default branch was renamed from 'master' to 'main'.

Instructions for renaming your local or forked branch to match can be found in the
gist [Default Branch Name
Change](https://gist.github.com/jcouball/580a10e395f7fdfaaa4297bbe816cc7d).

### 2025-05-15: We've Switched to Conventional Commits

To enhance our development workflow, enable automated changelog generation, and pave
the way for Continuous Delivery, the `ruby-git` project has adopted the [Conventional
Commits standard](https://www.conventionalcommits.org/en/v1.0.0/) for all commit
messages.

Going forward, all commits to this repository **MUST** adhere to the Conventional
Commits standard. Commits not adhering to this standard will cause the CI build to
fail. PRs will not be merged if they include non-conventional commits.

A git pre-commit hook may be installed to validate your conventional commit messages
before pushing them to GitHub by running `bin/setup` in the project root.

Read more about this change in the [Commit Message Guidelines section of
CONTRIBUTING.md](CONTRIBUTING.md#commit-message-guidelines)
