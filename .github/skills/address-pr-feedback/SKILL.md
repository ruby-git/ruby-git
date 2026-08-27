---
name: address-pr-feedback
description: 'Addresses unresolved pull request review threads and suppressed (low-confidence) Copilot review comments on the current branch, folds each fix into the existing commit that last touched the same file, force-pushes with lease, resolves the addressed threads, and requests a fresh Copilot review. Use when addressing PR feedback, resolving review comments or threads, handling comments suppressed due to low confidence, amending fixes into prior commits, or asking Copilot to re-review after changes.'
---

# Address PR Feedback

Address the unresolved review threads and suppressed comments on the pull
request for the current branch, folding each fix into the existing commit that
last touched the affected file, then force-push and request another Copilot
review.

The full workflow lives in the `address-pr-feedback` skill of the
`jcouball-github` plugin. This file holds only what is specific to ruby-git,
so fixes to the workflow land once, in the plugin, instead of drifting
between two full copies.

## How to use this skill

Invoke `/jcouball-github:address-pr-feedback` and apply the changes below
throughout its workflow. If you arrived here because that skill told you to
read this file, do not invoke it again — its workflow is already in context;
apply the changes below and continue.

If the plugin is not installed, install it first:

```bash
claude plugin marketplace add jcouball/agent-plugins
claude plugin install jcouball-github@jcouball
```

In an agent that cannot install or invoke Claude Code plugins, read the
workflow directly from
[the plugin source](https://github.com/jcouball/agent-plugins/blob/main/plugins/github/skills/address-pr-feedback/SKILL.md)
and apply the same changes on top. In Copilot Chat, attach this file and the
plugin source to your context and proceed the same way.

## Changes and additions for ruby-git

- **Protected branches** — never rewrite history on `main` or `4.x`. Wherever
  the workflow says "the default branch or a release/maintenance branch", it
  means exactly those two here.
- **Local CI** — before folding changes into commits, the project's local CI
  equivalent is:

  ```bash
  bundle exec rake default
  ```

## Related skills

- [Pull Request Review](../pull-request-review/SKILL.md) — the review workflow
  that produces the threads this skill resolves
- [PR Readiness Review](../pr-readiness-review/SKILL.md) — pre-PR quality gate
  to run before pushing follow-up changes
- [Development Workflow](../development-workflow/SKILL.md) — TDD process and
  branch rules that govern the fixes made here
