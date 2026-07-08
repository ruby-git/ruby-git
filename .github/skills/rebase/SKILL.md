---
name: rebase
description: 'Rebases the current branch onto origin/main, resolves rebase conflicts, and force-pushes with lease using non-interactive Git commands that never open an editor. Use when updating a feature branch from main, handling rebase conflicts, or rewriting branch history before updating a pull request.'
---

# Rebase

Rebase the current branch on `origin/main`, resolve conflicts, and force-push
the rewritten history without opening an editor.

## Contents

- [Contents](#contents)
- [How to use this skill](#how-to-use-this-skill)
- [Related skills](#related-skills)
- [Prerequisites](#prerequisites)
- [Safety rules](#safety-rules)
- [Workflow](#workflow)
- [Step 1: Preflight checks and fetch](#step-1-preflight-checks-and-fetch)
- [Step 2: Start rebase on origin/main](#step-2-start-rebase-on-originmain)
- [Step 3: Resolve conflicts and continue](#step-3-resolve-conflicts-and-continue)
- [Step 4: Verify the rebased branch](#step-4-verify-the-rebased-branch)
- [Step 5: Force-push with lease](#step-5-force-push-with-lease)
- [Troubleshooting](#troubleshooting)

## How to use this skill

Attach this file to your Copilot Chat context, then invoke it when the current
branch needs to be rebased onto `origin/main` and pushed.

## Related skills

- [Resolve Feedback](../resolve-feedback/SKILL.md) — follow-up workflow for
  addressing PR review comments after rebasing
- [PR Readiness Review](../pr-readiness-review/SKILL.md) — final validation
  before opening or updating a pull request

## Prerequisites

- `git` is installed and authenticated for the remote.
- The branch is a topic branch with an upstream on `origin`.
- The working tree is clean before rebasing.

## Safety rules

These rules are mandatory:

- Never run this workflow on `main` or `4.x`.
- Always fetch `origin` immediately before rebasing.
- Always run rebase commands with `GIT_EDITOR=:` and `GIT_SEQUENCE_EDITOR=:` so
  no editor opens.
- Force-push only with `--force-with-lease`.

## Workflow

1. [Preflight checks and fetch](#step-1-preflight-checks-and-fetch)
2. [Start rebase on origin/main](#step-2-start-rebase-on-originmain)
3. [Resolve conflicts and continue](#step-3-resolve-conflicts-and-continue)
4. [Verify the rebased branch](#step-4-verify-the-rebased-branch)
5. [Force-push with lease](#step-5-force-push-with-lease)

## Step 1: Preflight checks and fetch

```bash
git branch --show-current
git status --short --branch
git fetch --prune origin
```

If the current branch is `main` or `4.x`, stop and ask the user to switch to a
topic branch first.

If `git status --short --branch` shows uncommitted changes, stop and ask the
user whether to commit or stash before continuing.

## Step 2: Start rebase on origin/main

```bash
GIT_EDITOR=: GIT_SEQUENCE_EDITOR=: git rebase origin/main
```

If the command succeeds, continue to Step 4. If it stops with conflicts, go to
Step 3.

## Step 3: Resolve conflicts and continue

Repeat until the rebase completes:

1. Inspect conflicted files:

   ```bash
   git status --short
   ```

2. Edit conflicted files, remove conflict markers, and keep the intended final
   content.

3. Stage resolved files:

   ```bash
   git add <resolved-path> [<resolved-path>...]
   ```

4. Continue the rebase without opening an editor:

   ```bash
   GIT_EDITOR=: GIT_SEQUENCE_EDITOR=: git rebase --continue
   ```

5. If Git reports an empty patch after conflict resolution, skip that commit:

   ```bash
   GIT_EDITOR=: GIT_SEQUENCE_EDITOR=: git rebase --skip
   ```

If the rebase cannot be completed safely, abort and report back:

```bash
git rebase --abort
```

## Step 4: Verify the rebased branch

```bash
git status --short --branch
git merge-base --is-ancestor origin/main HEAD
git --no-pager log --oneline --decorate --max-count=15
```

`git merge-base --is-ancestor origin/main HEAD` must exit successfully.

## Step 5: Force-push with lease

```bash
git push --force-with-lease
```

If push is rejected, fetch and reconcile remote updates before retrying. Never
replace this with plain `--force`.

## Troubleshooting

| Issue | Solution |
| ----- | -------- |
| Rebase stops with conflicts | Resolve files, `git add`, then run `GIT_EDITOR=: GIT_SEQUENCE_EDITOR=: git rebase --continue`. |
| Rebase continue opens an editor | Re-run with both `GIT_EDITOR=:` and `GIT_SEQUENCE_EDITOR=:` prefixes. |
| `--force-with-lease` push rejected | Run `git fetch origin`, inspect divergence, reconcile, and retry `--force-with-lease`. |
| Need to abandon rebasing attempt | Run `git rebase --abort` and report the reason to the user. |
