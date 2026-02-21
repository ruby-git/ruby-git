# Review Arguments DSL

Verify that a command class's `arguments do ... end` definition accurately maps Ruby
call arguments to git CLI arguments, in the correct order, with the correct DSL
methods and modifiers.

## How to use this prompt

Attach this file to your Copilot Chat context, then invoke it with one or more
command source files and the relevant git man page or documentation. Examples:

```text
Using the Review Arguments DSL prompt, review
lib/git/commands/diff/numstat.rb against `git diff --numstat` docs.
```

```text
Review Arguments DSL: lib/git/commands/stash/push.rb
```

The invocation needs the command file(s) to review. Providing the git man page
or CLI documentation helps verify flag accuracy.

## Related prompts

- **Review Command Implementation** — class structure, phased rollout gates, and
  internal compatibility contracts
- **Review Command Tests** — unit/integration test expectations for command classes
- **Review YARD Documentation** — documentation completeness for command classes

## Input

You will be given:
1. One or more command source files containing a `class < Git::Commands::Base` and an
   `arguments do` block
2. The git man page or documentation for the subcommand

## Architecture Context (Base Pattern)

Command classes now follow this structure:

- `class < Git::Commands::Base`
- class-level `arguments do ... end`
- optional `allow_exit_status <range>` for commands where non-zero exits are valid
- YARD directive: `# @!method call(*, **)` with nested `@overload` blocks

The CLI argument mapping is still defined exclusively by the Arguments DSL. The
`Base` class handles binding and execution.

## How Arguments Work

Key behaviors:

- **Output order matches definition order** — bound arguments are emitted in the
  order entries appear in `arguments do`
- **Name-to-flag mapping** — underscores become hyphens, single-char names map to
  `-x`, multi-char names map to `--name`. **Case is preserved**: `:A` → `-A`,
  `:N` → `-N`. Uppercase short flags do not require `as:`.
- **`as:` override** — an escape hatch that emits the given string (or array of
  strings) verbatim instead of deriving a flag from the symbol name. Because it
  bypasses the DSL's automatic mapping it removes the guarantee that the flag can
  be verified just by reading the symbol name, adding a manual audit burden. Use
  it only when the DSL genuinely cannot produce the required output — see
  section 2 for the three acceptable cases. Uppercase single-char symbols never
  need `as:`.
- **Aliases** — first alias is canonical and determines generated flag (long name
  first: `%i[force f]`, not `%i[f force]`)
- **Operand naming** — use the parameter name from the git-scm.com man page, in
  singular form (e.g., `<file>` → `:file`, `<tag>` → `:tag`). The `repeatable: true`
  modifier already communicates that multiple values are accepted; pluralising the
  name is unnecessary and diverges from the docs.

## What to Check

### 1. Correct DSL method per option type

| Git behavior | DSL method | Example |
|---|---|---|
| fixed flag always present | `literal` | `literal '--numstat'` |
| boolean flag | `flag_option` | `flag_option :cached` |
| boolean-or-value | `flag_or_value_option` | `flag_or_value_option :dirstat, inline: true` |
| value option | `value_option` | `value_option :message` |
| execution kwarg (not a CLI arg) | `execution_option` | `execution_option :timeout` |
| positional argument | `operand` | `operand :commit1` |
| pathspec-style operands (keyword arg) | `value_option ... as_operand: true, separator: '--'` | `value_option :pathspec, as_operand: true, separator: '--', repeatable: true` — caller passes `pathspec: ['f1', 'f2']` |
| pathspec-style operands (positional arg) | `operand ... separator: '--'` | `operand :pathspec, repeatable: true, separator: '--'` — caller passes positionals `cmd.call('f1', 'f2')` |

#### Choosing the correct pathspec form

The two pathspec-style rows above look similar but represent meaningfully different
binding strategies. The choice is determined by the git-scm.com SYNOPSIS.

**`--` present in the git SYNOPSIS → keyword form (`value_option … as_operand: true`)**

When git explicitly separates two optional groups with `--` (e.g.,
`git diff [<tree-ish>] [--] [<pathspec>...]`), the post-`--` group is
*independently reachable* — a caller must be able to supply pathspecs without
also providing a tree-ish. Use the keyword form so positional binding is
unambiguous:

