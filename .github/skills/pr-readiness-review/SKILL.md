---
name: pr-readiness-review
description: "Performs a comprehensive pre-PR readiness review covering tests, code quality, security, and commit conventions. Use at the end of implementation before submitting a pull request."
---

# PR Readiness Review Workflow

Use this at the end of implementation to prepare for PR submission:

**"I've completed the implementation. Please perform a comprehensive PR readiness review."**

## Contents

- [How to use this skill](#how-to-use-this-skill)
- [Related skills](#related-skills)
- [1. Run Final Validation](#1-run-final-validation)
- [2. Verify Testing Quality](#2-verify-testing-quality)
- [3. Review Code Quality](#3-review-code-quality)
- [4. Verify Against Git Documentation](#4-verify-against-git-documentation)
- [5. Check Commit Quality](#5-check-commit-quality)
- [6. Review Documentation](#6-review-documentation)
- [7. Verify Branch Placement](#7-verify-branch-placement)
- [8. Generate PR Summary](#8-generate-pr-summary)

## How to use this skill

Attach this file to your Copilot Chat context, then invoke it after
implementation is complete and before opening a pull request. This workflow is a
final quality gate and reporting template.

## Related skills

- [Development Workflow](../development-workflow/SKILL.md) — primary
  implementation process prior to readiness checks
- [Review Command Tests](../review-command-tests/SKILL.md) — audit unit and
  integration test quality for command changes
- [Review Command YARD Documentation](../review-command-yard-documentation/SKILL.md)
  — verify command documentation completeness and consistency

## 1. Run Final Validation

Execute and report results for:
- `bundle exec rake default` - all tests and linters must pass
- Check test output for any Ruby warnings

## 2. Verify Testing Quality

**Unit Tests (Critical):**
- [ ] **100% coverage of all changed code** - every branch, edge case, error condition
- [ ] All external dependencies properly mocked (execution_context, git commands)
- [ ] Each test verifies one specific behavior
- [ ] Comprehensive coverage: success paths, failures, edge cases, error handling
- [ ] Test both public API and private methods where complexity exists

**Integration Tests (Essential Only):**
- [ ] **Minimal and purposeful** - only test what unit tests cannot verify
- [ ] Each test validates one specific git interaction pattern
- [ ] Tests verify mocked assumptions match real git behavior
- [ ] No redundancy - don't duplicate what unit tests already cover
- [ ] Follow CONTRIBUTING.md guidelines: test gem's interaction with git, not git itself

## 3. Review Code Quality

- [ ] YARD documentation complete for all public methods/classes
- [ ] Include `@api public` or `@api private` tags appropriately
- [ ] Usage examples in YARD docs show common patterns
- [ ] No breaking changes (or properly marked with `!` in commits)
- [ ] Cross-platform compatible on all supported OSes; any platform-specific logic is properly guarded and tested
- [ ] No security issues (command injection, path traversal, etc.)
- [ ] Uses Arguments DSL for building git commands

## 4. Verify Against Git Documentation

- [ ] Read https://git-scm.com/docs/git-[command] for the implemented command
- [ ] Confirm all documented options are considered
- [ ] All edge cases from git documentation are tested
- [ ] Error handling matches git's actual behavior
- [ ] Exit codes handled correctly (especially partial failures)

## 5. Check Commit Quality

- [ ] All commits follow Conventional Commits format: `type: description`
- [ ] Description is lowercase, no ending period, under 100 chars
- [ ] Valid types: feat, fix, docs, test, refactor, chore, perf, build, ci, style, revert
- [ ] Breaking changes marked with `!` and include `BREAKING CHANGE:` footer
- [ ] Each commit is atomic and has a clear purpose

## 6. Review Documentation

- [ ] Architecture docs updated if new patterns introduced (redesign/*.md)
- [ ] README.md updated if public API changed
- [ ] Examples are clear and demonstrate common use cases
- [ ] All `@param`, `@return`, `@raise` tags are accurate

## 7. Verify Branch Placement

Before creating the PR, confirm the branch situation:

- [ ] Changes are on a feature branch (not `main` or `4.x`), named
  `<type>/<short-description>`
- [ ] Branch targets the correct base: `main` for features/breaking changes;
  `4.x` for security fixes and backward-compatible v4.x-only changes

**If changes are on the wrong branch:** Create a new branch from the appropriate
base (`origin/main` or `origin/4.x`) and relocate the existing work using the
most appropriate Git approach — cherry-pick (specific commits), rebase (linear
history), or recommit (uncommitted changes) — based on the situation.

## 8. Generate PR Summary

Provide a comprehensive report with:

**Implementation Summary:**
- What was implemented and why
- Key design decisions made
- Any trade-offs or limitations

**Test Coverage:**
- Unit tests: X examples covering Y scenarios
- Integration tests: Z examples validating specific git interactions
- Coverage: 100% of changed lines (or explain gaps)
- Edge cases tested: [list critical ones]

**Quality Verification:**
- ✅ Items that passed all checks
- ⚠️ Items that need attention (if any)
- Reference to relevant documentation verified

**Suggested PR Materials:**
- PR Title: `type: clear description of change`
- PR Description draft including:
  - Summary of changes
  - Why this change is needed
  - Test coverage details
  - Breaking changes (if any)
  - Checklist from .github/pull_request_template.md

**Next Steps:**
- Any remaining items to address before PR submission
- Confirmation that all checklist items are complete
- Make sure to create a feature branch for the PR -- never push directly to main
