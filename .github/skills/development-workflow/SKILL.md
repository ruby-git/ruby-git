---
name: development-workflow
description: "Follows a strict Test-Driven Development (TDD) workflow with four phases: triage, prepare, execute, and finalize. Use for bug fixes, feature implementation, refactoring, and maintenance tasks."
---

# Development Workflow

This skill implements a strict Test-Driven Development (TDD) workflow.

**This project strictly follows TDD practices. All production code MUST be
written using the TDD process described below.**

## Contents

- [Contents](#contents)
- [How to use this skill](#how-to-use-this-skill)
- [Workflow Overview](#workflow-overview)
- [Core TDD Principles](#core-tdd-principles)
- [Phase 0: TRIAGE](#phase-0-triage)
- [Phase 1: PREPARE](#phase-1-prepare)
- [Phase 2: EXECUTE](#phase-2-execute)
  - [RED-GREEN Step](#red-green-step)
  - [REFACTOR Step](#refactor-step)
  - [VERIFY Step](#verify-step)
  - [COMMIT Step](#commit-step)
  - [REPLAN Step](#replan-step)
- [Phase 3: FINALIZE](#phase-3-finalize)
  - [Per-Task Commits](#per-task-commits)
- [Related skills](#related-skills)
- [Additional Guidelines](#additional-guidelines)
- [Example TDD Cycle](#example-tdd-cycle)

## How to use this skill

Attach this file to your Copilot Chat context, then invoke it when implementing
features, fixing bugs, refactoring, or maintaining code. Follow phases in order
and stop after TRIAGE when the issue is non-actionable or needs clarification.

## Workflow Overview

When assigned a task involving a GitHub issue, follow this workflow:

1. **Phase 0: TRIAGE** - Understand the issue and determine if action is needed
2. **Phase 1: PREPARE** - Set up the environment and plan the implementation
3. **Phase 2: EXECUTE** - Implement the solution using TDD
4. **Phase 3: FINALIZE** - Squash commits and create the PR

**Note:** Not all issues require implementation. Phase 0 may result in requesting
clarification, confirming the issue is a duplicate, or determining no changes are
needed.

## Related skills

- [Test Debugging](../test-debugging/SKILL.md) — focused diagnosis for failing or
  flaky tests
- [CI/CD Troubleshooting](../ci-cd-troubleshooting/SKILL.md) — workflow for CI
  failures and environment-specific issues
- [PR Readiness Review](../pr-readiness-review/SKILL.md) — final quality gate
  before opening a pull request

## Core TDD Principles

Adhere to the following fundamental principles to ensure high code quality and test
coverage:

- **Never Write Production Code without a Failing Test**
- **Bug Fixes Start with Tests:** Before fixing any bug, write a failing test that
  demonstrates the bug and fails in the expected way. Only then fix the code to make
  the test pass.
- **Tests Drive Design:** Let the test dictate the API and architecture. If the test
  is hard to write, the design is likely wrong. When this happens, stop and suggest
  one or more design alternatives. Offer to stash any current changes and work on the
  design improvements first before continuing with the original task.
- **Write Tests Incrementally:** Build tests in small steps, writing just enough to
  get the next expected failure. For example, first write a test that references a
  class that doesn't exist (fails), then define the empty class (passes), then extend
  the test to call a method (fails), then define the method (passes), etc.
- **Tests Should Be Atomic:** Each test should verify exactly one logical behavior,
  making failures easy to diagnose and understand.
- **Prefer the Simplest Solution:** Choose the simplest implementation that could
  possibly work, even if it seems naive. Complexity should only be added when driven
  by actual requirements in tests.
- **No Implementation in Advance:** Only write the code strictly needed to pass the
  current test.

## Phase 0: TRIAGE

The purpose of this phase is to understand what the issue is asking for, investigate
the current state of the codebase, and determine whether implementation is needed.

**Use this phase when the user references a GitHub issue number** (e.g., "Fix issue
\#999", "Implement \#999", "Diagnose issue \#999").

1. **Fetch the Issue:** Use `gh issue view #999` to read the full issue content,
   including description, comments, and labels.

2. **Understand the Request:** Analyze what is being asked:
   - Is this a bug report? Feature request? Question? Documentation issue?
   - Is the issue clear and actionable, or does it need clarification?
   - Are there reproduction steps or examples provided?

3. **Search for Context:** Investigate the codebase to understand the area affected:
   - Use `grep_search` or `semantic_search` to find relevant code
   - Read related test files to understand existing behavior
   - Check if similar functionality already exists
   - Look for related issues or PRs that might be relevant

4. **Reproduce (if applicable):** For bug reports:
   - Try to reproduce the issue based on the provided steps
   - Run existing tests to see if they catch the issue
   - Verify the issue still exists in the current codebase

5. **Determine Next Steps and Report Findings:**

   **Option A: Issue needs clarification**
   - Comment on the issue using `gh issue comment #999 --body "..."`
   - Ask specific questions about reproduction steps, expected behavior, or use case
   - **STOP here** - wait for user/reporter response before proceeding

   **Option B: Issue is not actionable (duplicate, won't-fix, already resolved)**
   - Comment on the issue explaining your findings
   - Suggest closing the issue or linking to related issues
   - **STOP here** - no implementation needed

   **Option C: Issue is clear and actionable**
   - Comment on the issue confirming you understand the request and plan to implement
   - Summarize your understanding and proposed approach
   - **Proceed to Phase 1: PREPARE** to begin implementation

   **Option D: User asked only to diagnose (not implement)**
   - Comment on the issue with your diagnostic findings
   - Explain what you discovered (root cause, affected code, potential solutions)
   - **STOP here** - wait for confirmation to proceed with implementation

**GitHub CLI Commands for Phase 0:**

- View issue: `gh issue view #999`
- View with comments: `gh issue view #999 --comments`
- Comment on issue: `gh issue comment #999 --body "Your comment here"`
- Search issues: `gh issue list --search "keyword"`

## Phase 1: PREPARE

The purpose of this phase is to ensure the project environment is ready, establish a
clean baseline, and create a clear implementation plan before writing any code.

**Only proceed to this phase if Phase 0 determined that implementation is needed.**

1. **Check Uncommitted Changes:** If there are any uncommitted changes in the
   project, ask the user what to do with them before continuing: include them in the
   current implementation plan, ignore them, or stash them before continuing.
2. **Create Feature Branch:** Create a new branch from `origin/main` using the naming
   convention `<type>/<short-description>` (e.g., `fix/issue-999`).
3. **Verify Project Setup:** Run `bin/setup` to ensure that the project is ready
   for development.
4. **Verify Clean Baseline:** Ensure that all existing tests and linters pass by
   running `bundle exec rake default`.
5. **Analyze and Plan:** Understand the requirements, identify edge cases and
   potential challenges, and break the work into small, isolated tasks. Consider what
   tests will be needed and in what order they should be written.
6. **Consider Refactoring:** Look for ways to make the implementation of the feature
   or bug fix easier by performing one or more refactorings. If any are found,
   suggest them to the user. If the user confirms the refactoring, do the refactoring
   in a separate TDD process. Only once the refactoring is completed should the
   current feature or bug fix be worked on.
7. **Review Implementation Guidelines:** When implementing or modifying git command
   wrappers, read the "Wrapping a git command" section in CONTRIBUTING.md before
   proceeding. This ensures consistent API design
   for method placement, naming, parameters, and output processing.

## Phase 2: EXECUTE

The purpose of this phase is to implement each planned task using strict TDD cycles,
ensuring every line of production code is driven by a failing test.

Execute each task by repeating the following cycle of steps until all tasks are
complete:

1. **RED-GREEN:** Write failing tests and implement code to make them pass
2. **REFACTOR:** Improve code quality and design without changing behavior
3. **VERIFY:** Confirm the task is complete and code meets quality standards
4. **COMMIT:** Create a commit for the completed task
5. **REPLAN:** Review the implementation plan, then return to step 1 for the next
   task

When all tasks are complete, proceed to **Phase 3: FINALIZE**.

### RED-GREEN Step

1. **RED Substep**

   The purpose of this substep is to write a failing test that you hypothesize will
   pass with the next incremental bit of task implementation.

   - **Write the Test:** Write a single, focused, failing test or extend an existing
     test for the current task.
   - **Keep It Minimal:** Only write enough of a test to get an expected, failing
     result (the test should fail for the *right* reason).
   - **Execute and Analyze:** Run the specific test file (e.g.,
     `bundle exec rspec spec/unit/git/commands/<command>_spec.rb` for RSpec or
     `bundle exec bin/test <test_file>` for TestUnit) and analyze the output.
   - **Confirm Expected Failure:** Confirm it fails with an expected error (e.g.,
     assertion failure or missing definition).
   - **Validate:** If the test passes without implementation, the test is invalid or
     the logic already exists. When that happens, revise or skip.

2. **GREEN Substep**

   The purpose of this substep is to write just enough production code to make the
   failing test(s) pass.

   - **Write Minimal Code:** Write the minimum amount of code required to make the
     test pass.
   - **Use Simple Solutions:** It is acceptable to use hardcoded values or "quick and
     dirty" logic here just to get to green, even if this means intentionally writing
     clearly suboptimal code that you will improve during the REFACTOR step.
   - **No Premature Optimization:** Do NOT optimize, clean up, or improve code style
     during GREEN—that work belongs in the REFACTOR step.
   - **Execute and Verify:** Run the specific test file
     - **If the test passes**, proceed to the REFACTOR step
     - **If the test fails**, read the FULL error output including the stack trace.
       Identify the exact failing line and assertion before modifying any code. Fix
       only what the error indicates, then re-run. Repeat until the test passes.
   - **Rollback on Repeated Failure:** If the test cannot be made to pass within 3
     attempts, revert all changes from this RED-GREEN cycle, report the issue to the
     user, and ask for guidance before proceeding.
   - **Stay Focused:** Do not implement future features or optimizations yet.

### REFACTOR Step

The purpose of this step is to improve code quality and design without changing
behavior, ensuring the codebase remains clean and maintainable.

**You must consider refactoring before starting the next task.** Remove duplication,
improve variable names, and apply design patterns. Skip this step only if the code is
already clean and simple—avoid over-engineering.

- **Generalize the Implementation:** Ensure the code solves the general case, not
  just the specific test case. Replace hardcoded values used to pass the test with
  actual logic.
- **Limit Scope:** Do not perform refactorings that affect files outside the
  immediate scope of the current task. If a broader refactor is needed, add it to the
  task list during the REPLAN step as a separate task.
- **Execute All Tests:** Run `bundle exec rake default` and verify they still pass.
- **Verify Test Independence:** Verify tests can run independently in any order.
- **Confirm Improvement:** Ensure the refactoring made the code clearer, simpler, or
  more maintainable.

### VERIFY Step

The purpose of this step is to confirm that the current task is fully complete before
moving to the next task.

- **Confirm Implementation Complete:** Verify all functionality for the task is
  implemented.
- **Run All Tests:** Run `bundle exec rspec` and `bundle exec rake test` to ensure
  all tests pass.
- **Run Linters:** Run `bundle exec rubocop` and `bundle exec rake yard` to verify
  code style and documentation standards.
- **Check Code Quality:** Confirm the code is clean and well-factored.
- **STOP on Unexpected Failure:** If any test unexpectedly fails during VERIFY, STOP
  immediately and report the failure to the user. Do not attempt to fix the failure
  without first explaining what went wrong and getting confirmation to proceed.

### COMMIT Step

The purpose of this step is to create a checkpoint after successfully completing a
task, providing a safe rollback point.

- **Create Commit:** Commit all changes from this task using the appropriate
  conventional commit type (see the **Per-Task Commits** section below for guidance).
- **Keep Commits Atomic:** Each commit should represent one completed task with all
  tests passing and linters clean.

### REPLAN Step

The purpose of this step is to review progress and adjust the implementation plan
based on what was learned during the current task.

- **Review Implementation Plan:** Assess whether the remaining tasks are still valid
  and appropriately scoped based on what was learned.
- **Identify New Tasks:** If the implementation revealed new requirements, edge
  cases, or necessary refactorings, add them to the task list.
- **Reprioritize if Needed:** Adjust task order if dependencies or priorities have
  changed.
- **Report Progress:** Briefly summarize what was completed and what remains.
  **ALWAYS** print the updated task list with status (e.g., `[x] Task 1`, `[ ] Task
  2`).
- **Continue or Complete:** If tasks remain, return to RED-GREEN for the next task.
  If all tasks are complete, proceed to **Phase 3: FINALIZE**.

## Phase 3: FINALIZE

The purpose of this phase is to consolidate all task commits into a single, clean
commit and complete the feature or bug fix.

1. **Run Final Verification:** Run `bundle exec rake default` one final time to
   ensure everything passes.
2. **Safety Check:** Run `git log --oneline HEAD~N..HEAD` (where N is the number of
   task commits) to list the commits included in the squash. Verify these are
   strictly the commits generated during the current session. If unexpected commits
   appear, STOP and ask the user for the correct value of N.
3. **Capture Commit Messages:** Run `git log --format="- %s" HEAD~N..HEAD` to capture
   individual commit messages for inclusion in the final commit body.
4. **Draft the Squash Message:** Prepare a commit message with:
   - **Subject:** A single line summarizing the entire feature or fix (e.g.,
     `feat(branch): add Branch#create method`)
   - **Body:** A summary of what was implemented, the captured commit messages from
     step 2, key decisions made, and any relevant context. Wrap lines at 100
     characters.
5. **Propose the Squash:** Present the drafted message and the commands to squash to
   the user:
   - `git reset --soft HEAD~N` (where N is the number of task commits)
   - `git commit -m "<drafted message>"`
6. **Wait for Confirmation:** Do NOT execute the squash until the user reviews the
   commits and confirms. The user may want to adjust the message or keep some commits
   separate.
7. **Execute on Confirmation:** Once confirmed, run `git reset --soft HEAD~N` to
   unstage the task commits while preserving all changes, then commit with the
   approved message.
8. **Handle Commit Hook Failure:** If the commit fails due to a `commit-msg` hook
   rejection (e.g., commitlint error):
   - Read the error message carefully to identify the formatting issue.
   - Fix the commit message to comply with the project's commit conventions.
   - Retry the commit. The changes remain staged after a hook failure, so only the
     `git commit` command needs to be re-run.
   - If the commit fails 3 times, STOP and report the issue to the user with the
     exact error message.


### Per-Task Commits

In the COMMIT step, create a commit for the completed task following these
guidelines:

- **Use Appropriate Types:**
  - `test:` for adding or modifying tests (RED step)
  - `feat:` for new **user-facing** functionality (triggers MINOR version bump)
  - `fix:` for bug fixes (GREEN step for bugs)
  - `refactor:` for code improvements without behavior change
  - `chore:` for internal tooling or maintenance
- **Use Scope When Relevant:** Include a scope to indicate the affected component
  (e.g., `feat(branch):`, `test(remote):`).
- **Write Clear Subjects:** Use imperative mood, lowercase, no period (e.g.,
  `feat(branch): add create method`).

## Additional Guidelines

These guidelines supplement the TDD process:

- **Justify Test Modifications:** If an existing test needs to be modified, STOP and
  report to the user before making the change. Explain which test needs modification,
  why the expected behavior is changing, and whether this represents a breaking
  change. Wait for user confirmation before proceeding.
- **Unrelated Test Failures:** If you need to modify a test file that is not related
  to the current task to make the build pass, STOP and report to the user. This
  usually indicates a deeper regression, environment issue, or flawed assumption. Do
  not attempt to fix unrelated tests without user guidance.
- **Handle Discovered Complexity:** If the implementation reveals a complex logic
  gap, add it to your task list but finish the current cycle first.
- **Test Names Describe Behavior:** Name tests to clearly describe what behavior they
  verify (e.g., `test_creates_new_branch` not `test_branch`).
- **Ask for Clarification:** Stop and ask for clarification if requirements or
  expectations are ambiguous.
- **Do NOT Update CHANGELOG.md:** The CHANGELOG is auto-generated from commit
  messages. Never edit it manually.

## Example TDD Cycle

Each task follows this cycle: **RED → GREEN → REFACTOR → VERIFY → COMMIT → REPLAN**

**RED:** Write a failing test that describes the desired behavior.

```ruby
def test_creates_new_branch
  @git.branch('feature').create
  assert @git.branches.local.map(&:name).include?('feature')
end
# Run: bundle exec bin/test test_branch → fails with NoMethodError
```

**GREEN:** Write minimal code to make the test pass.

```ruby
def create
  @base.lib.branch_new(@name)
end
# Run: bundle exec bin/test test_branch → passes
```

**REFACTOR:** Improve code quality without changing behavior, then run all tests.

**VERIFY:** Run `bundle exec rake default` to confirm tests and linters pass.

**COMMIT:** `git commit -m "feat(branch): add Branch#create method"`

**REPLAN:** Report progress, update task list, proceed to next task or FINALIZE.

**FINALIZE (after all tasks):** Propose squash commit with captured messages, wait
