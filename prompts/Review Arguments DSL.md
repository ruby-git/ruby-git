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

---

## Review Arguments DSL

Verify that a command class's `arguments do ... end` definition accurately maps Ruby
call arguments to git CLI arguments, in the correct order, with the correct DSL
methods and modifiers.

### Related prompts

- **Review Command Implementation** — class structure, phased rollout gates, and
  internal compatibility contracts
- **Review Command Tests** — unit/integration test expectations for command classes
- **Review YARD Documentation** — documentation completeness for command classes

### Input

You will be given:
1. One or more command source files containing a `class < Base` and an
   `arguments do` block
2. The git man page or documentation for the subcommand

### Architecture Context (Base Pattern)

Command classes now follow this structure:

- `class < Git::Commands::Base`
- class-level `arguments do ... end`
- optional `allow_exit_status <range>` for commands where non-zero exits are valid
- one-line YARD shim: `def call(...) = super # rubocop:disable Lint/UselessMethodDefinition`

The CLI argument mapping is still defined exclusively by the Arguments DSL. The
`Base` class handles binding and execution.

### How Arguments Work

Key behaviors:

- **Output order matches definition order** — bound arguments are emitted in the
  order entries appear in `arguments do`
- **Name-to-flag mapping** — underscores become hyphens, single-char names map to
  `-x`, multi-char names map to `--name`
- **`as:` override** — only for flags that cannot be expressed by symbol naming
  (e.g., `-C`)
- **Aliases** — first alias is canonical and determines generated flag (long name
  first: `%i[force f]`, not `%i[f force]`)
- **Operand naming** — use the parameter name from the git-scm.com man page, in
  singular form (e.g., `<file>` → `:file`, `<tag>` → `:tag`). The `repeatable: true`
  modifier already communicates that multiple values are accepted; pluralising the
  name is unnecessary and diverges from the docs.

### What to Check

#### 1. Correct DSL method per option type

| Git behavior | DSL method | Example |
|---|---|---|
| fixed flag always present | `literal` | `literal '--numstat'` |
| boolean flag | `flag_option` | `flag_option :cached` |
| boolean-or-value | `flag_or_value_option` | `flag_or_value_option :dirstat, inline: true` |
| value option | `value_option` | `value_option :message` |
| execution kwarg (not a CLI arg) | `execution_option` | `execution_option :timeout` |
| positional argument | `operand` | `operand :commit1` |
| pathspec-style operands | `value_option ... as_operand: true, separator: '--'` | `value_option :pathspecs, as_operand: true, separator: '--', repeatable: true` |

#### 2. Correct alias and `as:` usage

- Prefer aliases for long/short pairs (`%i[force f]`, `%i[all a]`)
- Use `as:` only when automatic mapping cannot generate the git flag
- Ensure long name is first in alias arrays

#### 3. Correct ordering

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
7. `requires_one_of` declarations

#### 4. Correct modifiers

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

Also validate `inline:`, `negatable:`, `allow_nil:`, `separator:`, and
`as_operand:` are applied where appropriate.

#### 5. Completeness

Cross-check against:
- git docs
- command `@overload` docs
- command unit tests

Every supported option should be represented in `arguments do`, and every DSL entry
should be covered by tests.

#### 6. Conflicts

If arguments are mutually exclusive — whether option vs option, option vs operand,
or operand vs operand — verify `conflicts ...` declarations exist. Names in a
`conflicts` group may be any mix of option names and operand names. Unknown names
raise `ArgumentError` at definition time, so any typo is caught early.

#### 7. At-Least-One Validation

If a command requires at least one argument from a group to be present — options,
operands, or a mix — verify `requires_one_of ...` declarations exist. As with
`conflicts`, names may be any mix of option names and operand names. Alias
resolution applies before the check, so supplying an alias counts as its canonical
argument being present. Unknown names raise `ArgumentError` at definition time.

The error at bind time has the form:

  "at least one of :name1, :name2 must be provided"

#### 8. Exit-status declaration consistency (class-level, outside the DSL)

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

### Verification Chain

For each DSL entry, verify:

`Ruby call -> bound argument output -> expected git CLI`

### Output

Produce:

1. A per-entry table:

| # | DSL method | Definition | CLI output | Correct? | Issue |
|---|---|---|---|---|---|

2. A list of missing options/modifier/order/conflict issues
3. Any `allow_exit_status` mismatches or missing rationale comments

> **Branch workflow:** Implement any fixes on a feature branch. Never commit or
> push directly to `main` — open a pull request when changes are ready to merge.
