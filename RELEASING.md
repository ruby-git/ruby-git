<!--
# @markup markdown
# @title Releasing
-->

# How to release a new git.gem

Releasing a new version of the `git` gem requires these steps:

- [How to release a new git.gem](#how-to-release-a-new-gitgem)
  - [Prepare the release](#prepare-the-release)
  - [Create a GitHub release](#create-a-github-release)
  - [Build and release the gem](#build-and-release-the-gem)

These instructions use an example where the current release version is `1.5.0`
and the new release version to be created is `1.6.0.pre1`.

## Prepare the release

From a fork of ruby-git, create a PR containing changes to (1) bump the
version number, (2) update the CHANGELOG.md, and (3) tag the release.

- Bump the version number in lib/git/version.rb following [Semantic Versioning](https://semver.org)
  guidelines
- Add a link in CHANGELOG.md to the release tag which will be created later
  in this guide
- Create a new tag using [git-extras](https://github.com/tj/git-extras/blob/master/Commands.md#git-release)
  `git release` command
  - For example: `git release v1.6.0.pre1`
- These should be the only changes in the PR
- An example of these changes for `v1.6.0.pre1` can be found in [PR #435](https://github.com/ruby-git/ruby-git/pull/435)
- Get the PR reviewed, approved and merged to master.

## Create a GitHub release

On [the ruby-git releases page](https://github.com/ruby-git/ruby-git/releases),
select `Draft a new release`

- Select the tag corresponding to the version being released `v1.6.0.pre1`
- The Target should be `master`
- For the release description, use the output of [changelog-rs](https://github.com/perlun/changelog-rs)
  - A Docker image is provided in [Dockerfile.changelog-rs](https://github.com/ruby-git/ruby-git/blob/master/Dockerfile.changelog-rs)
    so you don't have to install changelog-rs or the Rust tool chain. To build the
    Docker image, run this command from this project's root directory:
    - `docker build --file Dockerfile.changelog-rs --tag changelog-rs .`
  - To run the changelog-rs command using this image, run the following command
    from this project's root directory (replace the tag names appropriate for the
    current release):
    - `docker run --rm --volume "$PWD:/worktree" changelog-rs v1.5.0 v1.6.0.pre1`
  - Copy the output, omitting the tag header `## v1.6.0.pre1` and paste into
    the release description
  - The release description can be edited later if needed
- Select the appropriate value for `This is a pre-release`
  - Since `v1.6.0.pre1` is a pre-release, check `This is a pre-release`

## Build and release the gem

Clone [ruby-git/ruby-git](https://github.com/ruby-git/ruby-git) directly (not a
fork) and ensure your local working copy is on the master branch

- Verify that you are not on a fork with the command `git remote -v`
- Verify that the version number is correct by running `rake -T` and inspecting
  the output for the `release[remote]` task

Build the git gem and push it to rubygems.org with the command `rake release`

- Ensure that your `gem sources list` includes `https://rubygems.org` (in my
  case, I usually have my work’s internal gem repository listed)
