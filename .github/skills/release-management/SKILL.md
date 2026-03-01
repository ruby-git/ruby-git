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

1. Developers merge PRs with **conventional commit** messages into `main`
2. release-please automatically opens (and keeps updated) a **release PR** that
   bumps `lib/git/version.rb` and regenerates `CHANGELOG.md`
3. When a maintainer merges the release PR, release-please creates a **GitHub
   release** with a tag
4. The workflow then **publishes the gem** to RubyGems.org via `rubygems/release-gem`

Key config files:

| File | Purpose |
|------|---------|
| `.release-please-config.json` | Release-please settings (release type, changelog sections, versioning strategy) |
| `.release-please-manifest.json` | Tracks the current released version |
| `lib/git/version.rb` | Version constant (updated automatically by release-please) |
| `CHANGELOG.md` | Release history (updated automatically by release-please) |

The versioning strategy is `prerelease` with `beta` as the prerelease type. The
config also sets `bump-minor-pre-major: true` and `bump-patch-for-minor-pre-major: true`.

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

1. **Ensure CI passes on `main`:**

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
