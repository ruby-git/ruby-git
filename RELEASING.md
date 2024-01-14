<!--
# @markup markdown
# @title Releasing
-->

# How to release a new git.gem

Releasing a new version of the `git` gem requires these steps:

* [Install Prerequisites](#install-prerequisites)
* [Determine the SemVer release type](#determine-the-semver-release-type)
* [Create the release](#create-the-release)
* [Review the CHANGELOG and release PR](#review-the-changelog-and-release-pr)
* [Manually merge the release PR](#manually-merge-the-release-pr)
* [Publish the git gem to RubyGems.org](#publish-the-git-gem-to-rubygemsorg)

## Install Prerequisites

The following tools need to be installed in order to create the release:

* [create_githhub_release](https://github.com/main-branch/create_github_release) is used to create the release
* [git](https://git-scm.com) is used by `create-github-release` to interact with the local and remote repositories
* [gh](https://cli.github.com) is used by `create-github-release` to create the release and PR in GitHub

On a Mac, these tools can be installed using [gem](https://guides.rubygems.org/rubygems-basics/) and [brew](https://brew.sh):

```shell
$ gem install create_github_release
...
$ brew install git
...
$ brew install gh
...
$
```

## Determine the SemVer release type

Determine the SemVer version increment that should be applied for the new release:

* `major`: when the release includes incompatible API or functional changes.
* `minor`: when the release adds functionality in a backward-compatible manner
* `patch`: when the release includes small user-facing changes that are
  backward-compatible and do not introduce new functionality.

## Create the release

Create the release using the `create-github-release` command. If the release type
is `major`, the command is:

```shell
create-github-release major
```

Follow the directions given by the `create-github-release` command to finish the
release. Where the instructions given by the command differ than the instructions
below, follow the instructions given by the command.

## Review the CHANGELOG and release PR

The `create-github-release` command will output a link to the CHANGELOG and the PR
it created for the release. Review the CHANGELOG and have someone review and approve
the release PR.

## Manually merge the release PR

It is important to manually merge the PR so a separate merge commit can be avoided.
Use the commands output by the `create-github-release` which will looks like this
if you are creating a 2.0.0 release:

```shell
git checkout master
git merge --ff-only release-v2.0.0
git push
```

This will automatically close the release PR.

## Publish the git gem to RubyGems.org

Finally, publish the git gem to RubyGems.org using the following command:

```shell
rake release:rubygem_push
```
