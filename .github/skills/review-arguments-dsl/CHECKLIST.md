# Arguments DSL Checklist
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

#### Recognizing `flag_or_value_option` from the git man page

The git-scm.com man page uses **`[=<value>]`** (square-bracketed `=<value>`)
to mark an option's value as optional. That notation maps directly to
`flag_or_value_option`:

| Man-page signature | DSL method |
|---|---|
| `--foo` | `flag_option :foo` |
| `--foo=<value>` | `value_option :foo, inline: true` |
| `--foo[=<value>]` | `flag_or_value_option :foo, inline: true` |

Common examples: `--branches[=<pattern>]`, `--tags[=<pattern>]`,
`--remotes[=<pattern>]`, `--dirstat[=<param>...]`.

**Do not** use `flag_option` for these — it silently drops the value when one
is supplied.

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

#### Short-flag alias completeness

Every option that the git man page documents with a short form must have an alias
with the long name first:

```ruby
flag_option %i[regexp_ignore_case i]   # -i / --regexp-ignore-case
flag_option %i[extended_regexp E]      # -E / --extended-regexp
flag_option %i[fixed_strings F]        # -F / --fixed-strings
```

When reviewing, scan the man page's option headings for lines of the form
`-X` / `--long-name` and verify each has a corresponding `%i[long_name X]`
alias in the DSL. Missing short aliases are a completeness defect, not just
a convenience omission — callers who pass the short key `:E` will get an
`ArgumentError` rather than the expected flag.

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
| `skip_cli:` | `false` | Binds/validates/accesses the operand but suppresses argv emission |

**When to use `default:`**: omit it unless the explicit default value produces different output than `nil`. For a repeatable operand, both `nil` and `[]` are treated as absent — no args are emitted — so `default: []` is redundant and should be left off. Only supply `default:` when you need a non-empty fallback value to be emitted automatically (e.g. `default: 'HEAD'` on an optional commit operand).

**When to use `skip_cli:`**: use it only when an operand is part of the Ruby
call contract and should be bound/validated and available on `Bound`, but must
not be emitted to CLI argv (for example, values passed via stdin protocol).
Do not use `skip_cli:` for execution kwargs; use `execution_option` for those.
`skip_cli: true` must not be combined with `separator:`.

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

#### Per-argument validation completeness

For every `flag_option`, `value_option`, `flag_or_value_option`, and `operand`
declaration, check whether per-argument validation parameters have been considered:

| Parameter | Flag it missing if… |
|---|---|
| `required: true` | The command always fails without this argument, making the Ruby caller's error clearer before spawning a process |
| `allow_nil: false` | The argument is `required:` and a `nil` value is meaningless (not just absent) |
| `type: <Class>` | A wrong Ruby type would produce a confusing git error or silent coercion |
| `validator:` | A simple per-argument predicate exists that git expresses poorly in its error output |

Do **not** flag the absence of these parameters as issues when no meaningful
constraint exists for that argument — omitting them is correct in that case.

**Cross-argument constraint methods are generally not used in command classes.** Do not flag
the absence of `conflicts`, `requires`, `requires_one_of`, `requires_exactly_one_of`,
`forbid_values`, or `allowed_values` as a completeness issue. Command classes use
per-argument validation parameters (`required:`, `type:`, `allow_nil:`, etc.) and
operand format validation. Git validates its own option semantics. The narrow
exception is **arguments git cannot observe in its argv** — the test is: does this
argument appear in git's argv? If no (e.g., `skip_cli: true` operands routed via
stdin), git cannot detect incompatibilities and constraint declarations are
appropriate and should not be flagged as policy violations. Example: `cat-file
--batch` declares `conflicts :objects, :batch_all_objects` and `requires_one_of
:objects, :batch_all_objects` because `:objects` is `skip_cli: true`. See the
validation delegation policy in `redesign/3_architecture_implementation.md` Insight 6.

### 6. Exit-status declaration consistency (class-level, outside the DSL)

`allow_exit_status` is a class-level declaration, not part of the `arguments do`
block. It is included here because it should be validated alongside DSL entries for
completeness. See [Review Command Implementation](../review-command-implementation/SKILL.md) for the full class-shape
checklist.

When command behavior expects non-zero success exits, verify:

- `allow_exit_status` is declared with a `Range`
- declaration is accompanied by a rationale comment
- range matches documented git behavior

Example:

```ruby
# git diff exits 1 when differences are found (not an error)
allow_exit_status 0..1
