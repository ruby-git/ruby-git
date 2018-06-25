# Contributing to ruby-git

Thank you for your interest in contributing to this project.

These are mostly guidelines, not rules. 
Use your best judgment, and feel free to propose changes to this document in a pull request.

#### Table Of Contents

[How Can I Contribute?](#how-can-i-contribute)
  * [Submitting Issues](#submitting-issues)
  * [Contribution Process](#contribution-process)
  * [Pull Request Requirements](#pull-request-requirements)
  * [Code Review Process](#code-review-process)
  * [Developer Certification of Origin (DCO)](#developer-certification-of-origin-dco)


## How Can I Contribute?

### Submitting Issues

We utilize **GitHub Issues** for issue tracking and contributions. You can contribute in two ways:

1. Reporting an issue or making a feature request [here](https://github.com/ruby-git/ruby-git/issues/new).
2. Adding features or fixing bugs yourself and contributing your code to ruby-git.

### Contribution Process

We have a 3 step process for contributions:

1. Commit changes to a git branch in your fork.  Making sure to sign-off those changes for the [Developer Certificate of Origin](#developer-certification-of-origin-dco).
2. Create a GitHub Pull Request for your change, following the instructions in the pull request template.
3. Perform a [Code Review](#code-review-process) with the project maintainers on the pull request.

### Pull Request Requirements
In order to ensure high quality, we require that all pull requests to this project meet these specifications:

1. Unit Testing: We require all the new code to include unit tests, and any fixes to pass previous units.
2. Green CI Tests: We are using [Travis CI](https://travis-ci.org/ruby-git/ruby-git) to run unit tests on various ruby versions, we expect them to all pass before a pull request will be merged.
3. Up-to-date Documentation: New methods as well as updated methods should have [YARD](https://yardoc.org/) documentation added to them

### Code Review Process

Code review takes place in GitHub pull requests. See [this article](https://help.github.com/articles/about-pull-requests/) if you're not familiar with GitHub Pull Requests.

Once you open a pull request, project maintainers will review your code and respond to your pull request with any feedback they might have. 

The process at this point is as follows:

1. One thumbs-up (:+1:) is required from project maintainers. See the master maintainers document for the ruby-git project at <https://github.com/ruby-git/ruby-git/blob/master/MAINTAINERS.md>.
2. When ready, your pull request will be merged into `master`, we may require you to rebase your PR to the latest `master`.

### Developer Certification of Origin (DCO)

Licensing is very important to open source projects. It helps ensure the software continues to be available under the terms that the author desired.

ruby-git uses [the MIT license](https://github.com/ruby-git/ruby-git/blob/master/LICENSE)

Detail about the LICENSE can be found [here](https://choosealicense.com/licenses/mit/)

To make a good faith effort to ensure these criteria are met, ruby-git requires the Developer Certificate of Origin (DCO) process to be followed.

The DCO is an attestation attached to every contribution made by every developer. 

In the commit message of the contribution, the developer simply adds a Signed-off-by statement and thereby agrees to the DCO, which you can find below or at <http://developercertificate.org/>.

```
Developer's Certificate of Origin 1.1

By making a contribution to this project, I certify that:

(a) The contribution was created in whole or in part by me and I
    have the right to submit it under the open source license
    indicated in the file; or

(b) The contribution is based upon previous work that, to the
    best of my knowledge, is covered under an appropriate open
    source license and I have the right under that license to   
    submit that work with modifications, whether created in whole
    or in part by me, under the same open source license (unless
    I am permitted to submit under a different license), as
    Indicated in the file; or

(c) The contribution was provided directly to me by some other
    person who certified (a), (b) or (c) and I have not modified
    it.

(d) I understand and agree that this project and the contribution
    are public and that a record of the contribution (including
    all personal information I submit with it, including my
    sign-off) is maintained indefinitely and may be redistributed
    consistent with this project or the open source license(s)
    involved.
```