```ruby
operand :tree_ish                                              # positional
value_option :pathspec, as_operand: true, separator: '--',   # keyword
             repeatable: true

# cmd.call                               → git diff
# cmd.call('HEAD~3')                     → git diff HEAD~3
# cmd.call(pathspec: ['file.rb'])        → git diff -- file.rb
# cmd.call('HEAD~3', pathspec: ['f.rb']) → git diff HEAD~3 -- f.rb
```

Without the keyword form, `cmd.call('file.rb')` would silently bind `'file.rb'`
to `:tree_ish` instead of treating it as a pathspec.

**`--` absent (pure nesting) → two plain `operand` entries**

When the SYNOPSIS shows nested brackets — `[<commit1> [<commit2>]]` — the second
operand is only meaningful when the first is also present. No caller would ever
supply `commit2` without `commit1`. Left-to-right binding is correct:

```ruby
operand :commit1   # optional
operand :commit2   # optional — only meaningful when commit1 is also given

# cmd.call                    → git diff
# cmd.call('HEAD~3')          → git diff HEAD~3
# cmd.call('HEAD~3', 'HEAD')  → git diff HEAD~3 HEAD
```

**Quick reference**

| git SYNOPSIS shape | DSL shape |
|---|---|
| `[<a>] [--] [<b>...]` | `operand :a` + `value_option :b, as_operand: true, separator: '--'` |
| `[<a> [<b>]]` | `operand :a` + `operand :b` |

### 2. Correct alias and `as:` usage

- Prefer aliases for long/short pairs (`%i[force f]`, `%i[all A]`, `%i[intent_to_add N]`)
- Ensure long name is first in alias arrays
- **Do not** flag uppercase short-flag aliases (e.g. `:A`, `:N`) as needing `as:` —
  the DSL preserves symbol case, so `:A` correctly produces `-A` without any override

#### The `as:` escape hatch

`as:` bypasses the DSL's automatic name-to-flag mapping and emits its value
verbatim. This is intentional power — but it carries a cost: a reviewer can no
longer verify the flag by reading the symbol name alone. The `as:` string must be
audited separately, making it harder to spot typos and drift.

Flag any use of `as:` unless one of these three conditions applies:

1. **Ruby keyword conflict** — the git flag's natural name is a Ruby keyword and
   cannot be used as a symbol literal. The alias is renamed, and `as:` supplies
   the real flag:
   ```ruby
   flag_option %i[begin_rev], as: '--begin'
   ```

2. **Combined short flag** — git accepts a repeated short flag in combined form
   (e.g. `--force --force` → `-ff`) and there is no single long-form equivalent.
   This is the only idiomatic way to express it:
   ```ruby
   flag_option %i[force_force ff], as: '-ff'
   ```

3. **Multi-token flag** — the option must emit two or more CLI tokens that cannot
   be derived from a single symbol. Pass an array (valid on `flag_option` only):
   ```ruby
   flag_option :double_force, as: ['--force', '--force']
   ```

Outside these three cases, `as:` is a red flag. A DSL entry that uses `as:` where
a plain symbol or alias would suffice should be corrected.

### 3. Correct ordering

Mirror the order options appear in the git-scm.com SYNOPSIS for the command.
This keeps the DSL self-documenting and makes it easy to verify completeness
against the man page.

Within a group where the man page does not impose an order (e.g., a block of
short flags), prefer:
1. literals
2. flag options
3. flag-or-value options
4. value options
5. operands (positional args / pathspecs after `--`)

Constraint declarations always come after all arguments they reference are defined:

6. `conflicts` declarations
7. `requires_exactly_one_of` declarations (when a group needs exactly-one semantics)
8. `requires_one_of` declarations (unconditional and `when:` conditional forms)
9. `requires` declarations (single-argument conditional form)

### 4. Correct modifiers

Derive `required:` and `repeatable:` directly from the git-scm.com SYNOPSIS
notation for operands:

| SYNOPSIS notation | `required:` | `repeatable:` |
|---|---|---|
| `<arg>` | `true` | — |
| `[<arg>]` | `false` (default) | — |
| `<arg>…​` | `true` | `true` |
| `[<arg>…​]` | `false` | `true` |

