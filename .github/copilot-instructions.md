# GitHub Copilot Instructions for ruby-git

## Project Overview

ruby-git is a Ruby gem providing a Ruby interface to Git repositories. It wraps
system calls to the `git` CLI and exposes an API for creating and manipulating repos,
working with branches/commits/tags/remotes, inspecting history and objects, and
performing all standard Git operations.

**Status:** Stable. Minimum Ruby 3.2.0, minimum Git 2.28.0. MRI on macOS/Linux/Windows;
JRuby and TruffleRuby on Linux (JRuby/TruffleRuby on Windows are not tested).

For architecture details, coding standards, design philosophy, key technical details,
and compatibility requirements see the
[Project Context](skills/project-context/SKILL.md) skill.

## Skill Loading

When a skill applies to a request, read the entire `SKILL.md` file before taking
any other action. Read from line 1 through EOF with no gaps. Simple code review
or explanation does not require a skill.

## Project Commands

| Purpose | Command |
|---|---|
| First-time setup | `bin/setup` |
| Run all tests and linters(CI-equivalent) | `bundle exec rake default:parallel` |
| Run all tests (both suites) | `bundle exec rake test-all:parallel` |
| Run Test::Unit tests | `bundle exec rake test:parallel` |
| Run all RSpec tests | `bundle exec rake spec:parallel` |
| Run RSpec unit tests | `bundle exec rake spec:unit:parallel` |
| Run RSpec integration tests | `bundle exec rake spec:integration:parallel` |
| Run a specific Test::Unit test | `bundle exec bin/test <test-base-name>` |
| Run a specific RSpec spec | `bundle exec rspec <path>` |
| Run linters | `bundle exec rake rubocop yard build` |

**Test suites:** `spec/` (RSpec) is the current suite — all new tests go here.
`tests/` (Test::Unit) is legacy; only touch it when modifying existing tests there
or adding pre-migration coverage to verify that a `Git::Lib` → `Git::Commands`
migration doesn't break existing behaviour.

## Commit Conventions

This project uses [Conventional Commits](https://www.conventionalcommits.org/).
Automated releases via [release-please](https://github.com/googleapis/release-please).

**Format:** `type[optional scope][!]: description`

**Types:** `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `chore`,
`revert`, `ci`, `build`

**Breaking changes:** Add `!` before `:` and a `BREAKING CHANGE: <description>`
footer.

**Version bumps:** breaking change → major; `feat` → minor; others → patch.

**Pre-commit hook:** Run `bin/setup` to install a validator.

## Branch & PR Strategy

| Target | When |
|---|---|
| `main` | New features, breaking changes, all active development |
| `4.x` | Security fixes and backward-compatible bug fixes for the v4.x series |

> **Never commit directly to `main` or `4.x`** — this rule must never be violated.
> Always check `git branch --show-current` before committing. If on a release branch,
> run `git switch -c <type>/<short-description>` first.

All changes go via PR from a topic branch.

**Creating a PR:** Use `gh pr create`. Read `.github/pull_request_template.md` for
the body structure. Complete the [PR Readiness Review](skills/pr-readiness-review/SKILL.md)
skill first.

## Key Documents

| Document | Purpose |
|---|---|
| `CONTRIBUTING.md` | Design philosophy, contribution guidelines |
| `CHANGELOG.md` | Version history (auto-updated by release-please) |
| `MAINTAINERS.md` | Maintainer list and responsibilities |
| `AI_POLICY.md` | AI usage policy for this project |
| `redesign/` | Architecture redesign plans and implementation guide |
| `.github/skills/` | All Copilot skills |
