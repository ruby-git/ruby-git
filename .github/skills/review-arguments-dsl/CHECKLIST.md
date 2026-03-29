# Arguments DSL Checklist

## 1. Correct DSL method per option type

| Git behavior | DSL method | Example |
| --- | --- | --- |
| fixed flag always present | `literal` | `literal 'stash'` — **only** for operation selectors (subcommand names, mode flags like `--delete` that define what the class does) |
| boolean flag | `flag_option` | `flag_option :cached` |
| boolean-or-value | `flag_or_value_option` | `flag_or_value_option :dirstat, inline: true` |
| value option | `value_option` | `value_option :message` |
| execution kwarg (not a CLI arg) | `execution_option` | `execution_option :timeout` |
| positional argument | `operand` | `operand :commit1` |
| pathspec-style operands (keyword arg) | `end_of_options` + `value_option ... as_operand: true` | `end_of_options; value_option :pathspec, as_operand: true, repeatable: true` — caller passes `pathspec: ['f1', 'f2']` |
| pathspec-style operands (positional arg) | `end_of_options` + `operand ...` | `end_of_options; operand :pathspec, repeatable: true` — caller passes positionals `cmd.call('f1', 'f2')` |

### Recognizing `flag_or_value_option` from version-matched git docs

Version-matched git documentation uses **`[=<value>]`** (square-bracketed
`=<value>`) to mark an option's value as optional. That notation maps directly
to `flag_or_value_option`:

| Man-page signature | DSL method |
| --- | --- |
| `--foo` | `flag_option :foo` |
| `--foo=<value>` | `value_option :foo, inline: true` |
| `--foo[=<value>]` | `flag_or_value_option :foo, inline: true` |

Common examples: `--branches[=<pattern>]`, `--tags[=<pattern>]`,
`--remotes[=<pattern>]`, `--dirstat[=<param>...]`.

**Do not** use `flag_option` for these — it silently drops the value when one is
supplied.

### Action-option-with-optional-value commands

Some git commands express their **primary action** as an option with an optional
value (man-page notation: `--flag[=<value>]`). The canonical example is
`git am --show-current-patch[=(diff|raw)]` — there is no mode where the flag is
*not* passed; the optional `=<value>` just refines the behavior.

This situation is distinct from a normal `flag_or_value_option` used as a
modifier: the option IS the command. Do **not** model this as `literal
'--show-current-patch'` — that precludes passing the optional value.

**DSL entry:**

```ruby
flag_or_value_option :show_current_patch, inline: true, type: [TrueClass, String]
```

**Required `#call` override** — the class must provide a positional `#call`
override that maps the positional API onto the option keyword:

```ruby
def call(value = true, *, **)
  super(*, **, option_name: value)
end
```

Where:
- `value = true` — `true` emits `--flag` alone; a String emits `--flag=value`
- `*` — forwards any positional operands declared in the DSL (omit when none)
- `**` — forwards keyword options; unknown keywords raise `ArgumentError`
- `option_name: value` placed last so the positional arg always wins

**Flag these as errors:**

- Using `literal '--flag'` when the man page shows `--flag[=<value>]`
- Omitting `type: [TrueClass, String]` — allows `false` to silently pass, which
  emits nothing and produces no error
- Omitting the `#call` override — forces callers to use the awkward keyword form
  `.call(option_name: true)` instead of the natural `.call` or `.call('diff')`
- Using `nil` as the default in the override instead of `true` (use
  `value = true`, not `value = nil` with `|| true`)

### Choosing the correct pathspec form

The two pathspec-style rows above look similar but represent meaningfully different
binding strategies. The choice is determined by the version-matched git SYNOPSIS.

**`--` present in the git SYNOPSIS → `value_option … as_operand: true` form**

When git explicitly separates two optional groups with `--` (e.g., `git diff
[<tree-ish>] [--] [<pathspec>...]`), the post-`--` group is *independently reachable*
— a caller must be able to supply pathspecs without also providing a tree-ish. Use
the `value_option … as_operand: true` form so positional binding is unambiguous:

```ruby
operand :tree_ish                                            # positional
end_of_options                                               # options/operands boundary
value_option :pathspec, as_operand: true, repeatable: true   # as_operand

# cmd.call                               → git diff
# cmd.call('HEAD~3')                     → git diff HEAD~3
# cmd.call(pathspec: ['file.rb'])        → git diff -- file.rb
# cmd.call('HEAD~3', pathspec: ['f.rb']) → git diff HEAD~3 -- f.rb
```

Without the `value_option … as_operand: true` form, `cmd.call('file.rb')` would silently bind `'file.rb'` to
`:tree_ish` instead of treating it as a pathspec.

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

### Quick reference

