---
name: pull-request-review
description: "Reviews pull requests against project standards and posts review comments via the gh CLI. Use when reviewing PRs, checking coding standards compliance, or performing approval reviews."
---

# Pull Request Review Workflow

When asked to review a pull request (e.g., "Review PR #999"), follow this workflow to
analyze the changes, provide feedback, and optionally post the review to GitHub.

## Contents

- [How to use this skill](#how-to-use-this-skill)
- [Related skills](#related-skills)
- [Step 1: Fetch the PR](#step-1-fetch-the-pr)
- [Step 2: Review Against Project Standards](#step-2-review-against-project-standards)
- [Step 3: Present Review Findings](#step-3-present-review-findings)
- [Step 4: Get User Approval](#step-4-get-user-approval)
- [Step 5: Post the Review](#step-5-post-the-review)
- [Step 6: Confirm Completion](#step-6-confirm-completion)

## How to use this skill

Attach this file to your Copilot Chat context, then invoke it with the PR number
to review. Follow Step 4 explicitly: do not post review comments until the user
confirms.

## Related skills

- [PR Readiness Review](../pr-readiness-review/SKILL.md) — internal pre-PR checks
   before formal review
- [CI/CD Troubleshooting](../ci-cd-troubleshooting/SKILL.md) — investigate failed
   checks discovered during review
- [Review Backward Compatibility](../review-backward-compatibility/SKILL.md) —
   deeper audit when API compatibility concerns surface

## Step 1: Fetch the PR

1. **Read PR Details:** Use `gh pr view #999` to get title, description, author, and
   status.
2. **Get Changed Files:** Use `gh pr diff #999` to see the complete diff.
3. **Check PR Status:** Note if it's a draft, has merge conflicts, or has existing
   reviews.

## Step 2: Review Against Project Standards

Evaluate the PR against these criteria:

**Code Quality:** Ruby style (Rubocop-compliant), `frozen_string_literal: true`, proper naming (snake_case/PascalCase), single-responsibility, no duplication, Ruby 3.2+ idioms.

**Testing:** Changes covered by atomic Test::Unit tests, well-named, passing CI. Test modifications require justification.

**Documentation:** YARD docs on public methods with `@param`, `@return`, `@raise`, `@example`. README updated for user-facing changes. Platform differences and security documented.

**Architecture:** Correct layer placement (Base/Lib/CommandLine), principle of least surprise, direct Git command mapping, proper error hierarchy.

**Commits:** Conventional Commits format, lowercase subjects under 100 chars, no trailing period. Breaking changes use `!` and `BREAKING CHANGE:` footer.

**Compatibility:** Backward compatible (or marked breaking), Ruby 3.2+, Git 2.28.0+, cross-platform (Windows/macOS/Linux).

**Security:** No command injection, proper escaping via Git::CommandLine, input validation, resource cleanup.

## Step 3: Present Review Findings

Present your findings to the user in this format:

```text
# PR Review: #999 - [PR Title]

**Author:** [username]
**Status:** [open/draft/has conflicts/etc.]

## Summary
[Brief description of what the PR does]

## Recommendation
- **Review Type:** [APPROVE / COMMENT / REQUEST CHANGES]
- **Rationale:** [Why this recommendation]

## General Comments

[Overall feedback on the PR - architecture decisions, approach, etc.]

## Line-Specific Comments

[file.rb:123]
[Specific feedback about this line or section]

[file.rb:456-460]
[Feedback about this range of lines]

## Checklist Results

**Passing:**
- Uses proper Ruby style
- Tests included
- ...

**Issues Found:**
- Missing YARD documentation on `SomeClass#method`
- Commit message "Fixed bug" doesn't follow conventional commits
- ...

---

**Here is the review. Do you have any questions or want additional changes, OR should I go ahead and post this review on the PR?**
```

## Step 4: Get User Approval

Wait for the user to respond. They may:

- **Approve posting:** Proceed to Step 5
- **Request changes to review:** Modify your findings and re-present
- **Ask questions:** Answer and clarify before proceeding
- **Decide not to post:** End the workflow

Do NOT post the review without explicit user confirmation.

## Step 5: Post the Review

Once the user confirms, post the review using the GitHub CLI:

**For reviews with line-specific comments:**

1. Create the review: `gh pr review #999 --comment` (or `--approve` or
   `--request-changes`)
2. Add the general comment as the review body using `-b "comment text"`
3. For line-specific comments, you may need to use the GitHub API or instruct the
   user to add them manually in the GitHub UI

**For reviews with only general comments:**

```bash
gh pr review #999 --approve -b "Your general comment here"
# or
gh pr review #999 --comment -b "Your general comment here"
# or
gh pr review #999 --request-changes -b "Your general comment here"
```

**Note:** The `gh` CLI has limitations with line-specific comments. If the review
includes line-specific comments, inform the user of this limitation and either:

- Post only the general comment via CLI and provide the line comments for manual
  posting
- Provide the full review text for the user to post manually
- Use the GitHub API if line-specific commenting is critical

## Step 6: Confirm Completion

After posting, confirm with the user:

```text
Review posted successfully to PR #999.
View at: [PR URL from gh pr view output]
```
