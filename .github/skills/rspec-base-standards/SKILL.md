---
name: rspec-base-standards
description: 'Conventions every RSpec spec in ruby-git follows, unit or integration: naming the subject in `RSpec.describe`, one `describe` per method, the spec path, testing through the public interface, `context` and `it` wording, nesting, `subject` and `let`, `allow` and `expect`, verifying doubles, error assertions, edge-case placement, observable behavior, random order, the forbidden stubbing forms, no conditional logic or declared constants in a spec, and where shared contexts live. Use when writing, reviewing, or auditing any spec under spec/.'
---

# RSpec base standards

The conventions every spec follows live in the `rspec-base-standards` skill of the
`jcouball-testing` plugin. The plugin's unit, integration, and system standards load
it first. This file holds only what is specific to ruby-git, so fixes to the
conventions land once, in the plugin, instead of drifting between two full copies.

## Contents

- [How to use this skill](#how-to-use-this-skill)
- [Changes and additions for ruby-git](#changes-and-additions-for-ruby-git)
- [Related skills](#related-skills)

## How to use this skill

If you arrived here because a plugin skill told you to read this file, do not invoke
anything: that skill's rules are already in context. Apply the changes below and
continue.

If you invoked this skill yourself for a unit or integration spec, invoke the
[RSpec unit testing standards](../rspec-unit-testing-standards/SKILL.md) or the
[RSpec integration testing standards](../rspec-integration-testing-standards/SKILL.md)
instead; each loads these rules. Otherwise, invoke
`/jcouball-testing:rspec-base-standards` and apply the changes below throughout its
workflow.

If the plugin is not installed, install it first:

```bash
claude plugin marketplace add jcouball/agent-plugins
claude plugin install jcouball-testing@jcouball
```

In an agent that cannot install or invoke Claude Code plugins, read the rules
directly from
[the plugin source](https://github.com/jcouball/agent-plugins/blob/testing-v0.2.1/plugins/testing/skills/rspec-base-standards/SKILL.md)
and apply the same changes on top. In Copilot Chat, attach this file and the plugin
source to your context and proceed the same way.

These changes were written against version 0.2.1 of the `jcouball-testing` plugin,
which the link above points to. When the plugin is upgraded, check each change below
against the new rules, then move the link to the new version.

## Changes and additions for ruby-git

- **Which specs the rules bind.** Apply these rules, and those of the unit or
  integration standards, in full to every new or changed spec. An unchanged legacy
  spec may still break some of them; fixing it is incremental cleanup, not a blocker
  for the change under review. A review reports those violations separately from the
  ones the change introduced.
- **What the tools check.** ruby-git runs core RuboCop, not rubocop-rspec, so none
  of the RSpec cops that section names runs here, and every rule it lists as
  mechanical is read. `spec/spec_helper.rb` sets `config.order = :random`.
- **`context` wording.** The rule that `context` descriptions start with "when",
  "with", or "without" does not apply to the section names a class-family skill
  prescribes word for word. Use them as written in the specs those skills govern:
  - [Command test conventions](../command-test-conventions/SKILL.md):
    `'exit code handling'` and `'input validation'`
  - [Facade test conventions](../facade-test-conventions/SKILL.md):
    `'option whitelisting'`, `'deprecation handling'`, `'input validation'`, and
    `'signature compatibility'`
- **Backward-compatible alias constants.** When a class is also reachable through an
  alias constant kept for backward compatibility, a spec for the alias names the alias
  constant in `RSpec.describe` and asserts only that it is the target, with `be`. This
  is an exception to the rule on asserting observable behavior, which counts a test
  that a constant exists as no assertion: the alias is public API that a rename could
  drop. The spec for the target class covers everything else.
- **An addition: shared contexts.** The plugin has no rule on where shared contexts
  live. A spec that uses one, which in practice means an integration spec, finds it in
  `spec/support/contexts/`, in a file named for the context string, such as
  `empty_repository.rb` for `'in an empty repository'`. The context holds only `let`,
  `let!`, `before`, `after`, and the `include` of helper modules defined beside it,
  such as `Git::IntegrationTestHelpers`, with no `subject`, doubles, or
  `described_instance`, and its values come from `let`. Include it with an explicit
  `include_context 'name'`, never through metadata.

## Related skills

- [RSpec unit testing standards](../rspec-unit-testing-standards/SKILL.md) — what a
  spec under `spec/unit/` adds to these conventions
- [RSpec integration testing standards](../rspec-integration-testing-standards/SKILL.md)
  — what a spec under `spec/integration/` adds to these conventions
- [Command test conventions](../command-test-conventions/SKILL.md) — conventions for
  `Git::Commands::*` specs
- [Facade test conventions](../facade-test-conventions/SKILL.md) — conventions for
  `Git::Repository` module specs
- [Testing guide](../testing-guide/SKILL.md) — the vocabulary these rules are written
  in and the reasoning behind them
