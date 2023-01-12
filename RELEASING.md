<!--
# @markup markdown
# @title Releasing
-->

# How to release a new git.gem

Releasing a new version of the `git` gem requires these steps:

- [How to release a new git.gem](#how-to-release-a-new-gitgem)
  - [Install Prerequisites](#install-prerequisites)
  - [Prepare the Release](#prepare-the-release)
  - [Review and Merge the Release](#review-and-merge-the-release)
  - [Build and Release the Gem](#build-and-release-the-gem)

These instructions use an example where:

- The default branch is `master`
- The current release version is `1.5.0`
- You want to create a new *minor* release, `1.6.0`

## Install Prerequisites

The following tools need to be installed in order to create the release:

- [git](https://git-scm.com) is used to interact with the local and remote repositories
- [gh](https://cli.github.com) is used to create the release and PR in GitHub
- [Docker](https://www.docker.com) is used to run the script to create the release notes

On a Mac, these tools can be installed using [brew](https://brew.sh):

```shell
$ brew install git
...
$ brew install gh
...
$ brew install --cask docker
...
$
```

## Prepare the Release

Bump the version, create release notes, tag the release and create a GitHub release and PR which can be used to review the release.

Steps:

- Check out the code with `git clone https://github.com/ruby-git/ruby-git ruby-git-v1.6.0 && cd ruby-git-v1.6.0`
- Install development dependencies using bundle `bundle install`
- Based upon the nature of the changes, decide on the type of release: `major`, `minor`, or `patch` (in this example we will use `minor`)
- Run the release script `bundle exec create-github-release minor`

## Review and Merge the Release

Have the release PR approved and merge the changes into the `master` branch.

**IMPORTANT** DO NOT merge to the `master` branch using the GitHub UI. Instead use the instructions below.

Steps:

- Get the release PR reviewed and approved in GitHub
- Merge the changes with the command `git checkout master && git merge --ff-only v1.6.0 && git push`

## Build and Release the Gem

Build the gem and publish it to [rubygems.org](https://rubygems.org/gems/git)

Steps:

- Build and release the gem using rake `bundle exec rake release`
