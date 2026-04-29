---
name: extract-facade-from-base-lib
description: "Migrates a public method from Git::Base or Git::Lib to a Git::Repository facade method (under lib/git/repository/) as part of the v5.0.0 architectural redesign. Use when extracting a specific public method during the Strangler Fig migration of Git::Base / Git::Lib into Git::Repository."
---

# Extract Facade from Base/Lib

Migrate an existing public method from `Git::Base` and/or `Git::Lib` to a
`Git::Repository::*` facade method. This is the second extraction step of the
v5.0.0 redesign — it follows
[Extract Command from Lib](../extract-command-from-lib/SKILL.md), which moves
the underlying CLI invocation into a `Git::Commands::*` class.

In Phase 4 of the redesign, **both `Git::Base` and `Git::Lib` will be deleted**.
This migration moves their public surface to `Git::Repository`. Until Phase 4,
the original methods remain in place and delegate to the new facade method to
preserve backward compatibility within the migration window.

## Contents

- [How to use this skill](#how-to-use-this-skill)
- [Prerequisites](#prerequisites)
- [Related skills](#related-skills)
- [Input](#input)
- [Source patterns](#source-patterns)
- [Workflow](#workflow)
  - [Branch setup](#branch-setup)
  - [Step 1 — Identify the source pattern](#step-1--identify-the-source-pattern)
  - [Step 2 — Plan the migration and get approval](#step-2--plan-the-migration-and-get-approval)
  - [Step 3 — Ensure adequate legacy tests](#step-3--ensure-adequate-legacy-tests)
  - [Step 4 — Ensure the underlying `Git::Commands::*` class exists](#step-4--ensure-the-underlying-gitcommands-class-exists)
  - [Step 5 — Implement the facade method](#step-5--implement-the-facade-method)
  - [Step 6 — Update `Git::Base` and/or `Git::Lib` to delegate](#step-6--update-gitbase-andor-gitlib-to-delegate)
- [Commit discipline](#commit-discipline)
- [Quality gates](#quality-gates)
- [What stays vs. what moves](#what-stays-vs-what-moves)

## How to use this skill

Attach this file to your Copilot Chat context, then invoke with the public method
to migrate. Examples:

```text
Using the Extract Facade from Base/Lib skill, migrate Git::Base#commit to
Git::Repository#commit.
```

```text
Extract Facade: Git::Lib#branches_all (called publicly via g.lib.branches_all)
```

## Prerequisites

Before starting, you **MUST** load the following skill(s):

- [Facade Implementation](../facade-implementation/SKILL.md) — drives the actual
  scaffolding of the new facade method
- [YARD Documentation](../yard-documentation/SKILL.md) — baseline YARD rules

## Related skills

- [Facade Implementation](../facade-implementation/SKILL.md) — used in Step 5 to
  scaffold the new facade method
- [Facade Test Conventions](../facade-test-conventions/SKILL.md) — unit and
  integration test conventions for the new facade method
- [Facade YARD Documentation](../facade-yard-documentation/SKILL.md) — YARD docs
  for the new facade module/method
- [Extract Command from Lib](../extract-command-from-lib/SKILL.md) — sibling
  extraction skill that moves the underlying CLI call into a
  `Git::Commands::*` class. **Run first** when no command class exists yet.
- [Command Implementation](../command-implementation/SKILL.md) — used in Step 4
  if a new `Git::Commands::*` class needs to be scaffolded
- [Project Context](../project-context/SKILL.md) — three-layer architecture and
  Phase 4 deletion plan

## Input

Required:

1. The `Git::Base` and/or `Git::Lib` public method to migrate.
2. The git operation it performs (subcommand + flags).

## Source patterns

Public methods being migrated fall into one of three patterns. Identify which
pattern applies before planning the migration.

### Pattern A — `Git::Base` wrapper + `Git::Lib` implementation

The most common pattern. `Git::Base#foo` is a thin wrapper that forwards to
`Git::Lib#foo`, which contains the orchestration logic.

Examples: `commit`, `diff_full`, `branches`, `worktree_add`.

```ruby
# lib/git/base.rb
def commit(message, opts = {})
  self.lib.commit(message, opts)
end

# lib/git/lib.rb
def commit(message, opts = {})
  opts = opts.merge(message: message) if message
  deprecate_commit_no_gpg_sign_option!(opts)
  Git::Commands::Commit.new(self).call(edit: false, **opts).stdout
end
```

**Public contract source:** `Git::Base#commit` signature; `Git::Lib#commit`
implementation.

> When migrating, the facade method **must** preserve this signature exactly
> (e.g. `commit(message, opts = {})`) — even though greenfield facade methods
> would prefer `**options` per
> [facade-implementation REFERENCE.md — Choosing the method signature](../facade-implementation/REFERENCE.md#choosing-the-method-signature).
> The legacy public contract wins during migration.

### Pattern B — `Git::Lib`-only (public-by-exposure)

The public API is `g.lib.foo` — `Git::Base` exposes `Git::Lib` as `#lib` (or
through a similar accessor), so `Git::Lib` methods are reachable as public API
even when no `Git::Base` wrapper exists.

Examples: `branches_all`, `worktrees_all`, `current_branch_state`.

```ruby
# lib/git/lib.rb (no Git::Base wrapper exists)
def branches_all
  result = Git::Commands::Branch::List.new(self).call(all: true, format: ...)
  Git::Parsers::Branch.parse_list(result.stdout)
end
```

**Public contract source:** `Git::Lib#foo` signature and implementation.

**Migration consequence:** After Phase 4, callers using `g.lib.foo` must migrate
to `g.foo` (or `g.repository.foo`). Document this in the migration plan.

### Pattern C — `Git::Base`-only (no `Git::Lib` method)

The implementation lives entirely in `Git::Base` with no `Git::Lib` counterpart.
The method may call `command(...)` directly via `lib.send(...)` or implement
filesystem operations.

Examples: `add_remote`, `with_index`, `repo_size`, `archive`.

```ruby
# lib/git/base.rb
def repo_size
  all_files_size = 0
  Find.find(repo.path) { |f| all_files_size += File.size(f) if File.file?(f) }
  all_files_size
end
```

**Public contract source:** `Git::Base#foo` signature and implementation.

## Workflow

### Branch setup

All work must be done on a feature branch. **Never commit or push directly to
`main`.**

```bash
git checkout -b <feature-branch-name>
```

### Step 1 — Identify the source pattern

1. Locate the public method in `Git::Base` and/or `Git::Lib`.
2. Determine which [Source pattern](#source-patterns) applies (A, B, or C).
3. Note:
   - the public signature (positional args, options hash, keyword args)
   - the **exact return value** of the legacy method — read the source code to
     see whether it ends in `.stdout`, `.stdout.chomp`, a parser call, a domain
     object, `nil`, etc. **Do not assume** from the YARD `@return` tag, which
     may be stale or missing. The facade must reproduce this exact value (e.g.
     if `Git::Lib#add` ends in `.stdout`, the facade returns `String`, not
     `Git::CommandLineResult`).
   - any pre-processing (path expansion, option whitelisting, deprecation
     handling)
   - any post-processing (parsing, result-class assembly)
   - any execution-context arguments (`timeout:`, `chdir:`, `env:`)
4. Document the method's current **public contract** in writing — it must be
   preserved exactly by the facade method.
5. Run linters and rubocop to confirm a clean baseline:

   ```bash
   bundle exec rubocop
   ```

### Step 2 — Plan the migration and get approval

Before writing or changing any code, present a migration plan and **wait for
explicit confirmation** from the user.

The plan must include:

| Public method | Source pattern | Underlying command class | Class exists? | Target facade module | Notes |
| --- | --- | --- | --- | --- | --- |
| `Git::Base#foo` | A / B / C | `Git::Commands::Foo` | ✅ / 🆕 | `Git::Repository::Topic` (existing or new) | mapping decisions |

Also state:

- The exact **public contract** to preserve (signature + return type + raised
  errors).
- Whether a new topic module is required (justify per
  [facade-implementation REFERENCE.md](../facade-implementation/REFERENCE.md#decision-rules-for-adding-a-new-module)).
  When extracting one method at a time, scan `Git::Base` / `Git::Lib` for
  siblings on the same git topic and check
  `redesign/3_architecture_implementation.md` before deciding — see
  [One-at-a-time extraction](../facade-implementation/REFERENCE.md#one-at-a-time-extraction-from-gitbase--gitlib).
- The delegation strategy for `Git::Base` and/or `Git::Lib` (Step 6) — both
  remain in place during the migration window and delegate to the new facade.
- For Pattern B: explicit note that `g.lib.foo` callers will need to migrate
  before Phase 4; capture this as a follow-up issue or CHANGELOG entry.

Then ask:

> Does this mapping look correct? Any changes before I start implementing?

**Do not move to Step 3 until the user confirms the plan.**

### Step 3 — Ensure adequate legacy tests

Verify that legacy tests in `tests/units/` and existing specs in `spec/`
adequately cover the public method. The legacy tests guarantee the migration
preserves backward compatibility.

1. Search for coverage:

   ```bash
   grep -rn '<method_name>' tests/units/ spec/
   ```

2. If coverage is insufficient, add **minimal new tests** that exercise the
   current public contract. Use existing legacy test conventions for `Test::Unit`
   tests in `tests/units/`. Do **not** change existing tests.

3. Run the new tests and rubocop:

   ```bash
   bundle exec bin/test <test-file-basename>
   bundle exec rubocop tests/units/<test-file>
   ```

4. Commit:

   ```bash
   git commit -m "refactor(test): add legacy tests for <method_name>"
   ```

### Step 4 — Ensure the underlying `Git::Commands::*` class exists

The facade method calls one or more `Git::Commands::*` classes. If any required
command class does not exist yet, scaffold it first using
[Extract Command from Lib](../extract-command-from-lib/SKILL.md) (which in turn
uses [Command Implementation](../command-implementation/SKILL.md)).

For Pattern C migrations, the source `Git::Base` method may not currently call
through a `Git::Commands::*` class at all (it uses `command(...)` directly or
filesystem operations). In that case, you must scaffold the `Git::Commands::*`
class before this step.

Skip this step when every required command class already exists.

### Step 5 — Implement the facade method

Delegate to the [Facade Implementation](../facade-implementation/SKILL.md) skill
in **Scaffold** or **Update** mode. That skill handles:

- topic module selection
- generating or extending `lib/git/repository/<topic>.rb`
- generating or extending `spec/unit/git/repository/<topic>_spec.rb`
- generating or extending `spec/integration/git/repository/<topic>_spec.rb`
- YARD documentation
- running facade-side quality gates

The new facade method **must preserve the source method's public contract
exactly** — same signature, same return type, same raised errors. Use the
exact return type the source method documented (String, Array, Hash, domain
object, `CommandLineResult`).

For Pattern A and B migrations, copy any pre-processing logic
(option whitelisting, deprecation rewrites, key normalization) from `Git::Lib`
to the facade method. Do **not** leave it behind in `Git::Lib` — the facade is
now the source of truth.

For Pattern C migrations, port any pre-processing or filesystem logic from
`Git::Base` to the facade method.

After the facade method is in place and tests pass, commit:

```bash
git commit -m "feat(repository): add Git::Repository#<method_name> facade method"
```

### Step 6 — Update `Git::Base` and/or `Git::Lib` to delegate

The original methods stay in place during the migration window and delegate to
the new facade method. Both `Git::Base` and `Git::Lib` will be deleted in
Phase 4; until then, delegation preserves backward compatibility.

For each source pattern, the delegation looks like:

**Pattern A** — both files delegate:

```ruby
# lib/git/base.rb — already a wrapper; redirect to repository
def commit(message, opts = {})
  repository.commit(message, opts)
end

# lib/git/lib.rb — keep public-by-exposure callers working
def commit(message, opts = {})
  @repository.commit(message, opts)
end
```

**Pattern B** — `Git::Lib` delegates:

```ruby
# lib/git/lib.rb
def branches_all
  @repository.branches_all
end
```

**Pattern C** — `Git::Base` delegates:

```ruby
# lib/git/base.rb
def add_remote(name, url, opts = {})
  repository.add_remote(name, url, opts)
end
```

(The exact accessor — `repository`, `@repository`, `self.repository` — depends
on how `Git::Base` and `Git::Lib` hold their reference to the new
`Git::Repository` instance during the migration window. Match the existing
pattern used by other migrated methods.)

After delegation is in place, verify:

```bash
bundle exec bin/test <legacy-test-file-basename>
bundle exec rspec
bundle exec rubocop
bundle exec rake yard
```

Commit:

```bash
git commit -m "refactor(base): delegate <method_name> to Git::Repository"
```

(Use `refactor(lib):` if only `Git::Lib` was updated. When both files change,
use two separate commits — one per scope — to keep each commit single-scoped.)

## Commit discipline

Keep work organized into **three logical commit categories** (each optional if
no changes were needed for that step):

1. `refactor(test): add legacy tests for <method_name>` — new tests in
   `tests/units/` (Step 3)
2. `feat(repository): add Git::Repository#<method_name> facade method` — new
   facade module/method, unit specs, integration specs (Step 5)
3. `refactor(base): delegate <method_name> to Git::Repository` — `Git::Base`
   updated to delegate (Step 6); use `refactor(lib):` if only `Git::Lib`
   changed. When both files change, prefer **two separate commits** — one
   per scope — so each commit has a single conventional-commits scope.

If a new `Git::Commands::*` class was scaffolded in Step 4, it gets its own
commit (`refactor(command): add Git::Commands::<Command> class`) per
[Extract Command from Lib](../extract-command-from-lib/SKILL.md).

**Issue and PR references in commit bodies:** Do not use `#<number>` in the
commit body — write `issue 1000` not `issue #1000`. To close an issue/PR, use
`Closes`/`Fixes`/`Resolves #<number>` in the footer.

If further changes are needed after task commits are created, amend into the
appropriate commit and rebase. Always verify quality gates pass after rebasing.

## Quality gates

Run the gates discovered from the project's parallel default task at every step:

```bash
bundle exec ruby -e "require 'rake'; load 'Rakefile'; puts Rake::Task['default:parallel'].prerequisites"
```

Run each listed task individually via `bundle exec rake <task>` and fix
failures before advancing. All listed tasks must pass before committing.

## What stays vs. what moves

**Stays in `Git::Base` / `Git::Lib` until Phase 4:**

- Delegating methods — one-line forwards to the new `Git::Repository` facade
  method, preserving backward compatibility during the migration window.
- Methods not yet migrated — original implementation remains until extracted.

**Moves to `Git::Repository::*`:**

- The full public contract (signature, return type, raised errors).
- All pre-processing logic (option whitelisting, deprecation handling, key
  normalization, defaults).
- All post-processing logic (parsing, result-class assembly).
- The YARD docs that document the public API.

> **Branch workflow:** Implement migrations on a feature branch. Never commit
> or push directly to `main` — open a pull request when changes are ready to
> merge.
