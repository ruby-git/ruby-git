## Arguments DSL Review for `Git::Commands::*` Classes

### Goal

Verify that the `ARGS` definition in a `Git::Commands::*` class accurately and completely maps Ruby keyword arguments to the correct git CLI flags, in the correct order, using the correct DSL methods.

### Input

You will be given:
1. One or more command source files containing an `ARGS = Arguments.define` block
2. The git man page or documentation for the subcommand being implemented

### How Arguments Work

The `Arguments` DSL generates CLI arguments from Ruby method calls. Key behaviors:

- **Output order matches definition order** — the `ARGS.bind(*, **)` call produces CLI arguments in the exact order they are defined in the `Arguments.define` block
- **Name-to-flag mapping** — Ruby symbol names are automatically converted to CLI flags: underscores become hyphens, single-char names get `-x`, multi-char get `--name` (e.g., `:merge_base` → `--merge-base`, `:M` → `-M`)
- **Custom `args:` override** — the `args:` parameter overrides the automatic name-to-flag mapping (e.g., `flag_option :find_copies, args: '-C'`). Only needed when no Ruby symbol name maps to the correct flag.
- **Aliases** — `flag_option %i[cached staged]` means both `:cached` and `:staged` in Ruby map to `--cached` on the CLI. The first name is canonical and determines the generated flag. **The long option name must always be first** — single-char symbols generate `-x` while multi-char symbols generate `--name`, so `%i[f force]` would incorrectly generate `-f` instead of `--force`.
- **Long/short aliases** — when git has both long and short forms (e.g., `-f`/`--force`), use an alias like `%i[force f]` (long name first) instead of `args:`. This generates `--force` from the canonical name and provides both `:force` and `:f` as caller keywords.

### What to Check

#### 1. Correct DSL Method for Each Option

Each git option type maps to a specific DSL method:

| Git option behavior | DSL method | Example |
|---------------------|------------|---------|
| Always present (fixed flag) | `literal` | `literal '--numstat'` |
| Boolean on/off (`--flag` or nothing) | `flag_option` | `flag_option :cached` |
| Boolean or string (`--flag` or `--flag=val` or nothing) | `flag_or_value_option` | `flag_or_value_option :dirstat, inline: true` |
| Takes a required value (`--flag value`) | `value_option` | `value_option :message` |
| Takes a value inline (`--flag=value`) | `value_option` with `inline: true` | `value_option :format, inline: true` |
| Positional argument (no flag) | `operand` | `operand :commit1` |
| Pathspecs after `--` separator | `value_option` with `as_operand: true, separator: '--'` | `value_option :pathspecs, as_operand: true, separator: '--', repeatable: true` |

**Common mistakes:**
- Using `flag_option` for an option that can also take a value (should be `flag_or_value_option`)
- Using `flag_or_value_option` for an option that is purely boolean (should be `flag_option`)
- Using `literal` for an option the caller should be able to toggle (should be `flag_option`)
- Missing `inline: true` on options that use `=` syntax (e.g., `--dirstat=lines`)
- Missing `repeatable: true` on options that can appear multiple times
- Missing `as_operand: true` on value options that output without a flag prefix

#### 2. Correct `args:` Overrides

The `args:` parameter should only be used when **no Ruby symbol name** maps to the correct git flag via the automatic convention.

**Prefer aliases over `args:`** — when git has both a long form (`--force`) and a short form (`-f`), use an alias array where the canonical (first) name maps to the correct long flag:
- `flag_option %i[force f]` → generates `--force`, callers can use `force:` or `f:` ✓
- `flag_option %i[all a]` → generates `--all`, callers can use `all:` or `a:` ✓
- `flag_option %i[remotes r]` → generates `--remotes`, callers can use `remotes:` or `r:` ✓

**Use `args:` only when the automatic mapping is wrong:**
- `:find_copies` → automatic produces `--find-copies`, but git uses `-C` → needs `args: '-C'`
- `:cached` → automatic produces `--cached` → correct, no override needed
- `:merge_base` → automatic produces `--merge-base` → correct, no override needed

**`args:` is redundant with aliases when the first name already maps correctly:**
- `flag_option %i[force f], args: '--force'` — redundant, `%i[force f]` already generates `--force` ✗
- `flag_option %i[remotes r], args: '--remotes'` — redundant ✗
- `flag_option :all, args: '-a'` — forces short flag instead of using `%i[all a]` alias ✗

**Common mistakes:**
- Missing `args:` when the git flag doesn't match any symbol name (e.g., `-C` has no natural Ruby mapping)
- Using `args:` to force a short flag when an alias would be more consistent (prefer `%i[all a]` over `:all, args: '-a'`)
- Redundant `args:` on an alias where the canonical name already maps correctly
- Wrong flag in `args:` (e.g., typo or wrong short flag)

#### 3. Correct Aliases

Aliases let multiple Ruby keyword names map to the same CLI flag. They serve two purposes:

