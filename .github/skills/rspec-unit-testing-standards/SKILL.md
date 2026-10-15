---
name: rspec-unit-testing-standards
description: 'Rules for RSpec unit specs in ruby-git, on top of the rspec-base-standards skill: the examples a constructor earns, requiring only the spec helper and the file under test, keeping setup in the file, stubbing every non-trivial collaborator, the 100% line and branch coverage gate run by rake spec:unit, determinism, leaving process and global state alone, and testing mixins and module functions. Use when writing, reviewing, or auditing RSpec specs under spec/unit/, or deciding what a unit spec may stub.'
---

# RSpec unit testing standards

The rules for unit specs live in the `rspec-unit-testing-standards` skill of the
`jcouball-testing` plugin, which loads its `rspec-base-standards` skill first. This
file holds only what is specific to ruby-git, so fixes to the rules land once, in the
plugin, instead of drifting between two full copies. ruby-git's changes to the
conventions every spec follows are in its
[RSpec base standards](../rspec-base-standards/SKILL.md) file.

## Contents

- [How to use this skill](#how-to-use-this-skill)
- [Changes and additions for ruby-git](#changes-and-additions-for-ruby-git)
- [Related skills](#related-skills)

## How to use this skill

Invoke `/jcouball-testing:rspec-unit-testing-standards` and apply the changes below
throughout its workflow. If you arrived here because that skill told you to read this
file, do not invoke it again — its rules are already in context; apply the changes
below and continue.

If the plugin is not installed, install it first:

```bash
claude plugin marketplace add jcouball/agent-plugins
claude plugin install jcouball-testing@jcouball
```

In an agent that cannot install or invoke Claude Code plugins, read
[the unit skill](https://github.com/jcouball/agent-plugins/blob/testing-v0.2.1/plugins/testing/skills/rspec-unit-testing-standards/SKILL.md)
and [the base skill](https://github.com/jcouball/agent-plugins/blob/testing-v0.2.1/plugins/testing/skills/rspec-base-standards/SKILL.md)
directly from the plugin source and apply the same changes on top, with the
[RSpec base standards](../rspec-base-standards/SKILL.md) file's changes applied to the
base skill. In Copilot Chat, attach this file, that base standards file, and the two
plugin sources to your context and proceed the same way.

These changes were written against version 0.2.1 of the `jcouball-testing` plugin,
which the links above point to. When the plugin is upgraded, check each change below
against the new rules, then move the links to the new version.

## Changes and additions for ruby-git

- **The coverage run.** `bundle exec rake spec:unit` is the command that the coverage
  check in the plugin's Verification section, and its "What the tools check" section,
  leave to the project override. A full run fails below 100% line or branch coverage,
  and CI fails the pull request with it. How to read a focused run, and the one kind of
  branch that the rule on unit specs covering every line and branch lets a coverage
  directive exclude, are in the [Test coverage
  policy](../../../CONTRIBUTING.md#test-coverage-policy) in `CONTRIBUTING.md`.
- **Class families.** `Git::Commands::*` specs also follow the [Command test
  conventions](../command-test-conventions/SKILL.md), and `Git::Repository` module specs
  follow the [Facade test conventions](../facade-test-conventions/SKILL.md). Those are
  the class-family conventions the plugin's Step 0 refers to. Where one departs from a
  plugin rule, the convention wins, in either direction, whether or not it names the
  rule it departs from. It may prescribe what a plugin rule forbids, such as a fixed
  section at the end of `#call` or an example the conventions require. It may also
  forbid what a plugin rule permits, such as the command conventions' rule against using
  another command class in a spec. A review of such a spec produces the plugin's
  per-rule table first, then the class-family skill's own output for its conventions.

## Related skills

- [RSpec base standards](../rspec-base-standards/SKILL.md) — ruby-git's changes to the
  conventions every spec follows
- [RSpec integration testing standards](../rspec-integration-testing-standards/SKILL.md)
  — the rules for specs under `spec/integration/`
- [Command test conventions](../command-test-conventions/SKILL.md) and
  [Facade test conventions](../facade-test-conventions/SKILL.md) — the class-family
  conventions built on these rules
- [Testing guide](../testing-guide/SKILL.md) — the vocabulary these rules are written
  in and the reasoning behind them
- [Development workflow](../development-workflow/SKILL.md) — the TDD process that
  governs when and how tests are written
- [PR readiness review](../pr-readiness-review/SKILL.md) — the final check of test
  compliance before a pull request opens
