---
name: breaking-change-analysis
description: "Assesses the impact of API changes before implementation to understand what code would break and plan appropriate migration paths. Use when removing methods, changing interfaces, or planning deprecations."
---

# Breaking Change Analysis Workflow

Assess the impact of API changes before implementation. Use when removing methods,
changing method signatures, altering return types/values, changing exception types,
or modifying default behavior.

## Contents

- [How to use this skill](#how-to-use-this-skill)
- [Related skills](#related-skills)
- [Step 1: Identify the Change Scope](#step-1-identify-the-change-scope)
- [Step 2: Find All Usages](#step-2-find-all-usages)
- [Step 3: Assess and Document Impact](#step-3-assess-and-document-impact)
- [Step 4: Plan Migration Path](#step-4-plan-migration-path)

## How to use this skill

Attach this file to your Copilot Chat context, then invoke it with the specific
API/method change you are considering. Use this workflow before coding to assess
impact and plan migration.

## Related skills

- [Development Workflow](../development-workflow/SKILL.md) — implement required
   changes using strict TDD

## Step 1: Identify the Change Scope

1. Determine which classes and methods are affected.
2. Check API visibility (`@api public` vs `@api private` in YARD docs).
3. Check if the change affects `Git::Repository` (the current facade layer, modules under `lib/git/repository/`).

## Step 2: Find All Usages

1. **Internal usages:**

   ```bash
   grep -rn "method_name" lib/ spec/
   ```

2. **External usage (if applicable):**

   ```bash
   gh search code "Git::Repository#method_name language:ruby"
   ```

3. **Downstream gems:** `reverse-dependencies.sql` in this directory lists every gem
   that depends on `git`, one row per gem, showing only its most recent version.

   Code search finds call sites; this finds the projects that would have to react to a
   release. Each row gives the dependent gem's name, its latest version and release
   date, the version requirement it declares against `git`, and its source or homepage
   URL. The results are ordered newest release first, so gems still under active
   maintenance — the ones a deprecation notice can actually reach — sort to the top.

   The `WHERE` clause selects the requirements that a new major would affect: `~> 4.%`
   pins, which stop receiving updates, and open-ended `>= ` requirements, which pick up
   the new major immediately whether or not the gem is ready for it. **Edit those
   patterns to match the series you are changing** — they are pinned to the v4.x
   analysis they were written for.

   Run it against a restored copy of the public RubyGems.org database dump
   (<https://rubygems.org/pages/data>); the table names are that schema's.

## Step 3: Assess and Document Impact

Produce an impact assessment:

```markdown
## Breaking Change Impact Assessment

### Change Description
[What is being changed]

### Affected API
- Class: `Git::SomeClass`
- Method: `#some_method`
- Current signature: `def some_method(arg, opts = {})`
- Proposed signature: `def some_method(arg, force: false)`

### Internal Impact
- Files affected: X
- Tests to update: Y

### External Impact
- Severity: [High/Medium/Low]
- Migration difficulty: [Easy/Medium/Hard]

### Migration Path
[How users should update their code]
```

## Step 4: Plan Migration Path

**Project versioning policy:**
- Breaking changes are batched for major releases
- Use deprecation warnings in the current major series before removal in the next major release

**Deprecation approach:**

```ruby
# @deprecated Use {#new_method} instead. Will be removed in the next major release.
def old_method(*args)
  warn "[DEPRECATION] `old_method` is deprecated. Use `new_method` instead."
  new_method(*args)
end
```

**Documentation requirements:**
- Add `@deprecated` YARD tag with migration guidance
- Mark commits with `!` for breaking changes and include `BREAKING CHANGE:` footer
- DO NOT update CHANGELOG.md — it is auto-generated from commit messages
