---
name: release-management
description: "Prepares and publishes new releases of the ruby-git gem including version bumps, changelog updates, tagging, and gem publishing. Use when preparing a release or checking release readiness."
---

# Release Management Workflow

This workflow describes how releases are managed for the ruby-git gem.

## Contents

- [How to use this skill](#how-to-use-this-skill)
- [Related skills](#related-skills)
- [How Releases Work](#how-releases-work)
- [Developer Responsibilities](#developer-responsibilities)
- [Checking Release Readiness](#checking-release-readiness)
- [Cutting a maintenance branch](#cutting-a-maintenance-branch)
- [Major release readiness](#major-release-readiness)
- [After a major release](#after-a-major-release)
- [What NOT to Do](#what-not-to-do)
- [Useful Commands](#useful-commands)

## How to use this skill

Attach this file to your Copilot Chat context when preparing a release, verifying
release readiness, or answering questions about versioning and publishing flow.

## Related skills

- [Dependency Management](../dependency-management/SKILL.md) — dependency updates
   that affect release content and risk
- [PR Readiness Review](../pr-readiness-review/SKILL.md) — ensure changes are
   release-ready before merge
- [Breaking Change Analysis](../breaking-change-analysis/SKILL.md) — evaluate and
   communicate major-version impact

## How Releases Work

Releases are **fully automated** via
[release-please](https://github.com/googleapis/release-please) and the
`.github/workflows/release.yml` workflow:

1. Developers merge PRs with **conventional commit** messages into a release
   branch: `main` for the next major, or a maintenance branch such as `5.x` or
   `4.x` for a patch or minor release of an earlier series
2. release-please automatically opens (and keeps updated) a **release PR** that
   bumps `lib/git/version.rb` and regenerates `CHANGELOG.md`
3. When a maintainer merges the release PR, release-please creates a **GitHub
   release** with a tag
4. The workflow then **publishes the gem** to RubyGems.org via `rubygems/release-gem`

Key config files:

| File | Purpose |
| ---- | ------- |
| `.release-please-config.json` | Release-please settings (release type, changelog sections, versioning strategy) |
| `.release-please-manifest.json` | Tracks the current released version |
| `lib/git/version.rb` | Version constant (updated automatically by release-please) |
| `CHANGELOG.md` | Release history (updated automatically by release-please) |

`prerelease` is `false`, so release-please never proposes a beta and every release is
a normal release. The config also sets `bump-minor-pre-major: true` and
`bump-patch-for-minor-pre-major: true`, which affect version bumps only while the major
version is 0.

## Developer Responsibilities

The only thing developers need to do for releases is **use conventional commit
messages**. release-please determines the version bump from commit types:

- `fix:` → **patch** bump
- `feat:` → **minor** bump
- `feat!:` or `BREAKING CHANGE:` footer → **major** bump

Everything else (version bump, changelog, tag, gem push) is automated. Do **not**
manually edit `lib/git/version.rb` or `CHANGELOG.md`.

## Checking Release Readiness

Before a maintainer merges a release PR:

1. **Ensure CI passes on the release branch** (`main`, `5.x`, or `4.x`):

   ```bash
   bundle exec rake default
   ```

2. **Review unreleased changes since last tag:**

   ```bash
   git log $(git describe --tags --abbrev=0)..HEAD --oneline
   ```

3. **Check for open blockers:**

   ```bash
   gh issue list --label "bug" --state open
   ```

4. **Review the release PR** — verify the auto-generated changelog and version
   bump look correct.

## Cutting a maintenance branch

`main` becomes the release line for the next major as soon as the first removal merges
([ADR-0007](../../../docs/adr/0007-removals-require-one-normal-release-of-deprecation-not-calendar-soak.md)),
which can be long before that major ships. Cut the maintenance branch for the current
major at that point, not after the major release, so the series can keep releasing
while `main` is pinned to the next major.

The cut is two pull requests, one into each branch, because each branch runs its own
copy of the workflows. Both carry the same docs commit: write it once, cherry-pick it
onto the other branch, and cherry-pick it again whenever review changes it on either
side, so the two branches say the same thing. Merge the `main` PR first so the pin is
in place before anything else lands on `main`. Below, `<N>` is the major being cut,
`<N+1>` the major `main` will release next, and `<M>` the major of the maintenance
branch that already exists.

On `main`:

- [ ] Add a README announcement entry dated the cut day: every further v<N>.x release
      comes from the new branch, and the next release from `main` is v<N+1>.0.0.
- [ ] Pin the next release from `main` to the next major with a `Release-As: <N+1>.0.0`
      footer on the announcement commit. Without the pin, the first commit merged to
      `main` after the cut has release-please open a release PR for the next v<N> patch
      or minor from `main`, colliding with the release stream on the new branch.
      release-please reads the footer from any commit since the last tag, so the pin
      holds until the major ships and then expires on its own. The footer goes on a
      `main`-only commit and never on the shared docs commit, which is cherry-picked
      onto the new branch and would pin that branch's next release to the major too.
      Do not use the `release-as` key in `.release-please-config.json` instead: it
      applies to every release PR until someone remembers to remove it.

On the new branch:

- [ ] Create the branch `<N>.x` from the latest tag of that major and protect it with a
      ruleset named `Release Branch (<N>.x)`, copied from `Release Branch (default)`.
      The copy requires the same status checks as `main`. Until the next item lands,
      the only PR that can satisfy them is that item's own, whose head carries the
      triggers.
- [ ] Add the branch to the `push` trigger and the release job guard in `release.yml`,
      to the `pull_request` triggers in `continuous_integration.yml` and
      `enforce_conventional_commits.yml`, and to the `push` trigger in
      `warm_bundler_caches.yml`, all under `.github/workflows/`. The workflow that
      runs is the one on the branch pushed to or targeted, and a Bundler cache is
      readable only from the ref that wrote it, its base ref, and the default branch,
      so the copies on `main` need no change.
- [ ] Expect release-please to open a release PR from the new branch as soon as this
      PR merges. No commit type is hidden in `.release-please-config.json`, so the
      workflow and docs commits alone propose the next patch. Leave that release PR
      open until the series has something worth releasing, or merge it.

On both, in the shared docs commit:

- [ ] Name the new branch beside the existing maintenance branch everywhere that one is
      listed: the branch tables in `.github/copilot-instructions.md` and
      `CONTRIBUTING.md`, the release support policy in `README.md`, the protected
      branch list in `.husky/pre-commit`, and the skills that list the protected
      branches. `grep -rn '<M>\.x' .github .husky CONTRIBUTING.md README.md`, with the
      existing maintenance branch's major in place of `<M>`, finds them all.

## Major release readiness

Before merging the release PR for a major version, run
[Checking Release Readiness](#checking-release-readiness), then confirm each item
below. The per-PR removal gate lives in
[Breaking Change Analysis, Step 4](../breaking-change-analysis/SKILL.md#step-4-deprecation-policy)
and is checked when each removal PR merges, not here.

- [ ] Version floors are updated everywhere they are set: `required_ruby_version` in
      `git.gemspec`, `TargetRubyVersion` in `.rubocop.yml`, the CI workflow matrices
      under `.github/workflows/`, `Git::MINIMUM_GIT_VERSION` in `lib/git.rb`, the
      README "Ruby version support policy" and "Git version support policy"
      subsections, and the Compatibility list in
      [Project Context](../project-context/SKILL.md#compatibility). Include any RuboCop
      cleanup a `TargetRubyVersion` bump triggers.
- [ ] ADR-0004 audit: the options the new git floor kills are deprecated in this major
      ([ADR-0004](../../../docs/adr/0004-the-option-surface-is-the-union-of-the-supported-git-range.md)).
- [ ] Carried deprecations, if any, have their warning text, `@deprecated` YARD tag,
      and `UPGRADING.md` entry updated to name the major the roadmap decided for them,
      or "a future major release" while that is undecided, and the horizon passed to
      `ActiveSupport::Deprecation.new` in `lib/git.rb` is bumped to the next major.
- [ ] The "Upgrading to vN.0.0" section of `UPGRADING.md` is complete.
- [ ] README examples use no removed APIs.
- [ ] The changelog preview in the release PR reads correctly and every removal commit
      carries a `BREAKING CHANGE` footer.

## After a major release

- [ ] Add a README announcement entry dated the release day.
- [ ] Support for the oldest maintenance branch ends with this release (see the release
      support policy in `README.md`). Retire it everywhere it is named. In the workflow
      triggers and release job guard under `.github/workflows/`, replace it with the
      newer maintenance branch, which the cutting step left out of the copies on
      `main`. Everywhere else the newer branch is already listed, so remove the retired
      one: the branch tables in `.github/copilot-instructions.md` and
      `CONTRIBUTING.md`, the release support policy in `README.md`, the protected
      branch list in `.husky/pre-commit`, and the skills that list the protected
      branches. `grep -rn '<M>\.x' .github .husky CONTRIBUTING.md README.md`, with the
      retired branch's major in place of `<M>`, finds them all.
- [ ] Close the milestone and update the roadmap issue.

## What NOT to Do

- Do **not** manually bump `lib/git/version.rb` — release-please does this
- Do **not** manually edit `CHANGELOG.md` — it is auto-generated from commits
- Do **not** manually create tags — release-please creates them on merge
- Do **not** manually `gem push` — the workflow handles publishing
- Do **not** force-push or rebase the release PR — release-please manages it

## Useful Commands

```bash
# View recent tags
git tag -l --sort=-v:refname | head -10

# List commits since last release
git log $(git describe --tags --abbrev=0)..HEAD --oneline

# Compare with previous release
git diff $(git describe --tags --abbrev=0)..HEAD

# Check current version
ruby -e "require_relative 'lib/git/version'; puts Git::VERSION"

# View release-please config
cat .release-please-config.json | jq .

# Build gem locally (for testing only)
bundle exec rake build
gem install pkg/git-*.gem
```
