---
agent: agent
model: claude-sonnet-4.6
description: Address all unresolved Copilot review threads on the active pull request until there are no remaining unresolved review threads
---

Address unresolved **Copilot** review threads on the active pull request. Ignore threads opened by human reviewers. Ask me for clarification or decisions as needed.

If any terminal script command fails, stop immediately. Do not continue the loop, do not resolve additional threads, and do not request a new review. Report: the failed command, exit code, and the most relevant stderr output. **Exception**: the reply POST in Step 3 is intentionally non-fatal — a 404 after a force-push is expected and the resolve step must still run.

## Terminology

- **Review** — a top-level review submission by `copilot-pull-request-reviewer`, with a `submittedAt` timestamp and an optional summary body. A single review may contain zero or more Review Threads.
- **Review Thread** — an inline comment thread attached to a specific code location. Key fields: `id` (GraphQL node ID, e.g. `PRRT_…`), `isResolved` (manually resolved by a maintainer), `isOutdated` (the underlying code changed since the thread was created). Each thread has one or more comments; the first comment is Copilot's suggestion.
- **Check Run** — a standard CI status object on the HEAD commit. Note: Copilot Reviews do **not** create a Check Run; use the Reviews API to detect completion instead.

## Before the Loop

Run in terminal to establish `OWNER`, `REPO`, and `PR_NUMBER` for use throughout:

```bash
set -euo pipefail
OWNER=$(gh repo view --json owner --jq '.owner.login')
REPO=$(gh repo view --json name --jq '.name')
PR_NUMBER=$(gh pr view --json number --jq '.number')
: "${OWNER:?failed to resolve OWNER}"
: "${REPO:?failed to resolve REPO}"
: "${PR_NUMBER:?failed to resolve PR_NUMBER}"
```

Fetch unresolved, non-outdated Copilot Review Threads:

```bash
set -euo pipefail
: "${OWNER:?missing OWNER}"
: "${REPO:?missing REPO}"
: "${PR_NUMBER:?missing PR_NUMBER}"
threads_json=$(gh api graphql -f query='
  query($owner:String!,$repo:String!,$pr:Int!){
    repository(owner:$owner,name:$repo){
      pullRequest(number:$pr){
        reviewThreads(first:100){nodes{id isResolved isOutdated path
          comments(first:1){nodes{databaseId author{login} createdAt body}}}}}}
  }' -f owner="$OWNER" -f repo="$REPO" -F pr="$PR_NUMBER" \
  --jq '.data.repository.pullRequest.reviewThreads.nodes')
if [[ $(echo "$threads_json" | jq 'length') -ge 100 ]]; then
  echo "Error: the PR already has 100 threads or more. Aborting."
  exit 1
fi
echo "$threads_json" | jq '[.[] |
  select(.isResolved==false) |
  select(.isOutdated==false) |
  select(.comments.nodes[0].author.login=="copilot-pull-request-reviewer")]'
```

- **Results non-empty** → proceed directly to the iteration loop.
- **Results empty** → record `REVIEW_REQUESTED_AT` (current UTC, `YYYY-MM-DDTHH:MM:SSZ`, e.g. `2026-06-16T12:00:00Z`), request a new Copilot Review using the `mcp_github_mcp_se_request_copilot_review` tool (owner, repo, pullNumber), then jump to the **Wait for Review** section below.

## Iteration Loop

Repeat up to **${input:maxIterations:5}** iterations:

### 1. Address threads

Re-fetch unresolved, non-outdated Copilot Review Threads using the same `gh api graphql` query from Before the Loop. Group by file. For each file, read it once and address all its threads in that single pass:
- Validate each suggestion before accepting it.
- If a suggestion is invalid or out of scope: reply explaining why, then resolve the thread without changing code.
- Otherwise: implement the change using TDD where possible; ensure test coverage.

Skip any thread where `isOutdated` is true — the code it references has already changed; Copilot will re-evaluate it in the next Review.

After all threads are addressed, run `rake`. If it fails, capture `rake 2>&1 | tail -n 50` and fix the failure before continuing.

### 2. Commit and push

Amend each change into the most relevant existing commit on the branch based on file name. If a change spans multiple commits or doesn't map clearly to one, ask me which commit to amend into (or whether to create a new commit). Confirm the working tree is clean and `rake` passes, then force push.

### 3. Reply and resolve

For each addressed thread object from the unresolved-threads query, in the same `run_in_terminal` script block that performs reply/resolve, export:

- `COMMENT_DBID=.comments.nodes[0].databaseId`
- `THREAD_ID=.id`
- `EXPLANATION` to your plain-language fix summary for that thread

Set the per-thread variables (`COMMENT_DBID`, `THREAD_ID`, `EXPLANATION`) immediately before running the commands below — do not rely on them surviving from a prior terminal invocation.

Then post a reply and resolve it:

