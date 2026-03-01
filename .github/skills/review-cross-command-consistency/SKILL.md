---
name: review-cross-command-consistency
description: "Compares sibling command classes for consistent structure, documentation, testing, and exit-status conventions under the Base architecture. Use for cross-command audits."
---

# Review Cross-Command Consistency

Review sibling command classes (same module/family) for consistent structure,
documentation, testing, and exit-status conventions under the `Base` architecture.

## Contents

- [How to use this skill](#how-to-use-this-skill)
- [Related skills](#related-skills)
- [What to Check](#what-to-check)
  - [1. Class structure consistency](#1-class-structure-consistency)
  - [2. Arguments DSL consistency](#2-arguments-dsl-consistency)
  - [3. Exit-status consistency](#3-exit-status-consistency)
  - [4. YARD consistency](#4-yard-consistency)
  - [5. Unit spec consistency](#5-unit-spec-consistency)
  - [6. Integration spec consistency](#6-integration-spec-consistency)
  - [7. Migration process consistency](#7-migration-process-consistency)
- [Output](#output)

## How to use this skill

Attach this file to your Copilot Chat context, then invoke it with the sibling
command files (same module/family) to compare. Examples:

```text
Using the Review Cross-Command Consistency skill, review the
Git::Commands::Diff family: lib/git/commands/diff/patch.rb,
lib/git/commands/diff/numstat.rb, lib/git/commands/diff/raw.rb.
```

```text
Review Cross-Command Consistency: all files under lib/git/commands/stash/
```

The invocation needs two or more sibling command files from the same family.

## Related skills

- [Review Command Implementation](../review-command-implementation/SKILL.md) — canonical class-shape checklist, phased
  rollout gates, and internal compatibility contracts
- [Review Arguments DSL](../review-arguments-dsl/SKILL.md) — verifying DSL entries match git CLI
- [Review Command Tests](../review-command-tests/SKILL.md) — unit/integration test expectations for command classes
- [Review Command YARD Documentation](../review-command-yard-documentation/SKILL.md) — documentation completeness for command classes

## What to Check

### 1. Class structure consistency

- [ ] all classes use `class < Git::Commands::Base`
- [ ] all require `git/commands/base`
- [ ] all use `arguments do ... end` (no legacy `ARGS =` constants)
- [ ] all use YARD directive `# @!method call(*, **)` with nested `@overload` blocks
- [ ] all use YARD shim `def call(...) = super # rubocop:disable Lint/UselessMethodDefinition`, OR have a legitimate `call` override (stdin protocol, input validation, non-trivial option routing) — not both
- [ ] commands with `call` overrides use `Base#with_stdin` for stdin feeding and delegate exit-status validation to `validate_exit_status!`

### 2. Arguments DSL consistency

- [ ] shared options use same alias/modifier patterns
- [ ] shared entries appear in same relative order
- [ ] command-specific differences are intentional and documented

### 3. Exit-status consistency

- [ ] siblings with same git exit semantics use same `allow_exit_status` range
- [ ] rationale comments are present and consistent in tone
- [ ] commands without non-zero successful exits do not declare custom ranges

### 4. YARD consistency

- [ ] consistent class summaries and `@api private`
- [ ] `@overload` coverage consistent for equivalent call shapes
- [ ] `@return` and `@raise` wording consistent across siblings

### 5. Unit spec consistency

- [ ] expectations include `raise_on_failure: false` where command invocation is asserted
- [ ] similar option paths use similar context naming
- [ ] exit-status tests are parallel where ranges are shared

### 6. Integration spec consistency

- [ ] success/failure grouping uses same structure
- [ ] no output-format assertions (smoke + error handling only)

### 7. Migration process consistency

See **Review Command Implementation § Phased rollout / rollback requirements** for
the canonical checklist. During a cross-command audit, verify that sibling commands
were migrated in the same slice and that the same quality gates were applied.

## Output

1. Summary table:

   | Aspect | File A | File B | File C | Status |
   | --- | --- | --- | --- | --- |

2. Inconsistency list with canonical recommendation:

   | Issue | Files | Recommended canonical form |
   | --- | --- | --- |

> **Branch workflow:** Implement any fixes on a feature branch. Never commit or
> push directly to `main` — open a pull request when changes are ready to merge.
