---
name: testing-guide
description: 'Points at the testing guide, the reference that defines the vocabulary for talking about tests, classifies them on six dimensions, and says how to choose which kind to write, with sections mapping it to Ruby, RSpec, and Rails. Load only when asked why a testing rule exists, what a test term means, how to classify or name a test, or when writing or reviewing a testing skill or standard. Do not load it for ordinary test writing; the standards skills are self-sufficient for that.'
---

# Testing guide

The testing guide defines the vocabulary the testing skills in this repository are
written in and explains why their rules exist. The guide lives in the
`jcouball-testing` plugin, and the `testing-guide` skill there says when to read it
and which section answers which question. This file holds only what is specific to
ruby-git, so the guide has one copy and this project keeps only its differences.

## Contents

- [How to use this skill](#how-to-use-this-skill)
- [Changes and additions for ruby-git](#changes-and-additions-for-ruby-git)
- [Related skills](#related-skills)

## How to use this skill

Invoke `/jcouball-testing:testing-guide` and apply the changes below throughout
its workflow. If you arrived here because that skill told you to read this file,
do not invoke it again — it is already in context; apply the changes below and
continue.

If the plugin is not installed, install it first:

```bash
claude plugin marketplace add jcouball/agent-plugins
claude plugin install jcouball-testing@jcouball
```

In an agent that cannot install or invoke Claude Code plugins, read
[the guide](https://github.com/jcouball/agent-plugins/blob/main/plugins/testing/docs/testing-guide.md)
and [the skill](https://github.com/jcouball/agent-plugins/blob/main/plugins/testing/skills/testing-guide/SKILL.md)
from the plugin source and apply the same changes on top. In Copilot Chat, attach
this file and those two to your context and proceed the same way.

## Changes and additions for ruby-git

- **What derives from the guide.** The guide is the source the
  [RSpec base standards](../rspec-base-standards/SKILL.md),
  [RSpec unit testing standards](../rspec-unit-testing-standards/SKILL.md), and
  [RSpec integration testing standards](../rspec-integration-testing-standards/SKILL.md)
  skills derive their rules from. They state what every spec, and a spec under
  `spec/unit/` or `spec/integration/`, MUST and SHOULD do so that a reviewer can
  enforce it. The guide explains the terms those rules are written in and why the
  rules exist. When the guide and one of those skills disagree, either the guide is
  wrong or the rule is out of date, and the fix is to change one of them, not to work
  around the gap.
- **When it runs.** The default rake task runs the whole unit and integration suite
  on every change, so every test in the repository has that value on the
  when-it-runs dimension.
- **Unit test school.** The guide's default, solitary. The unit standards skill's
  stubbing rules assume it.
- **Scope of the standards.** The base standards hold for every spec, including one
  top-level `describe` per file naming its subject and a spec path that follows from the
  subject. The unit standards add the rules that hold only for a unit spec under
  `spec/unit/`: requiring only the spec helper and the file under test, stubbing every
  non-trivial collaborator, strict determinism, leaving process state alone, and the
  100% line and branch coverage gate, which the unit suite alone measures. The
  integration standards say what each of those becomes once a test runs real
  collaborators.
- **Integration tests.** They live under `spec/integration/` and follow the [RSpec
  integration testing standards](../rspec-integration-testing-standards/SKILL.md), plus
  the [Command test conventions](../command-test-conventions/SKILL.md) or [Facade test
  conventions](../facade-test-conventions/SKILL.md) for their class family. This project
  has no separate system test layer; the integration suite covers that ground.
- **Rails.** The Rails spec types do not apply. This is not a Rails application.

## Related skills

- [RSpec Unit Testing Standards](../rspec-unit-testing-standards/SKILL.md) — the
  rules for `spec/unit/`, derived from the guide
- [RSpec Integration Testing
  Standards](../rspec-integration-testing-standards/SKILL.md) — the rules for
  `spec/integration/`, derived from the guide
- [Command Test Conventions](../command-test-conventions/SKILL.md) — conventions
  for `Git::Commands::*` unit and integration specs
- [Facade Test Conventions](../facade-test-conventions/SKILL.md) — conventions
  for `Git::Repository` module specs
- [Test Debugging](../test-debugging/SKILL.md) — diagnosing flaky, order-dependent,
  and failing tests
