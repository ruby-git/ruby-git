---
name: tdd-refactor-step
description: 'Guides the REFACTOR step of the TDD cycle — identifying code smells, applying safe refactoring techniques, cleaning test code, and verifying with rubocop. Use during RED-GREEN-REFACTOR when deciding what and how to refactor after making a test pass.'
---

# TDD Refactor Step

Concrete guidance for the REFACTOR step of the RED-GREEN-REFACTOR cycle. Covers
code smells to look for, safe refactoring techniques, test code cleanup,
rubocop integration, and verification.

## Contents

- [How to use this skill](#how-to-use-this-skill)
- [Related skills](#related-skills)
- [Decision: refactor or skip](#decision-refactor-or-skip)
- [Code smells checklist](#code-smells-checklist)
- [Refactoring techniques](#refactoring-techniques)
- [Test code refactoring](#test-code-refactoring)
- [Rubocop integration](#rubocop-integration)
- [Verification](#verification)
- [Project-specific patterns](#project-specific-patterns)
- [Boundaries](#boundaries)

## How to use this skill

Invoke this skill during the REFACTOR step of the TDD cycle, after GREEN
(all tests pass). This skill expands the guidance in the
[Development Workflow](../development-workflow/SKILL.md) REFACTOR step.

Typical invocation:

```text
I just got to green. Walk me through the REFACTOR step using
the TDD Refactor Step skill.
```

## Related skills

- [Development Workflow](../development-workflow/SKILL.md) — parent TDD workflow;
  this skill supplements its REFACTOR step
- [RSpec Unit Testing Standards](../rspec-unit-testing-standards/SKILL.md) — test
  conventions that refactored tests must follow
- [PR Readiness Review](../pr-readiness-review/SKILL.md) — final quality gate
  that catches remaining quality issues

## Decision: refactor or skip

Not every GREEN step needs refactoring. Skip when **all** of the following are true:

- No hardcoded values from the GREEN step remain
- No duplication was introduced between new and existing code
- No method exceeds ~10 lines
- No parameter list exceeds 3 positional parameters
- Rubocop reports no new offenses on changed files
- Test setup is not duplicated across examples

If any condition is false, proceed with the relevant technique below.

## Code smells checklist

Check the code written or modified in this task for these smells, in priority order:

| # | Smell | Threshold | Action |
|---|-------|-----------|--------|
| 1 | **Hardcoded values** from GREEN step | Any | Generalize to actual logic |
| 2 | **Duplication** between new code and existing code | ≥ 3 similar lines | Extract shared method or constant |
| 3 | **Long method** | > 10 lines (body) | Extract private helper |
| 4 | **Long parameter list** | > 3 positional params | Convert trailing params to keyword arguments |
| 5 | **Inconsistent naming** | Deviates from file/module conventions | Rename to match existing patterns |
| 6 | **Deeply nested conditionals** | > 2 levels | Extract guard clause or helper |
| 7 | **Feature envy** | Method uses another object's data more than its own | Move method or extract delegator |
| 8 | **Dead code** | Unreachable branches, unused variables | Remove |

Limit yourself to smells **in files you touched this task**. Broader cleanup belongs
in a separate task (add it during REPLAN).

## Refactoring techniques

Apply the simplest technique that resolves the smell:

### Extract method

Split a long method into a public method and one or more private helpers. Name
the helper after **what** it does, not **how**:

```ruby
# Before
def call(*, **)
  bound = args_definition.bind(*, **)
  objects = Array(bound.objects).map { |o| "#{o}\n" }.join
  with_stdin(objects) { |r| run_batch(bound, r) }
end

# After
def call(*, **)
  bound = args_definition.bind(*, **)
  with_stdin(stdin_content(bound)) { |r| run_batch(bound, r) }
end

private

def stdin_content(bound)
  Array(bound.objects).map { |o| "#{o}\n" }.join
end
```

### Convert positional to keyword arguments

When a method accumulates optional trailing positional parameters:

```ruby
# Before
def initialize(args, options, positionals, exec_names = [], flags = [])

# After
def initialize(args, options, positionals, exec_names: [], flags: [])
```

Update the single call site at the same time.

### Replace conditional with guard clause

```ruby
# Before
def validate(value)
  if value
    if value.is_a?(String)
      process(value)
    end
  end
end

# After
def validate(value)
  return unless value
  return unless value.is_a?(String)

  process(value)
end
```

### Introduce constant

When a magic value appears in logic:

```ruby
# Before
raise error if version < Gem::Version.new('2.28.0')

# After
MINIMUM_GIT_VERSION = Gem::Version.new('2.28.0').freeze
raise error if version < MINIMUM_GIT_VERSION
```

### Eliminate duplication with shared setup

When two methods share identical preamble or teardown, extract the shared part.
If the duplication is in tests, see Test Code Refactoring below.

## Test code refactoring

Test code deserves the same refactoring attention as production code:

| Smell | Technique |
|-------|-----------|
| Duplicated `let`/`before` across contexts | Move to nearest shared `describe` or `context` |
| Long example bodies (> 5 lines of setup) | Extract to `let` declarations or `before` block |
| Repeated literal values | Extract to `let` or constant at top of file |
| Identical examples across files | Extract to shared example group (`shared_examples`) |
| Unclear example descriptions | Rewrite to state expected behavior, not implementation |

Follow the [RSpec Unit Testing Standards](../rspec-unit-testing-standards/SKILL.md)
for the resulting test structure.

## Rubocop integration

Run rubocop on changed files after refactoring:

```bash
bundle exec rubocop $(git diff --name-only HEAD)
```

Focus on:
- `Metrics/MethodLength` — methods over the configured limit
- `Metrics/ParameterLists` — too many parameters
- `Metrics/AbcSize` — complexity threshold
- `Style` cops — naming, formatting consistency

Auto-correct safe offenses when appropriate:

```bash
bundle exec rubocop -a $(git diff --name-only HEAD)
```

Do not auto-correct `Metrics` cops — those require structural changes (extract
method, split class), not formatting fixes.

## Verification

After refactoring, confirm:

1. **Tests still pass:** `bundle exec rspec <spec_file>` for the current task's
   test file(s)
2. **No new rubocop offenses:** `bundle exec rubocop $(git diff --name-only HEAD)`
3. **Behavior unchanged:** No new test was added during REFACTOR — if you need
   a new test, you skipped a RED step

If any test fails after refactoring, the refactoring changed behavior. Revert
and try a smaller change.

## Project-specific patterns

Patterns specific to this codebase that the REFACTOR step should enforce:

- **Command classes** should not contain parsing logic — if refactoring reveals
  parsing in a command class, flag it for extraction (separate task)
- **Arguments DSL** `Bound` metadata uses keyword arguments — if adding new
  metadata fields, follow the keyword argument pattern
- **Error classes** inherit from `Git::Error` — ensure new errors follow the
  hierarchy in `lib/git/errors.rb`
- **`freeze` constants** — all new constants should be frozen
  (`CONSTANT = value.freeze`)
- **Private methods** go below a single `private` keyword, not inline
  `private def`

## Boundaries

Things the REFACTOR step must **not** do:

- **Add new behavior** — no new features, no new test cases
- **Change public API** — method signatures visible to users stay the same
- **Touch unrelated files** — scope to files modified in this task; add broader
  refactoring to the task list during REPLAN
- **Optimize prematurely** — clarity over performance unless profiling data exists
- **Over-abstract** — do not create a helper for something used exactly once