```bash
set -euo pipefail
: "${OWNER:?missing OWNER}"
: "${REPO:?missing REPO}"
: "${COMMENT_DBID:?missing COMMENT_DBID}"
: "${EXPLANATION:?missing EXPLANATION}"

# Reply (COMMENT_DBID = databaseId of the thread's first comment)
# Build JSON via jq to safely handle quotes/newlines/special chars in EXPLANATION.
# EXPLANATION should contain the full reply text (e.g. "Fixed: ..." or "Not addressing this because...").
BODY_JSON=$(jq -n --arg body "$EXPLANATION" '{body:$body}')
# Non-fatal: a force-push can mark threads as outdated, causing the REST reply to return 404.
# Always continue to the GraphQL resolve step regardless.
gh api "repos/$OWNER/$REPO/pulls/comments/$COMMENT_DBID/replies" \
  -X POST --input - <<<"$BODY_JSON" \
  || echo "Warning: reply POST failed (thread may be outdated after force-push) — skipping reply, will still resolve"

: "${THREAD_ID:?missing THREAD_ID}"

# Resolve (THREAD_ID = GraphQL node id, e.g. PRRT_...)
gh api graphql \
  -f query='mutation($id:ID!){resolveReviewThread(input:{threadId:$id}){thread{isResolved}}}' \
  -f id="$THREAD_ID"
```

### 4. Request review

**If this was the ${input:maxIterations:5}th iteration**, skip steps 4 and 6 entirely — go directly to step 5 (Report) and then produce the Final Report.

Otherwise, capture `REVIEW_REQUESTED_AT` by running `date -u +%Y-%m-%dT%H:%M:%SZ` in the terminal immediately before requesting the review. Then request a new Copilot Review using the `mcp_github_mcp_se_request_copilot_review` tool (owner, repo, pullNumber).

### 5. Report

List what was addressed and how each issue was resolved.

### 6. Wait

Jump to the **Wait for Review** section below. Return here to begin the next iteration once the new Copilot Review has been submitted.

## Wait for Review

**[BLOCKING — do not proceed until complete]** Poll for a new Copilot Review submission using the Reviews API. A Review with `submittedAt >= REVIEW_REQUESTED_AT` is the authoritative completion signal — it fires even when Copilot produces zero Review Threads.

Run the following script via `run_in_terminal` (sync mode, timeout 750000 ms). Set the four variables on the first line to their actual values. On success, capture the script's last output line; on failure, follow the global failure-reporting rule (failed command, exit code, relevant stderr):

```bash
set -euo pipefail
# Replace with actual values. REVIEW_REQUESTED_AT = output of `date -u +%Y-%m-%dT%H:%M:%SZ` captured just before requesting the review.
OWNER="ruby-git"; REPO="ruby-git"; PR_NUMBER="1439"; REVIEW_REQUESTED_AT="2026-06-16T12:00:00Z"
: "${OWNER:?missing OWNER}"
: "${REPO:?missing REPO}"
: "${PR_NUMBER:?missing PR_NUMBER}"
: "${REVIEW_REQUESTED_AT:?missing REVIEW_REQUESTED_AT}"
START=$(date +%s)
for i in $(seq 1 60); do
  new_review=$(gh pr view "$PR_NUMBER" --repo "$OWNER/$REPO" --json reviews \
    --jq "[.reviews[] | select(.author.login==\"copilot-pull-request-reviewer\") | select(.submittedAt != null) | select(.submittedAt | fromdateiso8601 >= (\"$REVIEW_REQUESTED_AT\" | fromdateiso8601))] | length") \
    || { rc=$?; echo "Error: gh pr view failed (exit $rc)"; exit $rc; }
  if [[ -n "$new_review" && "$new_review" -gt 0 ]]; then
    raw_nodes=$(gh api graphql -f query='
      query($owner:String!,$repo:String!,$pr:Int!){
        repository(owner:$owner,name:$repo){
          pullRequest(number:$pr){
            reviewThreads(first:100){nodes{isResolved isOutdated comments(first:1){nodes{author{login}}}}}
          }
        }
      }' -f owner="$OWNER" -f repo="$REPO" -F pr="$PR_NUMBER" \
      --jq '.data.repository.pullRequest.reviewThreads.nodes') \
      || { rc=$?; echo "Error: gh api graphql failed (exit $rc)"; exit $rc; }
    if [[ $(echo "$raw_nodes" | jq 'length') -ge 100 ]]; then
      echo "Error: the PR already has 100 threads or more. Aborting."
      exit 1
    fi
    count=$(echo "$raw_nodes" | jq "[.[] |
      select(.isResolved==false) |
      select(.isOutdated==false) |
      select(.comments.nodes[0].author.login==\"copilot-pull-request-reviewer\")] | length")
    echo "done: $count threads"  # count of all unresolved non-outdated Copilot Review Threads
    exit 0
  fi
  elapsed=$(( $(date +%s) - START ))
  echo "Waiting for Copilot Review to complete... (${elapsed}s elapsed)"
  sleep 10
done
echo "timed out after 60 polls"
exit 1
```

**If `timed out after 60 polls`**: stop immediately and ask me whether to re-request the review and retry, or abort.

**If `done: 0 threads`**: the loop is complete — exit.

**If `done: N threads`** (N > 0): begin the next iteration.

## Final Report

- Total iterations completed
- Total threads addressed
- Unresolved threads in the final Copilot review (should be 0 if the loop exited cleanly)
