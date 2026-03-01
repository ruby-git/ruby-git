---
name: test-debugging
description: "Debugs failing or flaky tests and improves test coverage. Use when tests fail consistently, exhibit intermittent behavior, or when adding missing test coverage."
---

# Test Debugging & Maintenance Workflow

When asked to debug tests or improve test coverage, follow this workflow to identify
problems, determine root causes, and apply appropriate fixes.

## Contents

- [How to use this skill](#how-to-use-this-skill)
- [Related skills](#related-skills)
- [Step 1: Run and Observe the Test](#step-1-run-and-observe-the-test)
- [Step 2: Investigate Root Cause](#step-2-investigate-root-cause)
- [Step 3: Report Findings](#step-3-report-findings)
- [Step 4: Determine Fix Strategy](#step-4-determine-fix-strategy)
- [Step 5: Verify Test Fix](#step-5-verify-test-fix)
- [Project-Specific Considerations](#project-specific-considerations)

## How to use this skill

Attach this file to your Copilot Chat context, then invoke it with the failing
test file, test name, or flakiness symptom. Stop at Step 3 for diagnosis-only
requests unless the user asks for implementation.

## Related skills

- [Development Workflow](../development-workflow/SKILL.md) — required TDD process
   when fixes involve production code
- [CI/CD Troubleshooting](../ci-cd-troubleshooting/SKILL.md) — investigate
   failures that appear only in CI

## Step 1: Run and Observe the Test

1. **Run the failing test:**

   ```bash
   # TestUnit (legacy tests in tests/units/)
   bundle exec bin/test <test_file_name>

   # RSpec unit test
   bundle exec rspec spec/unit/git/commands/<command>_spec.rb

   # RSpec integration test
   bundle exec rspec spec/integration/git/commands/<command>_spec.rb

   # Specific test method (TestUnit)
   bundle exec ruby -I lib:tests tests/units/test_base.rb -n test_method_name
   ```

2. **For suspected flaky tests, run multiple times:**

   ```bash
   for i in {1..20}; do
     echo "Run $i"
     bundle exec bin/test <test_file> || break
   done
   ```

3. **Check test isolation** — run the test alone vs. within the full suite:

   ```bash
   bundle exec bin/test <test_file>   # alone
   bundle exec rake default           # full suite
   ```

## Step 2: Investigate Root Cause

1. **Read the full error** including stack trace. Identify exact failing line and
   expected vs. actual values.

2. **Check recent changes** with `git log` and `git blame` on the test file and
   related production code.

3. **For flaky tests**, look for:
   - Shared state between tests (global/class variables, shared filesystem resources)
   - Timing dependencies or race conditions
   - Non-deterministic behavior (time-dependent logic, unordered iteration)
   - Test execution order dependencies

4. **For environment issues**, check:
   - Platform differences (paths, line endings, permissions)
   - Git version differences (use `git --version`)
   - Ruby version differences

## Step 3: Report Findings

Present diagnostic findings to the user:

```markdown
# Test Failure Diagnosis: <test_name>

**Failure Type:** [Consistent / Flaky / Coverage Gap]
**Test File:** <path/to/test_file.rb>

## Error
<error message and relevant stack trace>

## Root Cause
<Explanation of why the test is failing>

## Recommended Fix
<Specific recommendation>

**Would you like me to implement this fix?**
```

**STOP here** unless the user asks you to proceed with the fix.

## Step 4: Determine Fix Strategy

| Scenario | Strategy | Commit Type |
|---|---|---|
| **Production code bug** (test caught a real bug) | Fix production code using the development-workflow TDD process. The failing test is the RED step. | `fix(component): <description>` |
| **Test needs updating** (intentional API change) | Get user confirmation first. Update test assertions. | `test(component): update test for <change>` |
| **Flaky test** (non-determinism) | Make test deterministic. Run 20+ times to verify. | `test(component): fix flaky test in <test_name>` |
| **Missing test coverage** | Add tests using the development-workflow TDD process. | `test(component): add tests for <feature>` |
| **Test refactoring** | Improve readability/reduce duplication. Keep tests green. | `refactor(test): improve <test_name>` |
| **Environment/setup issue** | Fix environment, document requirements. No code commit needed. | — |

**CRITICAL:** Get user confirmation before modifying existing tests.

## Step 5: Verify Test Fix

```bash
# Run the specific test
bundle exec bin/test <test_file>        # TestUnit
bundle exec rspec <spec_file>           # RSpec

# For flaky test fixes, run many times
for i in {1..50}; do
  echo "Run $i"
  bundle exec bin/test <test_file> || break
done

# Run full suite
bundle exec rake default
```

## Project-Specific Considerations

**Test frameworks:** This project uses both TestUnit (legacy tests in `tests/units/`)
and RSpec (new tests in `spec/`). Run both when verifying changes.

**Test helpers:** Use `clone_working_repo`, `create_temp_repo`, `in_temp_dir` from
test helpers for TestUnit. Use `include_context` shared contexts for RSpec.

**Mocking:** The project uses Mocha for TestUnit mocking and RSpec doubles for RSpec.
Be careful with stubs — they can mask real issues.

**Test data:** Fixtures are in `tests/files/`. Use test helpers to create temporary
repos. Clean up in teardown.

**CI vs. local differences:** If tests pass locally but fail in CI, use the
ci-cd-troubleshooting skill.
