---
name: test-debugging
description: 'Diagnoses a failing or flaky RSpec test, finds the root cause, reports it, and applies the right kind of fix. Use when a test fails consistently, fails intermittently, passes alone but fails in the suite, passes locally but fails elsewhere, fails the unit coverage gate, or when asked to debug, diagnose, or fix a test.'
---

# Test debugging

Works a failing or flaky test from reproduction to a verified fix. The workflow lives
in the `test-debugging` skill of the `jcouball-testing` plugin. This file holds only
what is specific to ruby-git, so fixes to the workflow land once, in the plugin,
instead of drifting between two full copies.

## Contents

- [How to use this skill](#how-to-use-this-skill)
- [Changes and additions for ruby-git](#changes-and-additions-for-ruby-git)
- [Related skills](#related-skills)

## How to use this skill

Invoke `/jcouball-testing:test-debugging` and apply the changes below throughout its
workflow. If you arrived here because that skill told you to read this file, do not
invoke it again — its workflow is already in context; apply the changes below and
continue.

If the plugin is not installed, install it first:

```bash
claude plugin marketplace add jcouball/agent-plugins
claude plugin install jcouball-testing@jcouball
```

In an agent that cannot install or invoke Claude Code plugins, read the workflow
directly from
[the plugin source](https://github.com/jcouball/agent-plugins/blob/main/plugins/testing/skills/test-debugging/SKILL.md)
and apply the same changes on top. In Copilot Chat, attach this file and the plugin
source to your context and proceed the same way.

## Changes and additions for ruby-git

- **The commands.** One example: `bundle exec rspec spec/unit/git/<path>_spec.rb:42`,
  or the same under `spec/integration/`. The unit suite is
  `bundle exec rake spec:unit`, which runs serially and takes about 90 seconds. The
  integration suite is `bundle exec rake spec:integration`, which runs in parallel
  through `parallel_rspec` unless `PARALLEL_TESTS=false` is set; that is the project's
  parallel command. `bundle exec rake spec` runs both. Wherever the workflow says "the
  whole suite", run the suite the failing example belongs to. Its command blocks run
  the whole suite as `bundle exec rspec` with `--order` or `--seed`; run the suite
  command instead and pass the option through `SPEC_OPTS`, such as
  `SPEC_OPTS='--order defined' bundle exec rake spec:unit`. RSpec reads `SPEC_OPTS`
  from the environment in every process, each `parallel_rspec` worker included, so the
  rake tasks need not forward it. The spec helper already sets random order, so
  `--order rand` needs no option. That swap covers whole-suite runs only. Replay a
  reported seed in one process, with exactly the files the reported run loaded:
  `bundle exec rspec --seed 12345 <files>`. `rake spec:integration` would spread those
  files across `parallel_rspec` workers, which can separate the example that changed
  the state from the one that failed and make the failure look CI-only.
- **"Run the whole suite once more".** The unit suite has no parallel command, so it
  is serial-only: after an order-dependence fix to a unit spec, the workflow's
  serial-only skip covers the unit suite, and `bundle exec rake spec:integration`
  still runs once. After any other fix, run both suites once.
- **Random-order runs.** Ten runs of the unit suite take about fifteen minutes. Run
  them in the background, as the workflow allows, rather than lowering the count.
- **Failures that depend on where they run.** The external tool the specs drive is
  the `git` binary. Check `git --version` against the minimum version the
  [Project Context](../project-context/SKILL.md) skill states. A failure reported
  from CI counts as appearing only in CI once "Run and observe" has replayed it
  locally, seed and files included, and the replay passed; only then does it go to the
  [CI/CD Troubleshooting](../ci-cd-troubleshooting/SKILL.md) skill.
- **Shared contexts, helpers, and fixtures.** Integration specs build their
  repositories with the `'in an empty repository'` shared context and the others under
  `spec/support/contexts/`, and write files with `Git::IntegrationTestHelpers` methods
  such as `write_file`. Static fixtures under `spec/support/fixtures/` serve a few
  specs that need pre-built content, such as `spec/integration/git/command_line_spec.rb`;
  a fix prefers the dynamic helpers. Clean up any state created outside them.
- **"The code is wrong and the test caught it".** Fix the code through the
  [Development Workflow](../development-workflow/SKILL.md) TDD process, with the
  failing test as its RED step.
- **An addition to "Choose the fix": the unit coverage gate.** The unit suite enforces
  100% line and branch coverage. A run whose only failure is that gate has a cause too:
  code the unit specs do not reach. Code that some behavior needs gets the missing
  examples, added through the Development Workflow TDD process; the commit type is
  `test`. Code no behavior needs, such as a branch that cannot be taken, is removed
  instead of tested; the commit type is `refactor`.
- **The standards a changed spec follows.** Unit specs follow the
  [RSpec Unit Testing Standards](../rspec-unit-testing-standards/SKILL.md). Integration
  specs also follow the [Command Test Conventions](../command-test-conventions/SKILL.md)
  or the [Facade Test Conventions](../facade-test-conventions/SKILL.md), whichever fits
  the class under test.

## Related skills

- [Development Workflow](../development-workflow/SKILL.md) — the TDD process a fix to
  production code runs through
- [CI/CD Troubleshooting](../ci-cd-troubleshooting/SKILL.md) — failures that appear
  only in CI
- [TDD Refactor Step](../tdd-refactor-step/SKILL.md) — cleaning up a test once it is
  green
- [RSpec Unit Testing Standards](../rspec-unit-testing-standards/SKILL.md) and
  [RSpec base standards](../rspec-base-standards/SKILL.md) — the rules on
  determinism, global state, and passing alone and in random order; consult when
  flakiness comes from a test design violation rather than a production bug