Square brackets `[…]` → optional (`required: false`).
Ellipsis `…​` → repeatable (`repeatable: true`).

All valid `operand` modifiers:

| Modifier | Default | Purpose |
|---|---|---|
| `required:` | `false` | Operand must be supplied by the caller |
| `repeatable:` | `false` | Operand accepts multiple values |
| `default:` | `nil` | Value emitted when the operand is absent — see note below |
| `separator:` | `nil` | Emits a literal (e.g. `'--'`) before the operand value(s) |
| `allow_nil:` | `false` | Permits an explicit `nil` to be passed without raising |

**When to use `default:`**: omit it unless the explicit default value produces different output than `nil`. For a repeatable operand, both `nil` and `[]` are treated as absent — no args are emitted — so `default: []` is redundant and should be left off. Only supply `default:` when you need a non-empty fallback value to be emitted automatically (e.g. `default: 'HEAD'` on an optional commit operand).

Also validate that these modifiers (which do **not** apply to `operand`) are correctly
placed on their respective DSL methods:

| Modifier | Applies to |
|---|---|
| `inline:` | `value_option`, `flag_or_value_option` |
| `negatable:` | `flag_option`, `flag_or_value_option` |
| `allow_empty:` | `value_option` |
| `as_operand:` | `value_option` only — see pathspec table above |

Note: `separator: '--'` is valid on **both** `operand` and `value_option`
(with `as_operand: true`). The difference is the Ruby calling convention:
`operand` binds positional arguments; `value_option as_operand:` binds a
keyword argument. Do not flag `operand :name, separator: '--'` as incorrect.

### 5. Completeness

Cross-check against:
- git docs
- command `@overload` docs
- command unit tests

Every supported **behavioral** option should be represented in `arguments do`, and
every DSL entry should be covered by tests.

#### Options that affect stdout are intentionally omitted

The library depends on **deterministic, parseable stdout** from every command.
Any option that adds, removes, or reformats content on stdout must be
**excluded** from the DSL — whether it is a format option, a verbosity flag,
or anything else. Do **not** flag these as missing.

The test is simple: run the command with and without the option and diff stdout.
If stdout changes → exclude the option.

Examples of options to **exclude** (stdout-affecting):
- `--format=<fmt>`, `--pretty=<fmt>`, `--porcelain`
- `--patch` / `-p`, `--stat`, `--numstat`, `--shortstat`, `--raw`
- `--name-only`, `--name-status`, `--diff-stat`
- `--long` / `--short` (where they change output structure)
- `--verbose` / `-v`, `--quiet` / `-q` — nearly always add or suppress stdout lines

Examples of options to **include** (do not affect stdout):
- `--dry-run` / `-n` — changes what git *does*; stdout is still deterministic
- `--force`, `--ignore-errors` — control whether/how the operation runs
- Any flag that controls *which* objects are operated on or *whether* something happens

**Default assumption for `--verbose` and `--quiet`:** their absence is intentional.
Do **not** flag them as missing.

### 6. Conflicts

If arguments are mutually exclusive — whether option vs option, option vs operand,
or operand vs operand — verify `conflicts ...` declarations exist. Names in a
`conflicts` group may be any mix of option names and operand names. Unknown names
raise `ArgumentError` at definition time, so any typo is caught early.

**Preferred single declaration when a group is both required and mutually exclusive:**
If a `conflicts` group also has a corresponding bare `requires_one_of` for the
identical argument list, the two declarations should be collapsed into a single
`requires_exactly_one_of` call (see §7a below). Flag any command where a bare
`requires_one_of` and a `conflicts` share the same names as a candidate for this
consolidation.

### 7. Conditional and Unconditional Argument Requirements

#### 7a. Unconditional at-least-one (`requires_one_of`) and exactly-one (`requires_exactly_one_of`)

If a command requires at least one argument from a group to be present — options,
operands, or a mix — verify `requires_one_of ...` declarations exist. As with
`conflicts`, names may be any mix of option names and operand names. Alias
resolution applies before the check, so supplying an alias counts as its canonical
argument being present. Unknown names raise `ArgumentError` at definition time.

