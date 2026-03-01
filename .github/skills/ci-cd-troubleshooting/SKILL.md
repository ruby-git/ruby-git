---
name: ci-cd-troubleshooting
description: "Diagnoses and fixes CI/CD failures in GitHub Actions workflows. Use when CI is failing on a PR, builds are broken, or tests pass locally but fail in CI."
---

# CI/CD Troubleshooting Workflow

When asked to diagnose or fix CI/CD failures (e.g., "Why is CI failing on PR #999?",
"Fix the failing build"), follow this workflow to identify the root cause and
optionally implement fixes.

## Contents

- [How to use this skill](#how-to-use-this-skill)
- [Related skills](#related-skills)
- [Step 1: Identify the Failure](#step-1-identify-the-failure)
- [Step 2: Fetch Relevant Logs](#step-2-fetch-relevant-logs)
- [Step 3: Diagnose Root Cause](#step-3-diagnose-root-cause)
- [Step 4: Reproduce Locally (if applicable)](#step-4-reproduce-locally-if-applicable)
- [Step 5: Report Findings or Fix](#step-5-report-findings-or-fix)
  - [Option A: Diagnostic Report ("Why is CI failing?")](#option-a-diagnostic-report-why-is-ci-failing)
  - [Option B: Implement Fix ("Fix the failing build")](#option-b-implement-fix-fix-the-failing-build)
- [Step 6: Verify Fix](#step-6-verify-fix)
- [Special Troubleshooting Considerations](#special-troubleshooting-considerations)

## How to use this skill

Attach this file to your Copilot Chat context, then invoke it with a failing PR
number, branch, or CI run context. Use Option A for diagnosis-only requests and
Option B when the user explicitly asks for a fix.

## Related skills

- [Test Debugging](../test-debugging/SKILL.md) — deep-dive test failure analysis
   and flakiness fixes
- [Development Workflow](../development-workflow/SKILL.md) — full TDD execution
   when implementing CI fixes
- [PR Readiness Review](../pr-readiness-review/SKILL.md) — final validation
   before opening or updating a PR

## Step 1: Identify the Failure

1. **Get CI Status:**
   - For PRs: `gh pr checks #999`
   - For branches: `gh run list --branch <branch-name> --limit 5`
   - Note which jobs passed and which failed

2. **Categorize the Failure Type:**
   - **Test failures** - Unit tests, integration tests failing
   - **Linter failures** - Rubocop, YARD documentation issues
   - **Build failures** - Dependency installation, compilation errors
   - **Timeout failures** - Jobs exceeding time limits
   - **Platform-specific failures** - Failing on specific Ruby version or OS

3. **Identify Specific Failing Steps:**
   - Note the exact job name and step that failed
   - Record the Ruby version, OS, and other environment details

## Step 2: Fetch Relevant Logs

**CRITICAL: CI logs can be massive (100K+ lines) and exceed token limits.**

1. **Get the Run ID:**

   ```bash
   gh run list --branch <branch> --limit 1 --json databaseId --jq '.[0].databaseId'
   ```

2. **Fetch Failed Job Logs Only:**

   ```bash
   gh run view <run-id> --log-failed
   ```

   This limits output to only failed jobs, making it manageable.

3. **Extract Key Error Information:**

   - For test failures: Look for stack traces, assertion errors, specific test names
   - For linter failures: Extract file names, line numbers, and violation types
   - For build failures: Find dependency errors or missing packages
   - Use `grep` to filter logs if still too large:

     ```bash
     gh run view <run-id> --log-failed | grep -A 10 -B 5 "Error\|FAILED\|Failure"
     ```

4. **Avoid Full Log Downloads:**

   - Do NOT use `--log` without `--log-failed` unless specifically requested
   - If logs are still too large, focus on the most recent or critical failure

## Step 3: Diagnose Root Cause

Based on the failure type, investigate:

**For Test Failures:**

- Check if the test exists and what it's testing
- Look for recent changes that might have broken the test
- Consider environment differences (local vs. CI)
- Check for flaky tests (intermittent failures)

**For Linter Failures:**

- Run linters locally: `bundle exec rubocop` and `bundle exec rake yard`
- Identify specific violations from the log
- Check if violations are in files related to recent changes

**For Build Failures:**

- Check dependency versions in `Gemfile` and `git.gemspec`
- Look for platform-specific dependency issues
- Verify Ruby version compatibility

**For Timeout Failures:**

- Identify which test or step is timing out
- Check for infinite loops or performance regressions
- Consider if it's a resource limitation in CI environment

## Step 4: Reproduce Locally (if applicable)

**For PR Failures:**

1. Fetch the PR branch:

   ```bash
   gh pr checkout #999
   ```

2. Run the failing tests locally:

   ```bash
   bundle exec bin/test <test-name>
   ```

3. Run linters:

   ```bash
   bundle exec rubocop
   bundle exec rake yard
   ```

**For Branch Failures:**

1. Checkout the branch.
2. Run full CI workflow:

   ```bash
   bundle exec rake default
   ```

## Step 5: Report Findings or Fix

Determine the appropriate action based on the user's request:

### Option A: Diagnostic Report ("Why is CI failing?")

Present findings to the user:

````markdown
# CI Failure Diagnosis: <Branch/PR>

**Status:** <X of Y jobs failed>

## Failed Jobs
1. **<Job Name>** (<Ruby version>, <OS>)
   - **Step:** <failing step name>
   - **Failure Type:** <test/linter/build/timeout>

## Root Cause
<Explanation of what's causing the failure>

## Error Details
```
<Relevant error messages and stack traces>
```

## Recommendations
- <Specific fix suggestion 1>
- <Specific fix suggestion 2>

**Would you like me to implement a fix, or do you need more information?**
````

**STOP here** unless the user asks you to proceed with fixes.

### Option B: Implement Fix ("Fix the failing build")

Proceed based on failure type:

- **Test Failures:** Use the full TDD workflow (Phase 1-3) to fix the failing tests
- **Linter Failures:** Fix violations directly, commit with appropriate message
  (e.g., `style: fix rubocop violations in lib/git/base.rb`)
- **Build Failures:** Update dependencies or configuration as needed
- **Timeout Failures:** Investigate performance issues, may require user guidance

**For PR Failures on Someone Else's PR:**

- You may not have push access to their branch
- Present the fix and ask user to either:
  - Push to the PR branch (if they have access)
  - Comment on the PR with suggested changes
  - Create a new PR with fixes

## Step 6: Verify Fix

After implementing fixes:

1. **Run Affected Tests Locally:**

   ```bash
   bundle exec bin/test <test-name>
   ```

2. **Run Full CI Suite:**

   ```bash
   bundle exec rake default
   ```

3. **Push and Monitor:**

   - Push the fixes
   - Monitor CI to confirm the fix worked:

     ```bash
     gh run watch
     ```

4. **Confirm Resolution:**

   ```text
   Fix implemented and pushed. Monitoring CI run...
   CI Status: <link to run>
   ```

## Special Troubleshooting Considerations

**Platform-Specific Failures:**

- If tests pass on macOS but fail on Linux/Windows, document the difference
- Check for path separator issues (`/` vs. `\`)
- Look for encoding differences
- Consider file system case sensitivity

**Flaky Tests:**

- If a test fails intermittently, note this in your diagnosis
- Run the test multiple times locally to confirm flakiness
- Suggest fixes for race conditions or timing issues

**Permission Issues:**

- If you can't push to a PR branch, clearly communicate this limitation
- Provide the exact commands or changes needed for the user to apply

**Token Limit Management:**

- Always use `--log-failed` to limit output
- If logs are still too large, use `grep` to extract errors
- Focus on the first failure if multiple failures exist
- Consider running tests locally instead of relying on full CI logs
