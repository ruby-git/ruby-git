---
name: command-implementation
description: "Scaffolds new and reviews existing Git::Commands::* classes with unit tests, integration tests, and YARD docs using the Base architecture. Use when creating a new command from scratch, updating an existing command, or reviewing a command class for correctness."
---

# Command Implementation

Scaffold new and review existing `Git::Commands::Base` command classes, unit tests,
integration tests, and YARD docs.

## Contents

- [Contents](#contents)
- [Related skills](#related-skills)
- [Input](#input)
  - [Command source code](#command-source-code)
  - [Command test code](#command-test-code)
  - [Git documentation for the git command](#git-documentation-for-the-git-command)
- [Reference](#reference)
- [Workflow](#workflow)
- [Output](#output)

## Related skills

Additional related skills:

- [Review Arguments DSL](../review-arguments-dsl/SKILL.md) — verify every DSL entry
  is correct and complete
- [Command YARD Documentation](../command-yard-documentation/SKILL.md) — verify
  documentation completeness and formatting
- [RSpec Unit Testing Standards](../rspec-unit-testing-standards/SKILL.md) — baseline
  RSpec rules all generated unit specs must comply with
- [Command Test Conventions](../command-test-conventions/SKILL.md) — conventions for
  writing and reviewing unit and integration tests for command classes
- [Review Cross-Command Consistency](../review-cross-command-consistency/SKILL.md) —
  sibling consistency within a command family

## Input

The user provides the target `Git::Commands::*` class name and the git subcommand (or
subcommand + sub-action) it wraps. The agent gathers the following.

### Command source code

Read the command class from `lib/git/commands/{command}.rb` or, for subcommands,
`lib/git/commands/{command}/{subcommand}.rb`. For subcommands, also read the
namespace module at `lib/git/commands/{command}.rb` which lists all sibling
subcommands and provides the module-level documentation.

Skip this step when scaffolding a new command (the file does not exist yet).

### Command test code

Read unit tests matching `spec/unit/git/commands/{command}/**/*_spec.rb`. Use these as
supplemental evidence when tracing the verification chain (Ruby call → bound
argument → expected git CLI). Coverage completeness is assessed by the
[Command Test Conventions](../command-test-conventions/SKILL.md) skill.

Skip this step when scaffolding a new command (the file does not exist yet).

### Git documentation for the git command

- **Latest-version online command documentation**

  Read the **entire** official git documentation online man page for the command
  for the latest version of git. This version will be used as the primary
  authority for DSL completeness, including the options to include in the
  DSL, argument names, aliases, ordering, etc.
  Fetch this version from the URL `https://git-scm.com/docs/git-{command}`
  (this URL always serves the latest release).

- **Minimum-version online command documentation**

  Read the **entire** official git documentation online man page for the command for
  the `Git::MINIMUM_GIT_VERSION` version of git. This will be used only for
  command-introduction and `requires_git_version` decisions. Fetch this version from
  URL `https://git-scm.com/docs/git-{command}/{version}`.

Do **not** scaffold from local `git <command> -h` output — the installed Git
version is unknown and may differ from the latest supported version. Local help may
be used as a supplemental check only.

## Reference

See [REFERENCE.md](REFERENCE.md) for the full reference covering:

- Files to generate
- Single class vs. sub-command namespace (when to split, naming, templates)
- Architecture contract and structural requirements
- Command template (Base pattern)
- `#call` override guidance (when to override, stdin feeding, action-option patterns)
- `Base#with_stdin` mechanics
- Options completeness (version conventions, execution-model conflicts)
- `end_of_options` placement rules
- Exit status guidance
- Facade delegation and policy options
- Internal compatibility contract
- Phased rollout requirements
- Common failures

Subagents load REFERENCE.md directly during the workflow steps that need it.

## Workflow

This skill supports three modes. Determine which mode applies before starting:

- **Scaffold** — creating a new command class from scratch. Follow all steps.
- **Update** — adding options to an existing command class: skip steps 2, 3a, 3b,
  and 3c (the class and test files already exist). Start from step 1, then proceed
  directly to 3d → 3e → 3f → 4 → 5.
- **Review** — auditing an existing command class for correctness (no changes).
  Follow all steps but produce findings instead of code.

1. **Gather input** — collect the target class name and git subcommand from
   the [Input](#input), then fetch the latest-version and minimum-version
   git documentation per [Git documentation for the git
   command](#git-documentation-for-the-git-command).

2. **Determine class structure** *(scaffold mode only)* — decide between a single
   class and a sub-command namespace per [Single class vs. sub-command
   namespace](REFERENCE.md#single-class-vs-sub-command-namespace).

3. **For each command / sub-command class**, repeat steps 3a–3f:

   a. **Scaffold the command class (subagent)** *(scaffold mode only)* — delegate
      to a subagent: load [REFERENCE.md](REFERENCE.md) and the
      [YARD Documentation](../yard-documentation/SKILL.md) skill, then generate
      `lib/git/commands/{command}.rb` using the [Command
      template](REFERENCE.md#command-template-base-pattern). Populate the
      `arguments do` block with all options from the latest-version docs per
      [Options completeness](REFERENCE.md#options-completeness--consult-the-latest-version-docs-first),
      applying the [Execution-model conflicts](REFERENCE.md#execution-model-conflicts),
      [`end_of_options` placement](REFERENCE.md#end_of_options-placement), and
      [Exit status guidance](REFERENCE.md#exit-status-guidance) rules. Pass the
      fetched git documentation to the subagent.

   Steps 3b and 3c may run **in parallel** (they produce independent files).

   b. **Scaffold unit tests (subagent)** *(scaffold mode only)* — delegate to a
      subagent: load **[Command Test
      Conventions](../command-test-conventions/SKILL.md)** (which loads [RSpec Unit
      Testing Standards](../rspec-unit-testing-standards/SKILL.md)), then generate
      `spec/unit/git/commands/{command}_spec.rb` following the unit test
      conventions. Fix all findings, then repeat the review until clean.

   c. **Scaffold integration tests (subagent)** *(scaffold mode only)* — delegate
      to a subagent: load **[Command Test
      Conventions](../command-test-conventions/SKILL.md)**, then generate
      `spec/integration/git/commands/{command}_spec.rb` following the integration
      test conventions. Fix all findings, then repeat the review until clean.

   d. **Review Arguments DSL (subagent)** — delegate to a subagent: load and
      apply **[Review Arguments DSL](../review-arguments-dsl/SKILL.md)** (and its
      [CHECKLIST.md](../review-arguments-dsl/CHECKLIST.md)) against the
      `arguments do` block. Fix all findings, then repeat the review until clean.
      **Complete this step before starting steps 3e–3f** — DSL corrections change
      the CLI arguments that tests and YARD docs must reflect.

   Steps 3e and 3f may run **in parallel** (they review independent file sets).

   e. **Review Command Tests (subagent)** — delegate to a subagent: load and
      apply **[Command Test Conventions](../command-test-conventions/SKILL.md)** against
      the unit and integration spec files. Fix all findings, then repeat the
      review until clean.

   f. **Review YARD Documentation (subagent)** — delegate to a subagent: load
      and apply **[Command YARD Documentation](../command-yard-documentation/SKILL.md)**
      against the command class. Fix all findings, then repeat the review until
      clean.

4. **Review class shape and declarations** — load
   [REFERENCE.md](REFERENCE.md) and verify against the
   [Architecture contract](REFERENCE.md#architecture-contract), [`#call` override
   guidance](REFERENCE.md#call-override-guidance), [Exit status
   guidance](REFERENCE.md#exit-status-guidance), [`requires_git_version`
   convention](REFERENCE.md#requires_git_version-convention), [Internal compatibility
   contract](REFERENCE.md#internal-compatibility-contract), and [Common
   failures](REFERENCE.md#common-failures). Additionally:

   - For **scaffold** and **update** modes: write or update the
     `Git::Lib` method per [Facade delegation and policy
     options](REFERENCE.md#facade-delegation-and-policy-options).
   - For **migration PRs**: verify [Phased rollout
     requirements](REFERENCE.md#phased-rollout-requirements).

5. **Run quality gates** — discover the prerequisite tasks for
   `default:parallel` and run them sequentially, fixing failures before
   advancing:

   ```bash
   bundle exec ruby -e "require 'rake'; load 'Rakefile'; puts Rake::Task['default:parallel'].prerequisites"
   ```

   Run each listed task in order via `bundle exec rake <task>`. On failure, fix
   the issue and re-run that task. Once it passes, continue to the next. After
   all tasks pass, re-run the full sequence from the first task to confirm no
   fix broke an earlier gate. Repeat until the whole sequence runs without error.

## Output

For **scaffold** and **update** modes, produce:

1. **Command class** — `lib/git/commands/{command}.rb` (and optionally the namespace
   module file for the first command in a namespace)
2. **Unit tests** — `spec/unit/git/commands/{command}_spec.rb`
3. **Integration tests** — `spec/integration/git/commands/{command}_spec.rb`
4. **Facade delegation** — updated `Git::Lib` method in `lib/git/lib.rb`
5. **All quality gates pass** — rspec, minitest, rubocop, and yard all green

For **review** mode, produce:

| Check | Status | Issue |
| --- | --- | --- |
| Base inheritance | Pass/Fail | ... |
| arguments DSL | Pass/Fail | ... |
| call shim | Pass/Fail | ... |
| allow_exit_status usage | Pass/Fail | ... |
| requires_git_version | Pass/Fail | ... |
| output parsing absent | Pass/Fail | ... |
| compatibility contract | Pass/Fail | ... |

Then list required fixes and indicate whether the migration slice is safe to merge
under phased-rollout rules.