| git SYNOPSIS shape | DSL shape |
| --- | --- |
| `[<a>] [--] [<b>...]` | `operand :a` + `end_of_options` + `value_option :b, as_operand: true` |
| `[<a> [<b>]]` | `operand :a` + `operand :b` |

## 2. Correct alias and `as:` usage

- Prefer aliases for long/short pairs (`%i[force f]`, `%i[all A]`, `%i[intent_to_add
  N]`)
- Ensure long name is first in alias arrays
- **Do not** flag uppercase short-flag aliases (e.g. `:A`, `:N`) as needing `as:` —
  the DSL preserves symbol case, so `:A` correctly produces `-A` without any override

### The `as:` escape hatch

`as:` bypasses the DSL's automatic name-to-flag mapping and emits its value verbatim.
This is intentional power — but it carries a cost: a reviewer can no longer verify
the flag by reading the symbol name alone. The `as:` string must be audited
separately, making it harder to spot typos and drift.

Flag any use of `as:` unless one of these three conditions applies:

1. **Ruby keyword conflict** — the git flag's natural name is a Ruby keyword and
   cannot be used as a symbol literal. The alias is renamed, and `as:` supplies the
   real flag:

   ```ruby
   flag_option %i[begin_rev], as: '--begin'
   ```

2. **Combined short flag** — git accepts a repeated short flag in combined form (e.g.
   `--force --force` → `-ff`) and there is no single long-form equivalent. This is
   the only idiomatic way to express it:

   ```ruby
   flag_option %i[force_force ff], as: '-ff'
   ```

3. **Multi-token flag** — the option must emit two or more CLI tokens that cannot be
   derived from a single symbol. Pass an array (valid on `flag_option` only):

   ```ruby
   flag_option :double_force, as: ['--force', '--force']
   ```

Outside these three cases, `as:` is a red flag. A DSL entry that uses `as:` where a
plain symbol or alias would suffice should be corrected.

#### Single-char flags never need `as:`

When git documents a flag as a bare short flag (e.g. `-p`, `-v`, `-q`), name the
symbol after the flag character directly — do **not** invent a descriptive name and
compensate with `as:`:

```ruby
# ❌ Wrong — descriptive name masking the real flag
flag_option :pretty, as: '-p'
flag_option :verbose, as: '-v'

# ✅ Correct — symbol IS the flag; no as: needed
flag_option :p
flag_option :v
```

The caller passes `p: true` or `v: true`. The symbol name is the single source of
truth and can be verified at a glance without auditing the `as:` string.

### Short-flag alias completeness

Every option that the version-matched git documentation documents with a short
form must have an alias
with the long name first:

```ruby
flag_option %i[regexp_ignore_case i]   # -i / --regexp-ignore-case
flag_option %i[extended_regexp E]      # -E / --extended-regexp
flag_option %i[fixed_strings F]        # -F / --fixed-strings
```

When reviewing, scan the version-matched docs' option headings for lines of the
form `-X` / `--long-name` and verify each has a corresponding `%i[long_name X]`
alias in the DSL.
Missing short aliases are a completeness defect, not just a convenience omission —
callers who pass the short key `:E` will get an `ArgumentError` rather than the
expected flag.

### Spurious short-flag aliases

**Never invent a short-flag alias that the version-matched docs do not
document.** Check the version-matched documentation (and tagged upstream source
when needed) before adding any alias entry. The canonical audit is: do the
minimum-version sources show `-X, --long-name` on the same option heading? If
not, do not add `:X` to the alias list.

A spurious alias looks correct to a reader but generates an unknown flag when git
rejects it:

```ruby
# ❌ Wrong — git push has no -t flag; version-matched docs show --tags only
flag_option %i[tags t]   # emits -t → git: error: unknown switch 't'

# ✅ Correct
flag_option :tags        # emits --tags only
```

Flag any alias whose short character cannot be found in the version-matched
docs' option
headings as an error (not just a style issue).

## 3. Correct ordering

Mirror the order options appear in the version-matched git SYNOPSIS for the
command. This keeps the DSL self-documenting and makes it easy to verify
completeness against the docs.

Within a group where the docs do not impose an order (e.g., a block of short
flags), prefer:

1. literals
2. flag options
3. flag-or-value options
4. value options
5. operands (positional args / pathspecs after `--`)

### `end_of_options` placement

Determine placement based on whether the version-matched SYNOPSIS explicitly shows `--`:

#### Rule 1 — SYNOPSIS shows `--`: mirror the SYNOPSIS