1. **Semantic synonyms** — `%i[cached staged]` gives callers two equivalent names
2. **Long/short forms** — `%i[force f]` provides both `:force` and `:f` keywords while generating the long `--force` flag

**Check:**
- `flag_option %i[cached staged]` — both `:cached` and `:staged` should produce `--cached`
- `flag_option %i[force f]` — both `:force` and `:f` should produce `--force`
- The first name in the array is the canonical name (used for flag generation) and **must be the long option name** — a single-char first name would generate `-x` instead of the intended `--long-name`
- All alias names should be semantically equivalent in git
- Options with well-known short forms in git (e.g., `-f`, `-r`, `-a`, `-u`, `-t`, `-i`) should use aliases

**Common mistakes:**
- Putting the short name first in the alias array (e.g., `%i[f force]` generates `-f` instead of `--force`)
- Using `args:` to force a short flag instead of using an alias (prefer `%i[all a]` over `:all, args: '-a'`)
- Aliases for options that aren't truly equivalent in git
- Missing aliases for well-known git option short forms

#### 4. Correct Definition Order

CLI output follows definition order, so the ARGS block must list entries in the order they should appear on the command line. The convention is:

```
1. literals (subcommand name, then fixed flags)
2. flag_options
3. flag_or_value_options
4. operands (positional arguments)
5. value_options with as_operand: true (typically pathspecs last)
```

**Check:**
- Subcommand literal comes first (e.g., `literal 'diff'`)
- Fixed format flags follow (e.g., `literal '--numstat'`)
- Options come after literals
- Operands come after options
- Pathspecs come last (with `separator: '--'`)

**Common mistakes:**
- Operand defined before an option — would place the positional argument before the flag in CLI output
- Pathspec `value_option` defined before operands — would put `-- pathspecs` before commit operands
- Literals in wrong order (e.g., `--patch` before `diff`)

#### 5. Correct Modifiers

| Modifier | Purpose | When needed |
|----------|---------|-------------|
| `inline: true` | Output `--flag=value` instead of `--flag value` | Options using `=` syntax (e.g., `--dirstat=lines`, `--format=%H`) |
| `as_operand: true` | Output value without flag prefix | Pathspecs, file arguments that aren't preceded by a flag |
| `separator: '--'` | Insert `--` before values | Pathspec separator convention |
| `repeatable: true` | Accept arrays, repeat per value | Options/operands that can appear multiple times |
| `negatable: true` | Output `--no-flag` for `false` | Options with explicit negation in git |
| `required: true` | Raise if not provided | Mandatory options/operands |
| `allow_nil: true` | Nil consumes slot but produces no output | Optional positional args that may be absent |

**Common mistakes:**
- Missing `repeatable: true` on pathspecs (most commands accept multiple pathspecs)
- Missing `inline: true` on `flag_or_value_option` for options like `--dirstat=lines`
- Using `repeatable: true` on non-repeatable options
- Missing `separator: '--'` on pathspec-style value options

#### 6. Completeness

Every git option the command supports should be represented in ARGS. Cross-reference against:
- The git man page for the subcommand
- The calling conventions documented in `@overload` blocks
- The unit tests (each test verifies specific ARGS entries)

**Check for:**
- Options listed in YARD docs but missing from ARGS
- Options in ARGS that aren't tested
- Git options mentioned in the man page that should be supported but aren't defined

#### 7. Conflicts

If the command has mutually exclusive options, they should be declared:

```ruby
conflicts :cached, :no_index  # can't use both --cached and --no-index
```

**Check:**
- Mutually exclusive git options have corresponding `conflicts` declarations
- Conflict groups don't include options that can legitimately be combined

### Verification Steps

For each ARGS entry, verify this chain:

```
Ruby call                    → ARGS.bind output          → git CLI
command.call(cached: true)   → ['--cached']              → git diff --cached
command.call(dirstat: 'lines') → ['--dirstat=lines']     → git diff --dirstat=lines
command.call('abc', 'def')   → ['abc', 'def']            → git diff abc def
```

1. **Symbol → flag mapping**: Does the symbol name (with automatic or custom `args:`) produce the correct git flag?
2. **Value handling**: Does the DSL method correctly handle the value type (boolean, string, array)?
3. **Output position**: Is the entry defined in the right position relative to other entries?

### Output

Produce a table with one row per ARGS entry:

| # | DSL method | Definition | CLI output | Correct? | Issue |
|---|------------|------------|------------|----------|-------|
| 1 | `literal` | `'diff'` | `diff` | Yes | — |
| 2 | `literal` | `'--numstat'` | `--numstat` | Yes | — |
| 3 | `flag_option` | `:find_copies, args: '-C'` | `-C` | Yes | `args:` needed — no symbol maps to `-C` |
| 4 | `flag_option` | `:cached` | `--cached` | **No** | Should be `%i[cached staged]` for alias |
| 5 | `flag_option` | `:all, args: '-a'` | `-a` | **No** | Should be `%i[all a]` — use alias, not `args:` |

Then list any missing options, ordering issues, or modifier problems found.
