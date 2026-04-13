# Arguments DSL Checklist

- [1. Determine scope and exclusions](#1-determine-scope-and-exclusions)
  - [Options excluded because they belong to a different sub-action](#options-excluded-because-they-belong-to-a-different-sub-action)
  - [Options excluded due to execution-model conflicts](#options-excluded-due-to-execution-model-conflicts)
- [2. Verify DSL method per option type](#2-verify-dsl-method-per-option-type)
  - [Recognizing `flag_or_value_option` from the git docs](#recognizing-flag_or_value_option-from-the-git-docs)
  - [Action-option-with-optional-value commands](#action-option-with-optional-value-commands)
  - [Choosing the correct pathspec form](#choosing-the-correct-pathspec-form)
  - [Quick reference](#quick-reference)
- [3. Verify alias and `as:` usage](#3-verify-alias-and-as-usage)
  - [The `as:` escape hatch](#the-as-escape-hatch)
    - [Prefer first-class DSL features over `as:`](#prefer-first-class-dsl-features-over-as)
    - [Single-char flags never need `as:`](#single-char-flags-never-need-as)
  - [Short-flag alias completeness](#short-flag-alias-completeness)
  - [Spurious aliases](#spurious-aliases)
- [4. Verify ordering](#4-verify-ordering)
  - [`end_of_options` placement](#end_of_options-placement)
    - [Rule 1 — SYNOPSIS shows `--`: mirror the SYNOPSIS](#rule-1--synopsis-shows----mirror-the-synopsis)
    - [Rule 2 — SYNOPSIS does NOT show `--`: protect operands from flag misinterpretation](#rule-2--synopsis-does-not-show----protect-operands-from-flag-misinterpretation)
    - [Choosing the `as:` token](#choosing-the-as-token)
- [5. Verify modifiers](#5-verify-modifiers)
  - [`execution_option` usage](#execution_option-usage)
- [6. Check completeness](#6-check-completeness)
  - [YARD documentation ↔ DSL parity](#yard-documentation--dsl-parity)
  - [Repeatable boolean flags](#repeatable-boolean-flags)
  - [Operand naming](#operand-naming)
  - [Per-argument validation completeness](#per-argument-validation-completeness)
- [7. Check class-level declarations](#7-check-class-level-declarations)

## 1. Determine scope and exclusions

Before auditing individual DSL entries, determine which git options are in scope.
Reference documents and source files are loaded during the [Input phase](SKILL.md#input).

### Options excluded because they belong to a different sub-action

When a command is split into sub-command classes (e.g., `Branch::Create` vs.
`Branch::List`), each class includes **only** the options that apply to its
sub-action. Do **not** add every option from the man page — git documents all modes
on a single page.

To determine which options belong to a sub-action:

1. **Read the SYNOPSIS** — git man pages list separate SYNOPSIS lines per mode.
   Only options shown on the SYNOPSIS line for the target sub-action are candidates.
2. **Cross-reference DESCRIPTION and OPTIONS sections** — check each option's
   description for phrases like "only useful with `--list`" or "when used with
   `-d`". If the docs explicitly tie an option to a different mode, exclude it.
3. **Common/shared options** — options on every SYNOPSIS line or described as
   applying to the command as a whole (e.g., `--quiet`, `--verbose`) belong in
   every sub-command class where they are meaningful.

This rule applies **only** to split commands. For single-class commands, include all
options (subject to execution-model exclusions below).

### Options excluded due to execution-model conflicts

Include ALL git options in the DSL by default — including output-format flags such as
`--patch`, `--numstat`, `--raw`, `--format=…`, `--pretty=…`, `--no-color`, etc.

The only options that should be **excluded** are those that conflict with the
subprocess execution model: options that require TTY input or otherwise make the
command incompatible with non-interactive subprocess execution:

Examples of options to **exclude** (execution-model conflicts):

- `--interactive` / `-i` — opens an interactive menu; requires a TTY
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

**Default assumption for `--verbose` and `--quiet`:** declare as `flag_option`
(not `literal`) unless their git implementation requires interactive I/O.

Command classes are neutral — they never hardcode `literal` entries for
output-control, editor-suppression, or progress flags. Declare these as
`flag_option` / `value_option` so the facade can pass the policy value.

> **Anti-pattern:** `literal '--no-edit'`, `literal '--verbose'`,
> `literal '--no-progress'` inside a command class.
>
> **Correct pattern:** `flag_option :edit, negatable: true` in the command;
> `edit: false` passed from the facade call site.

**The `--edit` / `--no-edit` pair:** Model as `flag_option :edit, negatable: true`.
The facade (`Git::Lib`) passes `edit: false` at each call site. Do **not** hardcode
`literal '--no-edit'` — that prevents the facade from controlling the option — and do
**not** exclude `--edit` from the DSL.

**Output-format options belong at the facade call site, not as `literal` entries:**
When a parser requires specific output flags (e.g. `--pretty=raw`, `--numstat`),
declare those flags in the DSL with `flag_option` or `value_option`, and pass them
explicitly from `Git::Lib`. Never hardcode them as `literal` entries inside the
command class — that hides the parser contract and prevents the facade from choosing
the format. See Insight 16 in `redesign/3_architecture_implementation.md`.

## 2. Verify DSL method per option type

| Git behavior | DSL method | Example |
| --- | --- | --- |
| fixed flag always present | `literal` | `literal 'stash'` — **only** for operation selectors (subcommand names, mode flags like `--delete` that define what the class does) |
| boolean flag | `flag_option` | `flag_option :cached` |
| repeatable boolean flag | `flag_option ..., max_times: N` | `flag_option %i[force f], max_times: 2` |
| boolean-or-value | `flag_or_value_option` | `flag_or_value_option :dirstat, inline: true` |
| value option | `value_option` | `value_option :message` |
| key-value pair option (inherently repeatable via Hash/Array input) | `key_value_option` | `key_value_option :trailer, key_separator: ': '` — caller passes `trailer: { 'Signed-off-by' => 'Name' }` or `trailer: [['key', 'val']]` |
| option requiring custom builder logic | `custom_option` | `custom_option :pattern, required: true do |val| ... end` — builder block receives the value and returns CLI args |
| execution kwarg (not a CLI arg) | `execution_option` | `execution_option :timeout` |
| positional argument | `operand` | `operand :commit1` |
| pathspec-style operands (independently reachable after `--`) | `end_of_options` + `value_option ... as_operand: true` | `end_of_options; value_option :pathspec, as_operand: true, repeatable: true` — caller passes `pathspec: ['f1', 'f2']` |
| pathspec-style operands (only positional group, no earlier positional ambiguity) | `operand ...` | `operand :pathspec, repeatable: true` — caller passes positionals `cmd.call('f1', 'f2')` |

### Recognizing `flag_or_value_option` from the git docs

git command documentation uses **`[=<value>]`** (square-bracketed
`=<value>`) to mark an option's value as optional. That notation maps directly
to `flag_or_value_option`:

| Man-page signature | DSL method |
| --- | --- |
| `--foo` | `flag_option :foo` |
| `--foo` / `--no-foo` | `flag_option :foo, negatable: true` |
| `--foo=<value>` | `value_option :foo, inline: true` |
| `--foo[=<value>]` | `flag_or_value_option :foo, inline: true` |
| `--foo[=<value>]` / `--no-foo` | `flag_or_value_option :foo, negatable: true, inline: true` |
| `--foo <value>` | `value_option :foo` |

**Why `inline: true` appears in every `=` row:** The `=` in man-page notation
(`--foo=<value>`, `--foo[=<value>]`) means git expects the value joined to the
flag as a single argv token (`--foo=bar`). The `inline: true` modifier tells the
DSL builder to emit that joined form. Without it, the value is emitted as a
**separate** argv token (`--foo bar`), which is the correct behavior when the git
docs show a space between the flag and value (`--foo <value>`). Match the
man-page notation: `=` → `inline: true`; space → omit `inline:`.

Common examples: `--branches[=<pattern>]`, `--tags[=<pattern>]`,
`--remotes[=<pattern>]`, `--dirstat[=<param>...]`.

Tri-state examples: `--track[=direct|inherit]` / `--no-track`,
`--recurse-submodules[=yes|on-demand|no]` / `--no-recurse-submodules`.

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
  super(*, **, show_current_patch: value)
end
```

Where:

- `value = true` — `true` emits `--flag` alone; a String emits `--flag=value`
- `*` — forwards any positional operands declared in the DSL (omit when none)
- `**` — forwards keyword options; unknown keywords raise `ArgumentError`
- `show_current_patch: value` — uses the actual option keyword name; placed last
  so the positional arg always wins

**Flag these as errors:**

- Using `literal '--flag'` when the man page shows `--flag[=<value>]`
- Omitting `type: [TrueClass, String]` — allows `false` to silently pass, which
  emits nothing and produces no error
- Omitting the `#call` override — forces callers to use the awkward keyword form
  `.call(option_name: true)` instead of the natural `.call` or `.call('diff')`
- Using `nil` as the default in the override instead of `true` (use
  `value = true`, not `value = nil` with `|| true`)

### Choosing the correct pathspec form

Choose the pathspec form by answering one question from the git command doc
SYNOPSIS: **can the pathspec group be supplied independently of earlier positional
operands?**

If **yes**, use `end_of_options` plus `value_option … as_operand: true` so the
caller can supply the pathspec group without accidentally binding it to an earlier
operand.

If **no**, use plain `operand` entries so left-to-right positional binding mirrors
the SYNOPSIS.

**Independently reachable pathspec group → `value_option … as_operand: true`**

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

The same rule applies when the SYNOPSIS has only a post-`--` pathspec group and no
earlier operands:

```ruby
end_of_options
value_option :pathspec, as_operand: true, repeatable: true, required: true

# cmd.call('file.rb')        → git <cmd> -- file.rb
# cmd.call('f1', 'f2')       → git <cmd> -- f1 f2
```

**Pure positional nesting → plain `operand` entries**

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

| git SYNOPSIS shape | Meaning | DSL shape |
| --- | --- | --- |
| `[<a>] [--] [<b>...]` | `<b>` is independently reachable | `operand :a` + `end_of_options` + `value_option :b, as_operand: true, repeatable: true` |
| `[--] <pathspec>...` | required pathspec group after `--` | `end_of_options` + `value_option :pathspec, as_operand: true, repeatable: true, required: true` |
| `[--] [<pathspec>...]` | optional pathspec group after `--` | `end_of_options` + `value_option :pathspec, as_operand: true, repeatable: true` |
| `<pathspec>...` | only positional group; no earlier positional ambiguity | `operand :pathspec, repeatable: true, required: true` |
| `[<a> [<b>]]` | pure left-to-right nesting | `operand :a` + `operand :b` |

Use `value_option … as_operand: true` whenever the post-`--` group must be
addressable without binding through earlier positional operands. Use plain
`operand` entries only when left-to-right positional binding is unambiguous and
matches the SYNOPSIS.

## 3. Verify alias and `as:` usage

- Prefer aliases for long/short pairs (`%i[force f]`, `%i[all A]`, `%i[intent_to_add
  N]`)
- Ensure long name is first in alias arrays

### Inline comment style

Each DSL entry MAY have a trailing comment documenting the emitted CLI form. When
present, the comment must reflect **what the DSL actually emits** — the primary
(long) flag — not the git man-page synopsis notation.

```ruby
# ✅ Correct — shows the emitted long flag; alias noted separately
flag_option %i[verbose v]          # --verbose (alias: :v)
flag_option %i[all a]              # --all (alias: :a)
flag_or_value_option :color, inline: true, negatable: true  # --color[=<when>] / --no-color
value_option :format, inline: true # --format=<format>

# ❌ Wrong — shows both short and long forms as if both are emitted;
#            reader may assume -v and --verbose are two separate flags
flag_option %i[verbose v], max_times: 2  # -v / -vv / --verbose
flag_option %i[all a]                    # -a / --all
```

The rule: **one comment → one emitted flag form**. Aliases are referenced as
`(alias: :x)`, not listed as separate flag tokens. Flag any comment that lists a
short flag as if it is independently emitted.
- **Do not** flag uppercase short-flag aliases (e.g. `:A`, `:N`) as needing `as:` —
  the DSL preserves symbol case, so `:A` correctly produces `-A` without any override

### The `as:` escape hatch

`as:` bypasses the DSL's automatic name-to-flag mapping and emits its value verbatim.
This is intentional power — but it carries a cost: a reviewer can no longer verify
the flag by reading the symbol name alone. The `as:` string must be audited
separately, making it harder to spot typos and drift.

Flag any use of `as:` unless one of these conditions applies:

1. **Ruby keyword conflict** — the git flag's natural name is a Ruby keyword and
  cannot be used as a symbol literal. The alias is renamed, and `as:` supplies the
  real flag:

   ```ruby
   flag_option %i[begin_rev], as: '--begin'
   ```

2. **The required argv cannot be expressed by the normal DSL mapping** — the
  symbol name, aliases, and existing modifiers (`negatable:`, `inline:`,
  `as_operand:`, `max_times:`, etc.) cannot produce the required token sequence,
  so `as:` is the narrowest accurate escape hatch. Example:

   ```ruby
   # :three_way auto-maps to --three-way, but git expects --3way
   flag_option :three_way, as: '--3way'
   ```

Outside these cases, `as:` is a red flag. A DSL entry that uses `as:` where a
plain symbol, alias, or existing modifier would suffice should be corrected.

#### Prefer first-class DSL features over `as:`

When the DSL now has a first-class way to express the behavior, `as:` is no longer
justified. Repeated flags are the canonical example: use `max_times:` instead of
encoding repetition manually.

The following patterns should be flagged as errors because `max_times:` expresses
them directly:

- **Combined short flag used to emulate repetition** (e.g. `flag_option %i[force_force ff], as: '-ff'`) —
  replace with `flag_option %i[force f], max_times: 2`
- **Repeated identical tokens encoded as an array** (e.g. `flag_option :double_force, as: ['--force', '--force']`) —
  replace with `flag_option %i[force f], max_times: 2`

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

Every option that the git documentation documents with a short form must have an
alias with the long name first:

```ruby
flag_option %i[regexp_ignore_case i]   # -i / --regexp-ignore-case
flag_option %i[extended_regexp E]      # -E / --extended-regexp
flag_option %i[fixed_strings F]        # -F / --fixed-strings
```

When reviewing, scan the git command doc's option headings for lines of the form
`-X` / `--long-name` and verify each has a corresponding `%i[long_name X]` alias in
the DSL. Missing short aliases are a completeness defect, not just a convenience
omission — callers who pass the short key `:E` will get an `ArgumentError` rather
than the expected flag.

### Spurious aliases

**Never invent an alias that the git command document does not document.** Check the
git command document before adding any alias entry. The canonical audit is: does the
git command document show the alias on the same option heading as the primary name?
If not, do not add it to the alias list.

Flag any alias that cannot be found in the git command document's option headings as
an error (not just a style issue).

## 4. Verify ordering

literal options should always come first.

For other options mirror the order those options appear in the git command document's
SYNOPSIS section for the subcommand being implemented.

Options that appear only in the OPTIONS section (not the SYNOPSIS) go after all
SYNOPSIS-ordered options but before `execution_option` declarations. Among
themselves, mirror the order found in the OPTIONS section.

`execution_option` declarations go after all CLI-producing options (`flag_option`,
`value_option`, `flag_or_value_option`, `key_value_option`, `custom_option`) and
before `end_of_options` and `operand` declarations. Since `execution_option` never
emits CLI arguments, its position does not affect the generated command line, but
consistent placement keeps the DSL block readable.

operands should go last.

### `end_of_options` placement

Determine placement based on whether the SYNOPSIS explicitly shows `--`:

#### Rule 1 — SYNOPSIS shows `--`: mirror the SYNOPSIS

When the SYNOPSIS explicitly shows `--`, place `end_of_options` in
the same position the SYNOPSIS shows it. See [Choosing the correct pathspec
form](#choosing-the-correct-pathspec-form) for how to model the operands that come
after `--`.

**Do not apply Rule 2** when Rule 1 applies.

```ruby
# git diff [<tree-ish>] [--] [<pathspec>...]
operand :tree_ish                                             # BEFORE end_of_options
end_of_options                                                # mirrors SYNOPSIS position
value_option :pathspec, as_operand: true, repeatable: true    # AFTER end_of_options
```

#### Rule 2 — SYNOPSIS does NOT show `--`: protect operands from flag misinterpretation

**Insert `end_of_options` immediately before the first operand when any
`flag_option`, `value_option`, `flag_or_value_option`, `key_value_option`, or
`custom_option` appears earlier in the same `arguments do` block.** This prevents
operand values that start with `-` from being misinterpreted as flags.

This applies even when the operand is unlikely to start with `-` in practice.
Defending against pathological inputs is the correct default.

`literal` entries are **never** the trigger for Rule 2 — regardless of whether their
value is option-style (e.g. `literal '--delete'`) or a plain subcommand word
(e.g. `literal 'remove'`). Only the five DSL option methods matter:
`flag_option`, `value_option`, `flag_or_value_option`, `key_value_option`, and
`custom_option`.

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

# ✅ Not needed — only literal entries precede the operand; no DSL option methods
arguments do
  literal 'remote'
  literal 'remove'
  operand :name, required: true  # no option methods → not required
end
```

`end_of_options` is always safe to add even when not strictly required — it is harmless
when no operand can plausibly start with `-`. Omit it by convention when neither rule
applies: it adds no defensive value and produces unnecessarily verbose command lines
(e.g. `git remote remove -- origin` instead of `git remote remove origin`).

#### Choosing the `as:` token

`end_of_options` defaults to emitting `--` as the options terminator, which is
correct for the vast majority of git commands. However, some commands use a
different terminator token. The canonical example is `git rev-parse`, which uses
`--end-of-options` instead of `--` because `--` is a **meaningful argument** to
`rev-parse` (it separates revisions from file paths in the output), not an
options terminator.

Use `end_of_options as: '<token>'` when the git documentation for the command
explicitly documents a different terminator. Check the command's SYNOPSIS and
options section for language like "use `--end-of-options` to separate options
from arguments".

| Git documentation says | DSL form |
| --- | --- |
| `[--] <pathspec>...` or generic `--` usage | `end_of_options` (default `as: '--'`) |
| `--end-of-options` explicitly documented | `end_of_options as: '--end-of-options'` |

**Flag these as errors:**

- Using bare `end_of_options` (emitting `--`) on a command that documents
  `--end-of-options` as its terminator — `--` has a different meaning for that
  command and will produce incorrect behavior
- Using `end_of_options as: '--end-of-options'` on a command that does not
  document it — the default `--` is correct for nearly all commands

```ruby
# ✅ Correct — git rev-parse documents --end-of-options
end_of_options as: '--end-of-options'
operand :args, repeatable: true

# ❌ Wrong — bare -- has a different meaning in rev-parse
end_of_options
operand :args, repeatable: true
```

## 5. Verify modifiers

Derive `required:` and `repeatable:` directly from the SYNOPSIS notation for
operands:

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

### `execution_option` usage

`execution_option` declares a Ruby keyword argument that controls subprocess
execution rather than producing a git CLI flag. It accepts **only** a name (or array
of alias names) — no modifiers (`required:`, `as:`, `validator:`, `repeatable:`,
etc.) are supported.

Values are forwarded as Ruby kwargs to the underlying command runner (e.g.,
`command_capturing` or `command_streaming`). They never appear in the generated argv.

The authoritative set of accepted execution option names is defined by
`COMMAND_CAPTURING_ARG_DEFAULTS` and `COMMAND_STREAMING_ARG_DEFAULTS` in
`lib/git/lib.rb`. The complete set of accepted names is:

| Name | Purpose | Capturing | Streaming | Notes |
| --- | --- | --- | --- | --- |
| `:timeout` | Maximum seconds to wait for the subprocess to complete; `nil` falls back to `Git.config.timeout`, `0` disables | yes | yes | Most commonly exposed execution option |
| `:chdir` | Working directory for the subprocess | yes | yes | |
| `:out` | Output destination; when present, `Base#execute_command` selects the streaming path | yes | yes | Presence triggers streaming vs. capturing path selection |
| `:in` | IO object to use as stdin for the subprocess; must be a real IO with a file descriptor | yes | yes | |
| `:merge` | Merge stdout and stderr into a single captured string | yes | — | |
| `:env` | Additional environment variable overrides (Hash); merged with the command's own `env` by `Base#execution_opts` | yes | yes | |
| `:normalize` | Normalize captured output encoding to UTF-8 (via `rchardet` detection) | yes | — | |
| `:chomp` | Chomp trailing newlines from captured stdout and stderr | yes | — | |
| `:err` | Additional destination for stderr output; stderr is always captured internally and available via `result.stderr` — when `:err` is provided, writes are teed to both the internal buffer and this destination | yes | yes | `result.stderr` remains available even when stderr is teed to another destination; safe to expose but rarely needed |
| `:raise_on_failure` | Whether to raise `Git::FailedError` on non-zero exit status | yes | yes | `Base#execute_command` hardcodes this to `false` and uses `validate_exit_status!` instead, so exposing it via the DSL has no effect — flag as unnecessary if encountered |

An `execution_option` whose name does not appear in either defaults hash will raise
`ArgumentError` at runtime — flag it as a likely error (either a misunderstanding of
the DSL or an option that should be a `value_option` or `flag_option` instead).

Also validate that these modifiers (which do **not** apply to `operand`) are
correctly placed on their respective DSL methods:

| Modifier | Applies to |
| --- | --- |
| `as:` | `flag_option`, `value_option`, `flag_or_value_option`, `key_value_option` — escape hatch that emits the given string verbatim; see [Section 3](#3-verify-alias-and-as-usage) for when use is justified |
| `type:` | `value_option`, `flag_or_value_option` — restrict accepted Ruby types; see [Section 2](#action-option-with-optional-value-commands) for the one valid use case (`type: [TrueClass, String]`) |
| `required:` | `flag_option`, `value_option`, `flag_or_value_option`, `key_value_option`, `custom_option`, `operand` — see [Section 6](#6-check-completeness) for when to flag its absence |
| `allow_nil:` | `flag_option`, `value_option`, `flag_or_value_option`, `key_value_option`, `custom_option` (default `true`), `operand` (default `false`) — see [Section 6](#6-check-completeness) |
| `inline:` | `value_option`, `flag_or_value_option`, `key_value_option` |
| `negatable:` | `flag_option`, `flag_or_value_option` |
| `repeatable:` | `value_option`, `flag_or_value_option` — accepts an array of values (note: `operand` also accepts `repeatable:` — see operand modifier table above) |
| `allow_empty:` | `value_option` — use when git distinguishes an empty-string value (`--option ''`) from the option being absent; without it, passing `''` raises `ArgumentError` |
| `as_operand:` | `value_option` only — see pathspec table above |
| `max_times:` | `flag_option` — limits how many times the flag is emitted; caller passes an integer up to N (e.g. `force: 2` emits `--force --force`) |
| `key_separator:` | `key_value_option` — separator between key and value (default: `'='`) |

**Do not use `type:` for general type validation.** The DSL accepts any object with
a meaningful `#to_s` implementation — `String`, `Integer`, `Float`, `Pathname`,
`Symbol`, etc. — and stringifies it automatically during the build phase. Adding
`type: String` to a `value_option` rejects valid inputs like `Pathname` or `Integer`
that would produce correct CLI arguments. Git validates the actual string value; the
DSL does not need to duplicate that.

The one exception is action-option-with-optional-value commands (see
[Section 2](#action-option-with-optional-value-commands)), where
`type: [TrueClass, String]` prevents `false` from silently emitting nothing.

## 6. Check completeness

### YARD documentation ↔ DSL parity

Every keyword/positional parameter documented for `call` must correspond to a DSL
entry and vice versa — mismatches indicate either a missing DSL entry or stale
documentation.

**`negatable:` options must document both emitted forms.** When the DSL declares
`flag_option :foo, negatable: true` or `flag_or_value_option :foo, negatable: true`,
the `@option` prose must explicitly state that `false` emits `--no-foo`. An
`@option` that only describes the positive (`true`) form is missing documentation
for callers who pass `false`.

```ruby
# ❌ Missing — only describes the positive form
# @option options [Boolean] :create_reflog (nil) create the branch's reflog

# ✅ Correct — documents both forms
# @option options [Boolean] :create_reflog (nil) create the branch's reflog
#
#   Pass `true` for `--create-reflog`, `false` for `--no-create-reflog`.
```

**`@option` descriptions must use the emitted long flag form.** The DSL emits the
primary (long) flag regardless of which alias the caller uses. Any `@option`
prose that references a short flag (e.g. `-v`, `-f`, `-a`) as if it is emitted
is misleading and must be corrected to the long form:

```ruby
# ❌ Misleading — describes -v as emitted
# @option options [Boolean, Integer] :verbose (nil) ...
#   Pass `true` for `-v`; pass `2` for `-v -v`.

# ✅ Correct — describes the emitted flag
# @option options [Boolean, Integer] :verbose (nil) ...
#   Pass `true` for `--verbose`; pass `2` for `--verbose --verbose`.
```

- If the class defines an explicit `def call`, check the YARD docs directly above
  that method.
- If the class does **not** define `def call`, check the `@overload` blocks in the
  class's `@!method call` YARD directive.

Flag any parameter present in an `@overload` but absent from `arguments do` (or
vice versa) as a mismatch that must be resolved.

**Example mismatch — documented `call` parameter `force:` is missing from the DSL:**

```ruby
# @!method call
#   @overload call(force: false)
#     @param force [Boolean] force the operation
arguments do
  # ← missing: flag_option %i[force f]
end
```

Every option documented for the command should be represented in `arguments do`
(except those excluded due to execution-model conflicts — see [§1](#1-determine-scope-and-exclusions)),
and every DSL entry should be covered by tests.

### Repeatable boolean flags

When the git command documentation describes a flag that can be given multiple
times to increase its effect (e.g. `--force` can be given twice for `git clean`), use
`flag_option ..., max_times: N` where N is the documented maximum repetition count.
The caller can then pass `true` (emit once) or an integer up to N (emit that many
times).

**When the docs don't state a specific maximum:** Some git docs say "can be given
more than once" without specifying a maximum. Do **not** invent a bound such as
`max_times: 2`. Instead, treat the repetition limit as requiring manual
verification against the latest-version upstream documentation and, if still
ambiguous, the latest-version upstream source. Only use `max_times: N` when that
verification establishes an explicit bound. If no explicit bound can be verified,
flag the DSL entry for manual/source verification rather than hard-coding an
arbitrary limit.

Flag these as errors:

- Using `as:` to emulate repeated flags (e.g. `as: '-ff'` or
  `as: ['--force', '--force']`) instead of `max_times:`
- Using a separate symbol name for the repeated form (e.g. `:force_force`) instead of
  `max_times:` on the same symbol
- Missing `max_times:` when the latest-version docs explicitly describe repeatable
  flag behavior

### Operand naming

Verify that each `operand` name matches the `<parameter>` name from the git
documentation in singular form. For example, if the git docs say
`<pathspec>...`, the operand should be named `:pathspec` (not `:pathspecs` or
`:paths`). If the docs say `<commit>`, the operand should be named `:commit`.

### Per-argument validation completeness

For every `flag_option`, `value_option`, `flag_or_value_option`, and `operand`
declaration, check whether per-argument validation parameters have been considered:

| Parameter | Flag it missing if… |
| --- | --- |
| `required: true` | The command always fails without this argument, making the Ruby caller's error clearer before spawning a process |
| `allow_nil: false` | The argument is optional in Ruby (no `required: true`), but `nil` should be rejected rather than treated as "not provided" — for example, passing `nil` would produce an invalid CLI argument or ambiguous behavior |

All option DSL methods (`flag_option`, `value_option`, `flag_or_value_option`,
`key_value_option`, `custom_option`) default to `allow_nil: true`. `operand`
defaults to `allow_nil: false`. Specify `allow_nil: false` on options when nil must
be rejected explicitly. Only specify `allow_nil: true` on operands when
distinguishing an explicit `nil` from "not provided" is semantically important; do
not flag its absence when the default is correct.

**`allow_nil: true` on `required:` arguments:** flag as suspicious — allowing nil on
a required argument is rarely correct.

Do **not** flag the absence of these parameters as issues when no meaningful
constraint exists for that argument — omitting them is correct in that case.

**Cross-argument constraint methods are generally not used in command classes.** Do
not flag the absence of `conflicts`, `requires`, `requires_one_of`,
`requires_exactly_one_of`, `forbid_values`, or `allowed_values` as a completeness
issue. Command classes use per-argument validation parameters (`required:`,
`allow_nil:`, etc.) and operand format validation. Git validates its own option
semantics. There are two narrow exceptions:

1. **Arguments git cannot observe in its argv** — the test is: does this argument
   appear in git's argv? If no (e.g., `skip_cli: true` operands routed via stdin),
   git cannot detect incompatibilities and constraint declarations are appropriate
   and should not be flagged as policy violations. Example: `cat-file --batch`
   declares `conflicts :objects, :batch_all_objects` and `requires_one_of :objects,
   :batch_all_objects` because `:objects` is `skip_cli: true`.
2. **Git-visible arguments that cause silent data loss** — if a combination of
   git-visible arguments causes git to silently discard data (no error, wrong
   result), a `conflicts` declaration MAY be added with: a code comment explaining
   why, a reference to the git version(s) where the behavior was verified, and a
   test. As of this writing, no such case has been identified.

## 7. Check class-level declarations

The following class-level declarations are **not** part of `arguments do` but should
be verified alongside DSL entries. The canonical rules live in [Command
Implementation](../command-implementation/REFERENCE.md) — see
[Exit status guidance](../command-implementation/REFERENCE.md#exit-status-guidance)
and [`requires_git_version` convention](../command-implementation/REFERENCE.md#requires_git_version-convention). Briefly:

- **`allow_exit_status`** — present with a `Range` and rationale comment when the
  command has non-zero successful exits.
- **`requires_git_version`** — present only when the command was introduced after
  `Git::MINIMUM_GIT_VERSION`; uses a `'major.minor.patch'` string.
- **`` @note `arguments` block audited against https://git-scm.com/docs/git-{command}/<version> ``** —
  present in the class-level YARD doc block. Flag as an error if: (1) the note is
  missing, (2) the version in the URL is not the current latest git version, or
  (3) the note appears in the wrong position (it must appear after all `@example`
  blocks and before any `@see` tags — i.e. the canonical tag order is description
  → `@example` → `@note` → `@see` → `@api private`).
  To get the current latest version, run `bin/latest-git-version` from the repo root.
  A stale version means the DSL may be missing options added in subsequent git
  releases.