When the version-matched SYNOPSIS explicitly shows `--` between operand groups
(e.g., `[<tree-ish>] [--] [<pathspec>...]`), place `end_of_options` in the same
position the SYNOPSIS shows it — after the pre-`--` operands, before the post-`--`
group. See [Choosing the correct pathspec form](#choosing-the-correct-pathspec-form)
in section 1 for how to model the post-`--` group (`value_option ... as_operand: true`).

**Do not apply Rule 2** when Rule 1 applies.

```ruby
# git diff [<tree-ish>] [--] [<pathspec>...]
operand :tree_ish                                             # BEFORE end_of_options
end_of_options                                                # mirrors SYNOPSIS position
value_option :pathspec, as_operand: true, repeatable: true    # AFTER end_of_options
```

#### Rule 2 — SYNOPSIS does NOT show `--`: protect operands from flag misinterpretation

**Insert `end_of_options` immediately before the first operand when any
`flag_option`, `value_option`, or `flag_or_value_option` appears earlier in the
same `arguments do` block.** This prevents operand values that start with `-`
from being misinterpreted as flags.

This applies even when the operand is unlikely to start with `-` in practice.
Defending against pathological inputs is the correct default.

`literal` entries are **never** the trigger for Rule 2 — regardless of whether their
value is option-style (e.g. `literal '--delete'`) or a plain subcommand word
(e.g. `literal 'remove'`). Only the three DSL option-flag methods listed above
matter.

```ruby
# ✅ Correct — end_of_options guards the operand
arguments do
  literal 'remote'
  literal 'prune'
  flag_option %i[dry_run n]   # ← flag_option triggers Rule 2

  end_of_options

  operand :name, repeatable: true, required: true
end

# ❌ Missing end_of_options — flag as an error
arguments do
  literal 'remote'
  literal 'prune'
  flag_option %i[dry_run n]
  operand :name, repeatable: true, required: true  # ← end_of_options required here
end

# ✅ Not needed — only literal entries precede the operand; no DSL option-flag methods
arguments do
  literal 'remote'
  literal 'remove'
  operand :name, required: true  # no flag_option/value_option/flag_or_value_option → not required
end
```

`end_of_options` is always safe to add even when not strictly required — it is harmless
when no operand can plausibly start with `-`. Omit it by convention when neither rule
applies: it adds no defensive value and produces unnecessarily verbose command lines
(e.g. `git remote remove -- origin` instead of `git remote remove origin`).

## 4. Correct modifiers

Derive `required:` and `repeatable:` directly from the version-matched git
SYNOPSIS notation
for operands:

| SYNOPSIS notation | `required:` | `repeatable:` |
| --- | --- | --- |
| `<arg>` | `true` | — |
| `[<arg>]` | `false` (default) | — |
| `<arg>…​` | `true` | `true` |
| `[<arg>…​]` | `false` | `true` |

Square brackets `[…]` → optional (`required: false`). Ellipsis `…​` → repeatable
(`repeatable: true`).

All valid `operand` modifiers:

| Modifier | Default | Purpose |
| --- | --- | --- |
| `required:` | `false` | Operand must be supplied by the caller |
| `repeatable:` | `false` | Operand accepts multiple values |
| `default:` | `nil` | Value emitted when the operand is absent — see note below |
| `allow_nil:` | `false` | Permits an explicit `nil` to be passed without raising |
| `skip_cli:` | `false` | Binds/validates/accesses the operand but suppresses argv emission |

**When to use `default:`**: omit it unless the explicit default value produces
different output than `nil`. For a repeatable operand, both `nil` and `[]` are
treated as absent — no args are emitted — so `default: []` is redundant and should be
left off. Only supply `default:` when you need a non-empty fallback value to be
emitted automatically (e.g. `default: 'HEAD'` on an optional commit operand).

**When to use `skip_cli:`**: use it only when an operand is part of the Ruby call
contract and should be bound/validated and available on `Bound`, but must not be
emitted to CLI argv (for example, values passed via stdin protocol). Do not use
`skip_cli:` for execution kwargs; use `execution_option` for those.

Also validate that these modifiers (which do **not** apply to `operand`) are
correctly placed on their respective DSL methods:

| Modifier | Applies to |
| --- | --- |
| `inline:` | `value_option`, `flag_or_value_option` |
| `negatable:` | `flag_option`, `flag_or_value_option` |
| `allow_empty:` | `value_option` |
| `as_operand:` | `value_option` only — see pathspec table above |
| `end_of_options` | structural DSL method — required before the first `operand` (or `value_option ... as_operand: true`) whenever any option flags appear earlier in the block; pathspec operands always require it; see section 3 for the full placement rule |

## 5. Completeness

Cross-check against:

- git docs
- command `@overload` docs
- command unit tests

Every supported **behavioral** option should be represented in `arguments do`, and
every DSL entry should be covered by tests.

### Options excluded due to execution-model conflicts

Include ALL git options in the DSL by default — including output-format flags such as
`--patch`, `--numstat`, `--raw`, `--format=…`, `--pretty=…`, `--no-color`, etc.

The only options that should be **excluded** are those that conflict with the
subprocess execution model: options that require TTY input, open an external editor,
or otherwise make the command incompatible with non-interactive subprocess execution:

Examples of options to **exclude** (execution-model conflicts):

- `--interactive` / `-i` — opens an interactive menu; requires a TTY
- `--edit` / `-e` — opens an editor ($EDITOR); incompatible with subprocess
- `--patch` (interactive form, e.g. `git add -p`) — requires TTY prompts
- Any option whose git implementation requires stdin/TTY interaction the library
  cannot provide

Examples of options to **include** (no execution-model conflict):

- `--format=<fmt>`, `--pretty=<fmt>`, `--porcelain` — output format flags; the facade
  passes these explicitly when the parser requires a specific format
- `--patch` (diff output mode, e.g. `git diff --patch`), `--numstat`, `--shortstat`,
  `--raw` — output mode flags used by the facade to select a parseable format

> **Note on `--patch`:** it appears in both lists because the flag has two different
> git behaviors depending on the command. In `git add -p` it opens an interactive
> session (exclude). In `git diff --patch` it selects a non-interactive output format
> (include). Evaluate per-command, not globally.

- `--no-color` — facade passes this to prevent ANSI escape codes from breaking
  parsing
- `--verbose` / `-v`, `--quiet` / `-q` — include these unless they open a TTY

**Default assumption for `--verbose` and `--quiet`:** include unless their git
implementation requires interactive I/O.

**The `--no-edit` edge case:** `--no-edit` is a safe, non-interactive flag — it
suppresses editor opening, which is the opposite of an execution-model conflict. If
the facade always passes `--no-edit` to prevent interactive editor invocations (e.g.,
for `git commit --amend --no-edit`), include `--no-edit` in the DSL using
`flag_option :no_edit`. Do **not** hardcode it as `literal '--no-edit'` — that
prevents callers from omitting it.

**Output-format options belong at the facade call site, not as `literal` entries:**
When a parser requires specific output flags (e.g. `--pretty=raw`, `--numstat`),
declare those flags in the DSL with `flag_option` or `value_option`, and pass them
explicitly from `Git::Lib`. Never hardcode them as `literal` entries inside the
command class — that hides the parser contract and prevents the facade from choosing
the format. See Insight 16 in `redesign/3_architecture_implementation.md`.

### Per-argument validation completeness

For every `flag_option`, `value_option`, `flag_or_value_option`, and `operand`
declaration, check whether per-argument validation parameters have been considered:

| Parameter | Flag it missing if… |
| --- | --- |
| `required: true` | The command always fails without this argument, making the Ruby caller's error clearer before spawning a process |
| `allow_nil: false` | The argument is optional in Ruby (no `required: true`), but `nil` should be rejected rather than treated as "not provided" — for example, passing `nil` would produce an invalid CLI argument or ambiguous behavior |
| `type: <Class>` | A wrong Ruby type would produce a confusing git error or silent coercion |
| `validator:` | A simple per-argument predicate exists that git expresses poorly in its error output |

`value_option` and `flag_or_value_option` default to `allow_nil: true`. Specify
`allow_nil: false` when nil must be rejected explicitly. Only specify `allow_nil:
true` when distinguishing an explicit `nil` from "not provided" is semantically
important; do not flag its absence when the default is correct.

**`allow_nil: true` on `required:` arguments:** flag as suspicious — allowing nil on
a required argument is rarely correct.

Do **not** flag the absence of these parameters as issues when no meaningful
constraint exists for that argument — omitting them is correct in that case.

**Cross-argument constraint methods are generally not used in command classes.** Do
not flag the absence of `conflicts`, `requires`, `requires_one_of`,
`requires_exactly_one_of`, `forbid_values`, or `allowed_values` as a completeness
issue. Command classes use per-argument validation parameters (`required:`, `type:`,
`allow_nil:`, etc.) and operand format validation. Git validates its own option
semantics. The narrow exception is **arguments git cannot observe in its argv** — the
test is: does this argument appear in git's argv? If no (e.g., `skip_cli: true`
operands routed via stdin), git cannot detect incompatibilities and constraint
declarations are appropriate and should not be flagged as policy violations. Example:
`cat-file --batch` declares `conflicts :objects, :batch_all_objects` and
`requires_one_of :objects, :batch_all_objects` because `:objects` is `skip_cli:
true`. See the validation delegation policy in
`redesign/3_architecture_implementation.md` Insight 6.

## 6. Exit-status declaration consistency (class-level, outside the DSL)

`allow_exit_status` is a class-level declaration, not part of the `arguments do`
block. It is included here because it should be validated alongside DSL entries for
completeness. See [Review Command
Implementation](../review-command-implementation/SKILL.md) for the full class-shape
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
