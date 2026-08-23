---
name: resolve-feedback
description: 'Resolves unresolved pull request review threads and suppressed (low-confidence) Copilot review comments on the current branch, folds each fix into the existing commit that last touched the same file, force-pushes with lease, and requests a fresh Copilot review. Use when addressing PR feedback, resolving review comments or threads, handling comments suppressed due to low confidence, amending fixes into prior commits, or asking Copilot to re-review after changes.'
---

# Resolve Feedback

Address the unresolved review threads and suppressed comments on the pull
request for the current branch, folding each fix into the existing commit that
last touched the affected file, then force-push and request another Copilot
review.

## Contents

- [Contents](#contents)
- [How to use this skill](#how-to-use-this-skill)
- [Related skills](#related-skills)
- [Prerequisites](#prerequisites)
- [Terms](#terms)
- [Safety and stop points](#safety-and-stop-points)
- [Workflow](#workflow)
- [Step 1: Identify the PR and branch](#step-1-identify-the-pr-and-branch)
- [Step 2: Fetch unresolved review threads](#step-2-fetch-unresolved-review-threads)
- [Step 3: Fetch suppressed comments](#step-3-fetch-suppressed-comments)
- [Step 4: Triage each item](#step-4-triage-each-item)
- [Step 5: Implement the changes](#step-5-implement-the-changes)
- [Step 6: Fold each change into the matching commit](#step-6-fold-each-change-into-the-matching-commit)
- [Step 7: Force-push the branch](#step-7-force-push-the-branch)
- [Step 8: Reply to and resolve threads](#step-8-reply-to-and-resolve-threads)
- [Step 9: Request another Copilot review](#step-9-request-another-copilot-review)
- [Troubleshooting](#troubleshooting)

## How to use this skill

Attach this file to your Copilot Chat context and invoke it when a PR has review
feedback to address on the current branch. Work top to bottom. Stop and ask the
user whenever a thread or suppressed comment needs a clarification or decision
(Step 4) and before the history-rewriting force-push (Step 7).

## Related skills

- [Pull Request Review](../pull-request-review/SKILL.md) — the review workflow
  that produces the threads this skill resolves
- [PR Readiness Review](../pr-readiness-review/SKILL.md) — pre-PR quality gate to
  run before pushing follow-up changes
- [Development Workflow](../development-workflow/SKILL.md) — TDD process and
  branch rules that govern the fixes made here

## Prerequisites

- The `gh` CLI is installed and authenticated (`gh auth status`).
- The `jq` CLI is installed (Step 3 pipes `gh api` output through it).
- The current branch has an open PR and is a topic branch (not `main` or `4.x`).
- The working tree has no unrelated uncommitted changes before starting.

## Terms

- **Unresolved review thread** — a PR review thread whose `isResolved` is
  `false` in the GitHub GraphQL API.
- **Suppressed comment** — a comment Copilot withheld from the thread list,
  embedded in a review body under a "Comments suppressed due to low confidence"
  `<details>` section. It has no thread ID or comment ID, so it can be neither
  replied to nor resolved — its disposition is reported in the final summary
  instead (Step 9).
- **Base** — the merge-base between the PR base branch and `HEAD`, computed with
  `git merge-base origin/<base-branch> HEAD`. All commit lookups are scoped to
  `<base>..HEAD` so only this branch's commits are considered.
- **Target commit** — the newest commit in `<base>..HEAD` that last touched the
  file a fix applies to. Each fix is folded into its target commit.

## Safety and stop points

These rules are mandatory:

- Never rewrite history on `main` or `4.x`. Confirm the branch first with
  `git branch --show-current`.
- Stop and ask the user whenever a thread or suppressed comment requests a
  clarification or decision (Step 4). Do not guess on ambiguous feedback.
- Force-push only with `--force-with-lease`, and only after the user confirms
  (Step 7).
- Do not resolve a thread until its fix is committed and pushed (Step 8).

## Workflow

1. [Identify the PR and branch](#step-1-identify-the-pr-and-branch)
2. [Fetch unresolved review threads](#step-2-fetch-unresolved-review-threads)
3. [Fetch suppressed comments](#step-3-fetch-suppressed-comments)
4. [Triage each item](#step-4-triage-each-item) — ask for clarifications or
   decisions as needed
5. [Implement the changes](#step-5-implement-the-changes)
6. [Fold each change into the matching commit](#step-6-fold-each-change-into-the-matching-commit)
7. [Force-push the branch](#step-7-force-push-the-branch)
8. [Reply to and resolve threads](#step-8-reply-to-and-resolve-threads)
9. [Request another Copilot review](#step-9-request-another-copilot-review)

## Step 1: Identify the PR and branch

Confirm the branch and locate the PR for it:

```bash
git branch --show-current
gh pr view --json number,title,headRefName,baseRefName,url,state
```

Record the PR number, `baseRefName` (the base branch), and URL. If no PR is
associated with the branch, stop and tell the user.

## Step 2: Fetch unresolved review threads

List the first 100 review threads and keep the ones where `isResolved` is
`false`. For unusually active PRs with more than 100 review threads, paginate
before assuming no unresolved threads remain.

```bash
OWNER=$(gh repo view --json owner --jq '.owner.login')
REPO=$(gh repo view --json name --jq '.name')
PR_NUMBER=$(gh pr view --json number --jq '.number')

gh api graphql -f query='
  query($owner:String!, $repo:String!, $pr:Int!) {
    repository(owner:$owner, name:$repo) {
      pullRequest(number:$pr) {
        reviewThreads(first:100) {
          nodes {
            id
            isResolved
            isOutdated
            path
            line
            comments(first:30) {
              nodes { databaseId author { login } body }
            }
          }
        }
      }
    }
  }' -F owner="$OWNER" -F repo="$REPO" -F pr="$PR_NUMBER" \
  --jq '.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved == false)'
```

For each unresolved thread, note its `id` (thread ID, needed to resolve it), the
first comment `databaseId` (needed to reply), the `path`, and the `line`.

## Step 3: Fetch suppressed comments

Copilot omits low-confidence findings from the thread list and instead embeds
them in its review body under a `<details>` section titled "Comments suppressed
due to low confidence". Print the newest review whose body contains that
section (guarding against null bodies, and matching the exact section title so
reviews that merely mention the word "suppressed" do not match), then read the
section out of the printed body:

```bash
gh api "repos/$OWNER/$REPO/pulls/$PR_NUMBER/reviews" --paginate |
  jq -sr 'add
    | map(select((.body // "")
      | contains("Comments suppressed due to low confidence")))
    | sort_by(.submitted_at)
    | last // empty
    | "review \(.id) by \(.user.login) at \(.submitted_at)\n\n\(.body)"'
```

The pipeline sorts the matching reviews by `submitted_at` and keeps only the
last one — the listing order of `/pulls/.../reviews` is not guaranteed, and
suppressed sections in earlier reviews describe superseded revisions of the
code. The `-r` flag prints the body as raw text (real newlines instead of a
JSON-escaped string) under a one-line header identifying the review. For each
suppressed comment, record the file path, the line reference, and the comment
text from the section body.

Before triaging, check each suppressed comment against the current working
tree: line numbers in an older review body may have drifted, and a later push
may already have addressed the finding. Drop the ones that no longer apply and
note them for the final summary (Step 9).

## Step 4: Triage each item

For each unresolved thread and each still-applicable suppressed comment,
classify it and act:

- **Actionable and unambiguous** → plan the concrete code or doc change.
- **Needs a clarification or decision** → stop and ask the user. Present the
  item's file, line, and comment text, and the specific question or the
  options you see. Wait for the answer before implementing.
- **Not applicable / disagree** → do not change code. For a thread, draft a
  short, respectful reply explaining why (used in Step 8). For a suppressed
  comment, note the reasoning for the final summary. Ask the user if you are
  unsure whether to push back.

Triage suppressed comments with the same rigor as threads — low confidence
means Copilot was unsure, not that the finding is wrong.

Do not proceed to Step 5 for an item until its resolution is clear.

## Step 5: Implement the changes

Apply the agreed changes in the workspace. Keep edits for each item minimal and
scoped to what the feedback asks. If the project has tests or linters, run the
relevant checks before folding changes into commits:

```bash
bundle exec rake default
```

Fix any failures before continuing.

## Step 6: Fold each change into the matching commit

Amend each change into its target commit — the existing commit on this branch
that last touched the file — instead of adding new follow-up commits.

1. Compute the base once:

   ```bash
   BASE=$(git merge-base origin/<base-branch> HEAD)
   ```

2. For each changed file, find its target commit (the topmost line is newest):

   ```bash
   git log --oneline "$BASE"..HEAD -- <path>
   ```

3. Stage that file and create a fixup commit aimed at its target SHA:

   ```bash
   git add <path>
   git commit --fixup=<target-sha>
   ```

   Repeat for each changed file. When several files share the same target
   commit, stage them together for one fixup.

4. Autosquash the fixups into their targets non-interactively:

   ```bash
   GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash "$BASE"
   ```

5. Verify the result — the fixup commits should be gone and history should be
   clean:

   ```bash
   git --no-pager log --oneline "$BASE"..HEAD
   git status --short --branch
   ```

If a change does not correspond to any existing commit (e.g. a brand-new file
requested in review), ask the user whether to fold it into a related commit or
add a new, conventionally formatted commit.

## Step 7: Force-push the branch

History was rewritten, so the branch must be force-pushed. This is a
history-rewriting operation — confirm with the user first, then use a lease to
avoid clobbering unseen remote commits:

```bash
git push --force-with-lease
```

If the push is rejected, someone updated the remote branch. Fetch and reconcile
before retrying; do not use `--force` to override the lease.

## Step 8: Reply to and resolve threads

For each thread that is now addressed:

1. Reply to the thread, referencing what changed. Keep reply bodies shell-safe:
   use single quotes for simple one-line replies, or assign a quoted heredoc to a
   variable for arbitrary text. Do not put human-written reply text directly in a
   double-quoted shell argument; review comments can contain characters such as
   `!`, `$`, backticks, or quotes that the shell may expand before `gh` runs.

```bash
COMMENT_DATABASE_ID=COMMENT_DATABASE_ID_FROM_THREAD
reply_body='Addressed in the latest push: <short summary>.'

gh api \
  "repos/$OWNER/$REPO/pulls/$PR_NUMBER/comments/$COMMENT_DATABASE_ID/replies" \
  -f body="$reply_body"
```

For multi-line replies or text that may contain shell metacharacters, use a
single-quoted heredoc delimiter:

```bash
COMMENT_DATABASE_ID=COMMENT_DATABASE_ID_FROM_THREAD
reply_body=$(cat <<'EOF'
Addressed in the latest push: the guidance now covers `@!method` declarations.
EOF
)

gh api \
  "repos/$OWNER/$REPO/pulls/$PR_NUMBER/comments/$COMMENT_DATABASE_ID/replies" \
  -f body="$reply_body"
```

2. Resolve the thread:

   ```bash
   gh api graphql -f query='
     mutation($threadId:ID!) {
       resolveReviewThread(input:{threadId:$threadId}) {
         thread { id isResolved }
       }
     }' -F threadId=THREAD_ID
   ```

Only resolve threads whose feedback was actually addressed (or that the user
agreed to close after a reply). Leave threads open when the user still owes a
decision.

Suppressed comments have no thread, so there is nothing to reply to or
resolve — their disposition (fixed, already addressed, no longer applicable, or
disagreed) goes into the final summary instead.

## Step 9: Request another Copilot review

Request a fresh Copilot review on the PR so it re-reviews the amended commits.

- Preferred: activate the pull request management tools, then request a Copilot
  review via the GitHub pull request tooling (`request_copilot_review`).
- Do **not** create a new Copilot PR task for a re-review; that opens separate
  work instead of re-reviewing this PR.

Finish by reporting to the user: the threads resolved, any threads left open and
why, the disposition of each suppressed comment, the new commit list, and the
PR URL.

## Troubleshooting

| Issue | Solution |
| ----- | -------- |
| `git log "$BASE"..HEAD -- <path>` is empty | The file is new on this branch; ask the user whether to fold into a related commit or add a new commit. |
| Rebase stops with conflicts | Resolve the conflict, `git add` the files, then `git rebase --continue`. |
| Force-push rejected despite `--force-with-lease` | The remote branch moved; run `git fetch`, review the remote changes, reconcile, and retry. |
| A thread has no obvious file/line (`path` is null) | It is a PR-level comment; reply at the PR level and resolve only if addressed. |
| No review body contains a suppressed section | Copilot suppressed nothing on this PR; continue with the unresolved threads alone. |
| A suppressed comment's line reference does not match the current code | Locate the referenced code in the current tree, or drop the comment as no longer applicable and note it in the summary. |
| Unsure whether to push back on feedback | Stop and ask the user before replying or resolving. |
