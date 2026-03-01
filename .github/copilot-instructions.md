# GitHub Copilot Instructions for ruby-git

## Project Overview

ruby-git is a Ruby gem providing a Ruby interface to Git repositories. It wraps
system calls to the `git` CLI and exposes an API for creating and manipulating repos,
working with branches/commits/tags/remotes, inspecting history and objects, and
performing all standard Git operations.

**Status:** Stable. Minimum Ruby 3.2.0, minimum Git 2.28.0. MRI only; Mac, Linux,
Windows.

For architecture details, coding standards, design philosophy, key technical details,
and compatibility requirements see the
[Project Context](skills/project-context/SKILL.md) skill.

## Task Routing

Select the skill for the task at hand and attach it to your Copilot Chat context.

| Task | Skill |
|---|---|
| Triage / diagnose an issue | [development-workflow](skills/development-workflow/SKILL.md) — Phase 0 only |
| Fix a bug | [development-workflow](skills/development-workflow/SKILL.md) — all phases |
| Implement a feature | [development-workflow](skills/development-workflow/SKILL.md) — all phases |
| Refactor / improve code | [development-workflow](skills/development-workflow/SKILL.md) — all phases |
| Maintenance (linting, version bumps) | [development-workflow](skills/development-workflow/SKILL.md) — all phases |
| Migrate a command from Git::Lib | [extract-command-from-lib](skills/extract-command-from-lib/SKILL.md) |
| Review a pull request | [pull-request-review](skills/pull-request-review/SKILL.md) |
| Pre-PR readiness check | [pr-readiness-review](skills/pr-readiness-review/SKILL.md) |
| CI/CD failure diagnosis | [ci-cd-troubleshooting](skills/ci-cd-troubleshooting/SKILL.md) |
| Debug failing / flaky tests | [test-debugging](skills/test-debugging/SKILL.md) |
| Update dependencies / fix CVEs | [dependency-management](skills/dependency-management/SKILL.md) |
| Prepare a release | [release-management](skills/release-management/SKILL.md) |
| Assess breaking changes / deprecation | [breaking-change-analysis](skills/breaking-change-analysis/SKILL.md) |
| YARD docs / documentation fixes | [write-yard-documentation](skills/write-yard-documentation/SKILL.md) |
| Audit or create a Copilot skill | [reviewing-skills](skills/reviewing-skills/SKILL.md) / [make-skill-template](skills/make-skill-template/SKILL.md) |
| Code review / explain code | *(no skill needed)* |

### Command-Migration Skills

| Skill | File |
|---|---|
| Scaffold New Command | [scaffold-new-command](skills/scaffold-new-command/SKILL.md) |
| Extract Command from Lib | [extract-command-from-lib](skills/extract-command-from-lib/SKILL.md) |
| Refactor Command to CommandLineResult | [refactor-command-to-commandlineresult](skills/refactor-command-to-commandlineresult/SKILL.md) |
| Review Arguments DSL | [review-arguments-dsl](skills/review-arguments-dsl/SKILL.md) |
| Review Command Implementation | [review-command-implementation](skills/review-command-implementation/SKILL.md) |
| Review Command Tests | [review-command-tests](skills/review-command-tests/SKILL.md) |
| Review Command YARD Documentation | [review-command-yard-documentation](skills/review-command-yard-documentation/SKILL.md) |
| Review Cross-Command Consistency | [review-cross-command-consistency](skills/review-cross-command-consistency/SKILL.md) |
| Review Backward Compatibility | [review-backward-compatibility](skills/review-backward-compatibility/SKILL.md) |

## Project Commands

| Purpose | Command |
|---|---|
| First-time setup | `bin/setup` |
| Run all tests (CI-equivalent) | `bundle exec rake default` |
| Run all tests (both suites) | `bundle exec rake test_all` |
| Run Test::Unit tests | `bundle exec rake test` |
| Run all RSpec tests | `bundle exec rake spec` |
| Run RSpec unit tests | `bundle exec rake spec:unit` |
| Run RSpec integration tests | `bundle exec rake spec:integration` |
| Run a specific Test::Unit test | `bundle exec bin/test <name>` (no extension) |
| Run a specific RSpec spec | `bundle exec rspec <path>` |
| Run a specific Test::Unit method | `bundle exec ruby -I lib:tests tests/units/<test_file>.rb -n <method_name>` |
| Run tests in Docker (multi-Ruby) | `bin/test-in-docker` |
| Run linters | `bundle exec rake rubocop yard` |

## Coding Standards Summary

- `frozen_string_literal: true` on every Ruby file
- Ruby 3.2.0+ idioms; keyword arguments for multi-parameter methods
- `private` keyword form (not `private :method_name`)
- Single-responsibility classes; one public class per file
- YARD on all public methods: `@param`, `@return`, `@raise`, `@example`

See [project-context](skills/project-context/SKILL.md) for full details.

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

Never commit directly to `main` or `4.x`. All changes via PR from a feature branch
named `<type>/<short-description>`.

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
