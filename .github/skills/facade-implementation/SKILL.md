---
name: facade-implementation
description: "Scaffolds new and reviews existing Git::Repository facade methods (organized into Git::Repository::* topic modules) with unit tests, integration tests, and YARD docs. Use when adding a new facade method to Git::Repository, updating an existing facade method, choosing or creating a topic module under lib/git/repository/, or reviewing a facade method for correctness."
---

# Facade Implementation

Scaffold new and review existing facade methods on `Git::Repository`. Facade methods
live in topic modules under `lib/git/repository/<topic>.rb` (e.g.
{Git::Repository::Staging}) and are included into the `Git::Repository` class.

A facade method is the public-API entry point that orchestrates one or more
`Git::Commands::*` calls, optional argument pre-processing, and optional output
parsing into rich Ruby return values. See
[redesign/2_architecture_redesign.md §2.1](../../../redesign/2_architecture_redesign.md)
for the five facade responsibilities this layer is designed around.

## Contents

- [Related skills](#related-skills)
- [Input](#input)
  - [Existing facade source](#existing-facade-source)
  - [Existing facade tests](#existing-facade-tests)
  - [Underlying command class(es)](#underlying-command-classes)
  - [Underlying parsers (if any)](#underlying-parsers-if-any)
- [Reference](#reference)
- [Workflow](#workflow)
- [Output](#output)

## Related skills

- [Facade Test Conventions](../facade-test-conventions/SKILL.md) — unit and
  integration test conventions for facade methods (load when scaffolding or
  reviewing tests)
- [Facade YARD Documentation](../facade-yard-documentation/SKILL.md) — facade-specific
  YARD rules for module-level and method-level docs
- [Extract Facade from Base/Lib](../extract-facade-from-base-lib/SKILL.md) — when a
  new facade method is migrated from `Git::Base` or `Git::Lib`, the extraction
  workflow drives this skill in scaffold/update mode
- [Command Implementation](../command-implementation/SKILL.md) — the underlying
  `Git::Commands::*` classes a facade method calls. Scaffold any missing command
  class first.
- [YARD Documentation](../yard-documentation/SKILL.md) — baseline YARD formatting
  rules
- [RSpec Unit Testing Standards](../rspec-unit-testing-standards/SKILL.md) — baseline
  RSpec rules
- [Project Context](../project-context/SKILL.md) — three-layer architecture overview

## Input

The user provides:

1. **Method name** — the public Ruby method name (e.g. `add`, `branches_all`,
   `commit`).
2. **Git operation(s)** — which `Git::Commands::*` class(es) the method orchestrates.
   If the relevant command class does not exist yet, scaffold it first via
   [Command Implementation](../command-implementation/SKILL.md).
3. **Optional context** — the source `Git::Lib` / `Git::Base` method when migrating
   (handled by [Extract Facade from Base/Lib](../extract-facade-from-base-lib/SKILL.md)).

> **Note:** `Git::Repository` is intentionally empty during early phases of the
> redesign. Its `initialize(execution_context:)` constructor is introduced
> alongside the first facade method extraction; subsequent extractions only
> add new topic modules and `include` lines.

The agent then gathers:

### Existing facade source

Read `lib/git/repository.rb` to see the `include Git::Repository::<Topic>` lines and
which topic modules exist. List `lib/git/repository/` to see all current topic
modules and the facade methods they already define.

Skip when scaffolding into a brand-new topic module.

### Existing facade tests

Read `spec/unit/git/repository/<topic>_spec.rb` and
`spec/integration/git/repository/<topic>_spec.rb` (if present). Use as supplemental
evidence of the existing test style before extending or reviewing.

### Underlying command class(es)

Read `lib/git/commands/<command>.rb` for each command the facade method calls.
The command's `arguments do` block defines the option keys the facade may forward,
and the YARD `@!method call` block documents what each option does. The facade must
not pass option keys the command does not declare.

### Underlying parsers (if any)

Read `lib/git/parsers/<parser>.rb` for any parser the facade uses to transform
command stdout into structured data.

## Reference

See [REFERENCE.md](REFERENCE.md) for the full reference covering:

- Files to generate
- Topic module selection (existing modules + decision rules for creating a new module)
- Designing a facade method (return type, signature, body shape)
- Topic module skeleton (file layout)
- The five facade responsibilities as a checklist
- Argument pre-processing patterns (path normalization, option whitelisting via
  `Git::Repository::Internal.assert_valid_opts!` + `private_constant`,
  deprecation handling, defaults)
- Internal helpers and encapsulation (sibling `module_function` modules under
  `lib/git/repository/` instead of private methods on `Git::Repository`;
  bare-noun naming; growth path from `Internal` to responsibility-named
  modules)
- When to call multiple commands (orchestration sequences)
- When to use a parser vs. raw stdout
- When to use a result-class factory method
- Common failures (one-line delegation when orchestration is needed; leaking
  command-class types into the public API; bypassing the execution context;
  hardcoding policy options the caller cannot override)

Subagents load REFERENCE.md directly during the workflow steps that need it.

## Workflow

This skill supports three modes. Determine which mode applies before starting:

- **Scaffold** — adding a new facade method (and possibly a new topic module).
  Follow all steps.
- **Update** — modifying an existing facade method (e.g. adding a new option to
  forward). Skip step 2 (module selection); steps 3a–3c are extending existing files
  rather than creating them.
- **Review** — auditing an existing facade method (no changes). Follow all steps but
  produce findings instead of code.

1. **Gather input** — collect the method name, target git operation(s), and any
   migration source per [Input](#input). Read the underlying command class(es) and
   parser(s) the method will call.

2. **Choose the topic module** — load
   [REFERENCE.md](REFERENCE.md) and apply [Topic module
   selection](REFERENCE.md#topic-module-selection):

   - Prefer extending an existing module under `lib/git/repository/`.
   - Create a new module only when there are at least 3 related facade methods that
     do not fit any existing module.
   - New module names are inspired by (not slavishly following) the categories at
     <https://git-scm.com/docs> (Working tree, Branching, History, Sharing,
     Patching, Inspection, Configuration, etc.).

3. **For the facade method**, repeat steps 3a–3e:

   a. **Scaffold the facade method (subagent)** *(scaffold/update modes only)* —
      delegate to a subagent: load [REFERENCE.md](REFERENCE.md) and the
      [Facade YARD Documentation](../facade-yard-documentation/SKILL.md) skill,
      then create or extend `lib/git/repository/<topic>.rb` using the [Designing
      a facade method](REFERENCE.md#designing-a-facade-method) section and
      [Topic module skeleton](REFERENCE.md#topic-module-skeleton). For new topic
      modules, also add the `require` and `include` lines to
      `lib/git/repository.rb`.

   Steps 3b and 3c may run **in parallel** (they produce independent files).

   b. **Scaffold unit tests (subagent)** *(scaffold/update modes only)* — delegate
      to a subagent: load **[Facade Test
      Conventions](../facade-test-conventions/SKILL.md)** (which loads [RSpec Unit
      Testing Standards](../rspec-unit-testing-standards/SKILL.md)), then create or
      extend `spec/unit/git/repository/<topic>_spec.rb` following the unit
      conventions (stub `Git::Commands::*` and `Git::Parsers::*` via
      `instance_double`; assert delegation contracts; cover each pre-processing
      branch).

   c. **Scaffold integration tests (subagent)** *(scaffold/update modes only)* —
      delegate to a subagent: load **[Facade Test
      Conventions](../facade-test-conventions/SKILL.md)**, then create or extend
      `spec/integration/git/repository/<topic>_spec.rb` following the integration
      conventions (real git in a temp repository; assert end-to-end Ruby return
      value, not intermediate command results). Skip integration tests for true
      one-line delegators that add no orchestration on top of the underlying
      command — the command's own integration tests already cover that path.

   Steps 3d and 3e may run **in parallel** (they review independent file sets).

   d. **Review Facade Tests (subagent)** — delegate to a subagent: load and apply
      **[Facade Test Conventions](../facade-test-conventions/SKILL.md)** against the
      unit and integration spec files. Fix all findings, then repeat the review
      until clean.

   e. **Review YARD Documentation (subagent)** — delegate to a subagent: load and
      apply **[Facade YARD Documentation](../facade-yard-documentation/SKILL.md)**
      against the topic module file. Fix all findings, then repeat the review
      until clean.

4. **Review facade shape and orchestration** — load
   [REFERENCE.md](REFERENCE.md) and verify against the [Five facade
   responsibilities checklist](REFERENCE.md#the-five-facade-responsibilities-checklist),
   the [Designing a facade method](REFERENCE.md#designing-a-facade-method) section, and
   [Common failures](REFERENCE.md#common-failures). Confirm the method:

   - delegates to a `Git::Commands::*` class via `@execution_context` (never
     constructs commands with `self` or builds CLI argv directly)
   - does not return a `Git::CommandLineResult` from the public contract unless
     that is the documented return type for the entire topic module
   - whitelists forwarded options when the caller's hash is opaque
     (per-method `<METHOD>_ALLOWED_OPTS` constant +
     `Git::Repository::Internal.assert_valid_opts!(allowed, **)` — do **not**
     also `slice`; see [Option
     whitelisting](REFERENCE.md#option-whitelisting-preventing-api-expansion))
   - handles defaults and deprecations explicitly, not by relying on command
     internals

5. **Run quality gates** — discover the prerequisite tasks for `default:parallel`
   and run them sequentially, fixing failures before advancing:

   ```bash
   bundle exec ruby -e "require 'rake'; load 'Rakefile'; puts Rake::Task['default:parallel'].prerequisites"
   ```

   Run each listed task **individually** in order via `bundle exec rake <task>`
   (one task per invocation). On failure, fix the issue and re-run that same task.
   Continue until every task passes on its first attempt with no fixes needed.

## Output

For **scaffold** and **update** modes, produce:

1. **Topic module** — `lib/git/repository/<topic>.rb` (created or extended)
2. **Facade wiring** — `lib/git/repository.rb` updated with `require` and `include`
   when a new topic module was created
3. **Unit tests** — `spec/unit/git/repository/<topic>_spec.rb`
4. **Integration tests** — `spec/integration/git/repository/<topic>_spec.rb`
   (omit only for true one-line delegators)
5. **All quality gates pass** — rspec, minitest, rubocop, and yard all green

For **review** mode, produce:

| Check | Status | Issue |
| --- | --- | --- |
| Topic module placement | Pass/Fail | ... |
| Orchestration via `@execution_context` | Pass/Fail | ... |
| Argument pre-processing complete | Pass/Fail | ... |
| Option whitelisting (where required) | Pass/Fail | ... |
| Return value matches documented contract | Pass/Fail | ... |
| Parser/result-class wiring correct | Pass/Fail | ... |
| YARD docs complete | Pass/Fail | ... |
| Unit + integration coverage | Pass/Fail | ... |

Then list required fixes.
> **Branch workflow:** Implement scaffolding or updates on a feature branch.
> Never commit or push directly to `main` — open a pull request when changes
> are ready to merge.