The error at bind time has the form:

  "at least one of :name1, :name2 must be provided"

When the group must have **exactly one** member present (both at-least-one and
at-most-one), prefer `requires_exactly_one_of` over separate `requires_one_of` +
`conflicts` declarations for the same names:

```ruby
# Preferred — single declaration for exactly-one semantics:
requires_exactly_one_of :mode_a, :mode_b, :mode_c

# Equivalent but verbose — two declarations that must stay in sync:
requires_one_of :mode_a, :mode_b, :mode_c
conflicts       :mode_a, :mode_b, :mode_c
```

`requires_exactly_one_of` raises at definition time for unknown names (typo guard),
and at bind time:
- zero members present → `"at least one of :a, :b, :c must be provided"`
- two or more present → `"cannot specify :a and :b"`

#### 7b. Conditional single requirement (`requires`)

If an argument is only required when another specific argument is present, verify a
`requires :name, when: :trigger` declaration exists. The check is skipped entirely
when the trigger is absent. Unknown names (including the trigger) raise
`ArgumentError` at definition time.

The error at bind time has the form:

  ":trigger requires :name"

Example in `git add`:

```ruby
requires :pathspec_from_file, when: :pathspec_file_nul
requires :dry_run,            when: :ignore_missing
```

#### 7c. Conditional at-least-one-of group (`requires_one_of ... when:`)

If at least one of a group must be present only when another argument is present,
verify a `requires_one_of :a, :b, when: :trigger` declaration exists. Like the
unconditional form, names may be any mix of option/operand names. The check is
skipped when the trigger is absent. Unknown names (including the trigger) raise
`ArgumentError` at definition time.

The error at bind time has the form:

  ":trigger requires at least one of :name1, :name2"

Example in `git tag --create`:

```ruby
requires_one_of :message, :file, when: :annotate
requires_one_of :message, :file, when: :sign
requires_one_of :message, :file, when: :local_user
```

### 7d. Allowed-values constraints

If a `value_option`, `flag_or_value_option`, or `flag_or_inline_value_option`
accepts a fixed, enumerated set of strings, verify an `allowed_values` declaration
exists for that option:

```ruby
value_option :cleanup, inline: true
allowed_values :cleanup, in: %w[verbatim whitespace strip]
```

Points to check:

- `allowed_values` supersedes ad-hoc `validator:` lambdas for enumerated-string
  cases — flag any `validator:` doing a simple set-membership test as a
  candidate for replacement.
- The declaration must reference a name already defined in `arguments do`; an
  unknown name raises `ArgumentError` at load time.
- Validation is **skipped** for `nil` / absent values; callers that want a
  non-nil value must add a separate `required:` or `requires_one_of` check.
- Validation is also skipped for empty strings when the option is declared with
  `allow_empty: true`.
- For `repeatable: true` options each element in the array is checked
  individually.
- Aliases are resolved before the check, so the declaration may use either the
  primary name or any alias.

Error form at bind time:

```
Invalid value for :name: expected one of ["a", "b"], got "actual"
```

### 8. Exit-status declaration consistency (class-level, outside the DSL)

`allow_exit_status` is a class-level declaration, not part of the `arguments do`
block. It is included here because it should be validated alongside DSL entries for
completeness. See **Review Command Implementation** for the full class-shape
checklist.

When command behavior expects non-zero success exits, verify:

- `allow_exit_status` is declared with a `Range`
- declaration is accompanied by a rationale comment
- range matches documented git behavior

Example:

```ruby
# git diff exits 1 when differences are found (not an error)
allow_exit_status 0..1
```

## Verification Chain

For each DSL entry, verify:

`Ruby call -> bound argument output -> expected git CLI`

## Output

Produce:

1. A per-entry table:

   | # | DSL method | Definition | CLI output | Correct? | Issue |
   | --- | --- | --- | --- | --- | --- |

2. A list of missing options/modifier/order/conflict issues
3. Any `allow_exit_status` mismatches or missing rationale comments

> **Branch workflow:** Implement any fixes on a feature branch. Never commit or
> push directly to `main` — open a pull request when changes are ready to merge.
