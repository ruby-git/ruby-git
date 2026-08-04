---
description: Address all unresolved Copilot review threads on the active pull request
argument-hint: "[PR number — defaults to the PR for the current branch]"
---

Follow the shared agent prompt in
`.github/prompts/iteratively-address-copilot-reviews.prompt.md` exactly. That file
is the canonical instructions for this task and is shared with other AI agents; read
it before doing anything else.

@.github/prompts/iteratively-address-copilot-reviews.prompt.md

If `$ARGUMENTS` is non-empty, treat it as the pull request number to operate on
instead of detecting the PR from the current branch.
