---
agent: agent
model: claude-sonnet-4.6
description: Address all unresolved review comments on the active pull request in a loop until Copilot review has no remaining comments
---

Address the unresolved **Copilot** review comments from the active pull request, asking me for any clarifications or decisions needed along the way. Only Copilot review comments are in scope; ignore comments from human reviewers.

This prompt references specific models by name (see below). If any named model is not available, stop and ask me which model to use instead rather than silently falling back to a default.

Run the following in a loop, up to a maximum of **${input:maxIterations:5} iterations**. Each iteration of addressing issues must be performed using a subagent with the **"Claude Sonnet 4.6 (copilot)"** model. Continue iterating until a Copilot review completes with no remaining comments, or until ${input:maxIterations:5} iterations have run.

If there are no unresolved Copilot comments on the first pass, report that and exit without making any changes.

To keep token usage low, subagents must return only a short structured summary to the orchestrator (e.g. `Files changed: ...; Comments resolved: N; Rake: pass/fail`), never full diffs, file contents, or comment text. The orchestrator should pass only IDs and outcomes between steps; each subagent fetches the comments and reads the files it needs itself.

## Per-Iteration Steps

1. For each unresolved Copilot review comment (group comments by file and address all comments for a file in a single pass to avoid re-reading it):
   - Verify that the suggestion is valid and the best approach before accepting it.
   - If the suggestion is invalid, out of scope, or should not be acted on, do not change code. Instead, reply to the comment explaining why, then resolve it.
   - Otherwise, implement the change using TDD where possible.
   - Make sure that there is test coverage for any code changed or added.
   - Make sure to `rake` after the changes are done to ensure the CI build will succeed. If `rake` fails, capture only the failing summary (e.g. `rake 2>&1 | tail -n 50`) rather than full output, and fix the failure before continuing.

2. Once all comments in this iteration have been addressed, amend each change into the most relevant previous commit on this branch based on file name. If a change spans multiple commits or does not clearly map to any single commit, ask me which commit to amend into (or whether to create a new commit). Before force pushing, confirm the working tree is clean and `rake` passes, then force push the result.

3. After the force push succeeds, for each addressed comment add a reply explaining what was changed and how the issue was resolved, then resolve the comment.

4. Ask Copilot for a new review.

5. Report for this iteration:
   - What issue(s) were addressed
   - How each issue was resolved

6. **[BLOCKING — do not proceed until complete]** Wait for the new Copilot review to complete using a subagent with the cheapest available model (e.g. **"GPT-5.4 mini (copilot)"**). That subagent should poll the review status every ~30 seconds and return only a single line per poll (`pending` or `done: N comments`), outputting "Waiting for Copilot review to complete... (Xs elapsed)" after each poll until the review is done. It must not re-fetch or print the full PR state. Do NOT move to step 7 or begin the next iteration until this subagent returns `done`.

7. If the new Copilot review has no remaining comments, exit the loop. Otherwise, begin the next iteration (unless ${input:maxIterations:5} iterations have already run).

## Final Report

After all iterations are complete, report:
- Total number of iterations completed
- Total number of issues addressed
- Number of Copilot review comments found in the last iteration (this should be 0 if the loop ended because the reviewer had nothing to comment on)
