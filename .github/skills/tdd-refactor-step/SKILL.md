---
name: tdd-refactor-step
description: 'Guides the refactor step of red-green-refactor: deciding whether to refactor, the code smells to look for with thresholds, the technique for each, cleaning the test code, running rubocop, and verifying nothing changed. Use after a test goes green, during the REFACTOR step of the Development Workflow, when asked what to refactor, or when reviewing the refactor step of a TDD cycle.'
---

# TDD refactor step

The REFACTOR step of the [Development Workflow](../development-workflow/SKILL.md),
after every test passes. The procedure lives in the `tdd-refactor-step` skill of the
`jcouball-testing` plugin. This file holds only what is specific to ruby-git, so fixes
to the procedure land once, in the plugin, instead of drifting between two full
copies.

## Contents

- [How to use this skill](#how-to-use-this-skill)
- [Changes and additions for ruby-git](#changes-and-additions-for-ruby-git)
- [Related skills](#related-skills)

## How to use this skill

Invoke `/jcouball-testing:tdd-refactor-step` and apply the changes below throughout
its workflow. If you arrived here because that skill told you to read this file, do
not invoke it again — its workflow is already in context; apply the changes below and
continue.

If the plugin is not installed, install it first:

```bash
claude plugin marketplace add jcouball/agent-plugins
claude plugin install jcouball-testing@jcouball
```

In an agent that cannot install or invoke Claude Code plugins, read the workflow
directly from
[the plugin source](https://github.com/jcouball/agent-plugins/blob/main/plugins/testing/skills/tdd-refactor-step/SKILL.md)
and apply the same changes on top. In Copilot Chat, attach this file and the plugin
source to your context and proceed the same way.

## Changes and additions for ruby-git

- **Green includes the coverage gate.** Before starting, run
  `bundle exec rake spec:unit`. It fails when unit line or branch coverage drops below
  100%, even with every example passing, and a failure there means the GREEN step is
  not done: return to it, and cover the unreached code with an example or remove it if
  no behavior needs it.
- **"Commit the red and green steps before starting".** Commit the task's RED-GREEN
  work as one commit before starting this step. Its type is the task's type as a
  whole, from the Development Workflow's Per-Task Commits list: `feat` for
  user-facing functionality, `fix` for a bug fix, `refactor` or `chore` for those
  tasks; the list's `test` is for a task that only adds tests. At the Development
  Workflow's COMMIT step, fold the refactor into it with `git commit --amend --no-edit`,
  so the task still ends as one commit and FINALIZE squashes as usual.
- **`base`.** `HEAD~1`, the commit before the task's RED-GREEN commit. It stays
  `HEAD~1` on the second rubocop pass, since the refactor is not committed until the
  COMMIT step.
- **"Noted for a later task".** Add it to the task list during the Development
  Workflow's REPLAN step.
- **Additions to "Code smells": this codebase's patterns.** The refactor step enforces
  these on the code the task touched:
  - A command class holds no parsing logic. Parsing found in one is flagged for
    extraction as a separate task.
  - New metadata fields on the Arguments DSL's `Bound` follow its keyword-argument
    pattern.
  - A new error class inherits from `Git::Error`, in the hierarchy in
    `lib/git/errors.rb`.
  - Every new constant is frozen, not only one the Introduce constant technique adds.
  - Private methods go below a single `private` keyword, not inline `private def`.
- **The standards refactored tests follow.** Unit specs follow the
  [RSpec Unit Testing Standards](../rspec-unit-testing-standards/SKILL.md). Integration
  specs also follow the [Command Test Conventions](../command-test-conventions/SKILL.md)
  or the [Facade Test Conventions](../facade-test-conventions/SKILL.md), whichever fits
  the class under test.

## Related skills

- [Development Workflow](../development-workflow/SKILL.md) — the TDD workflow whose
  REFACTOR step this is
- [RSpec Unit Testing Standards](../rspec-unit-testing-standards/SKILL.md) — the rules
  refactored unit specs follow
- [PR Readiness Review](../pr-readiness-review/SKILL.md) — the final quality gate
