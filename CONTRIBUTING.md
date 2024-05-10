<!--
# @markup markdown
# @title How To Contribute
-->

# Contributing to ruby-git

Thank you for your interest in contributing to the ruby-git project.

This document gives the guidelines for contributing to the ruby-git project.
These guidelines may not fit every situation.  When contributing use your best
judgement.

Propose changes to these guidelines with a pull request.

## How to contribute

You can contribute in two ways:

1. [Report an issue or make a feature request](#how-to-report-an-issue-or-make-a-feature-request)
2. [Submit a code or documentation change](#how-to-submit-a-code-or-documentation-change)

## How to report an issue or make a feature request

ruby-git utilizes [GitHub Issues](https://help.github.com/en/github/managing-your-work-on-github/about-issues)
for issue tracking and feature requests.

Report an issue or feature request by [creating a ruby-git Github issue](https://github.com/ruby-git/ruby-git/issues/new).
Fill in the template to describe the issue or feature request the best you can.

## How to submit a code or documentation change

There is three step process for code or documentation changes:

1. [Commit your changes to a fork of ruby-git](#commit-changes-to-a-fork-of-ruby-git)
2. [Create a pull request](#create-a-pull-request)
3. [Get your pull request reviewed](#get-your-pull-request-reviewed)

### Commit changes to a fork of ruby-git

Make your changes in a fork of the ruby-git repository.

### Create a pull request

See [this article](https://help.github.com/articles/about-pull-requests/) if you
are not familiar with GitHub Pull Requests.

Follow the instructions in the pull request template.

### Get your pull request reviewed

Code review takes place in a GitHub pull request using the [the Github pull request review feature](https://help.github.com/en/github/collaborating-with-issues-and-pull-requests/about-pull-request-reviews).

Once your pull request is ready for review, request a review from at least one
[maintainer](MAINTAINERS.md) and any number of other contributors.

During the review process, you may need to make additional commits which would
need to be squashed.  It may also be necessary to rebase to master again if other
changes are merged before your PR.

At least one approval is required from a project maintainer before your pull
request can be merged.  The maintainer is responsible for ensuring that the pull
request meets [the project's coding standards](#coding-standards).

## Coding standards

In order to ensure high quality, all pull requests must meet these requirements:

### 1 PR = 1 Commit

* All commits for a PR must be squashed into one commit
* To avoid an extra merge commit, the PR must be able to be merged as [a fast forward
  merge](https://git-scm.com/book/en/v2/Git-Branching-Basic-Branching-and-Merging)
* The easiest way to ensure a fast forward merge is to rebase your local branch to
 the ruby-git master branch

### Unit tests

* All changes must be accompanied by new or modified unit tests
* The entire test suite must pass when `bundle exec rake default` is run from the
  project's local working copy.

While working on specific features you can run individual test files or
a group of tests using `bin/test`:

    # run a single file (from tests/units):
    $ bin/test test_object

    # run multiple files:
    $ bin/test test_object test_archive

    # run all unit tests:
    $ bin/test

### Continuous integration

* All tests must pass in the project's [GitHub Continuous Integration
  build](https://github.com/ruby-git/ruby-git/actions?query=workflow%3ACI) before the
  pull request will be merged.
* The [Continuous Integration
  workflow](https://github.com/ruby-git/ruby-git/blob/master/.github/workflows/continuous_integration.yml)
  runs both `bundle exec rake default` and `bundle exec rake test:gem` from the
  project's [Rakefile](https://github.com/ruby-git/ruby-git/blob/master/Rakefile).

### Documentation

* New and updated public methods must have [YARD](https://yardoc.org/) documentation
  added to them
* New and updated public facing features should be documented in the project's
  [README.md](README.md)

## Licensing

ruby-git uses [the MIT license](https://choosealicense.com/licenses/mit/) as
declared in the [LICENSE](LICENSE) file.

Licensing is very important to open source projects. It helps ensure the
software continues to be available under the terms that the author desired.
