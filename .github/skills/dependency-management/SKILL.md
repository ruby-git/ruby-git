---
name: dependency-management
description: "Updates gem dependencies, handles CVEs, and manages gemspec rules. Use when updating dependencies, checking for outdated gems, or fixing security vulnerabilities."
---

# Dependency Management Workflow

## Contents

- [How to use this skill](#how-to-use-this-skill)
- [Related skills](#related-skills)
- [Project-Specific Rules](#project-specific-rules)
- [Update Process](#update-process)
- [Key Considerations](#key-considerations)
- [Commit Guidelines](#commit-guidelines)

## How to use this skill

Attach this file to your Copilot Chat context, then invoke it with the specific
dependency update or CVE remediation scope. Apply this workflow before changing
version constraints so updates remain consistent with gem project rules.

## Related skills

- [CI/CD Troubleshooting](../ci-cd-troubleshooting/SKILL.md) — diagnose failures
   introduced by dependency updates
- [Development Workflow](../development-workflow/SKILL.md) — drive any required
   code changes via TDD
- [Release Management](../release-management/SKILL.md) — understand how
   dependency changes flow into automated releases

## Project-Specific Rules

- **All dependencies go in `git.gemspec`** (both runtime and development) - enforced by Rubocop
- **`Gemfile` should remain minimal/empty** - do not add dependencies here
- **`Gemfile.lock` is NOT committed** - this is a gem/library project

## Update Process

1. **Assess:** Run `bundle outdated` and `bundle audit check --update` (if available)
2. **Update:** Edit `git.gemspec` if constraints need changing, then run `bundle update`
3. **Test:** Run `bundle exec rake default` - must pass on all supported Ruby versions (see CI matrix in `.github/workflows/` and minimum version in `git.gemspec`)
4. **Commit:** Use conventional commit format:
   - Security: `fix(deps): update <gem> to fix CVE-XXXX-XXXX`
   - Regular: `chore(deps): update dependencies`
   - Breaking: `chore(deps)!: update <gem>` with `BREAKING CHANGE:` footer

## Key Considerations

- Security vulnerabilities are highest priority - address immediately
- For gem projects, version constraints in gemspec must be carefully chosen since users resolve dependencies independently
- Breaking changes in dependencies may require code changes (use TDD workflow)
- Test with both minimum supported versions and latest versions when possible
- If tests fail, isolate by updating gems one at a time or use binary search

## Commit Guidelines

This project uses [Conventional Commits](https://www.conventionalcommits.org/). A
commit hook enforces the format. See the Git Commit Conventions section in
`copilot-instructions.md` for the full format and allowed types.
