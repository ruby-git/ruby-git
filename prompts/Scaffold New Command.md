# Scaffold New Command

Generate a production-ready command class, unit tests, integration tests, and YARD
docs using the `Git::Commands::Base` architecture.

## How to use this prompt

Attach this file to your Copilot Chat context, then invoke it with the git
subcommand name and the Ruby module path for the new class. Examples:

```text
Using the Scaffold New Command prompt, scaffold Git::Commands::Worktree::Add
for `git worktree add`.
```

```text
Scaffold New Command: Git::Commands::LsTree for `git ls-tree`.
```

The invocation needs the target `Git::Commands::*` class name and the git
subcommand (or subcommand + sub-action) it wraps.

## Related prompts

- **Review Command Implementation** — canonical class-shape checklist, phased
  rollout gates, and internal compatibility contracts
- **Review Arguments DSL** — verifying DSL entries match git CLI
- **Review Command Tests** — unit/integration test expectations for command classes
- **Review YARD Documentation** — documentation completeness for command classes

## Files to generate

For `Git::Commands::Foo::Bar`:

- `lib/git/commands/foo/bar.rb`
- `spec/unit/git/commands/foo/bar_spec.rb`
- `spec/integration/git/commands/foo/bar_spec.rb`

Optional (first command in module):

- `lib/git/commands/foo.rb`

## Command template (Base pattern)

```ruby
# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Foo
      # Summary...
      #
      # @api private
      class Bar < Git::Commands::Base
        arguments do
          # literals/options/operands
        end

        # Optional: for commands where non-zero exits are valid
        # rationale comment
        # allow_exit_status 0..1

        # @!method call(*, **)
        #
        #   @overload ...
        #
        #     Execute the git ... command.
        #
        #     @return [Git::CommandLineResult] the result of calling `git ...`
        #
        #     @raise [Git::FailedError] if git exits outside allowed status range
      end
    end
  end
end
```

## Output-format options are intentionally omitted

The library requires **deterministic, parseable output** from each command class.
For this reason, options that change the **structure or format** of a command's
primary output are **deliberately excluded** from the DSL.

Do **not** add options such as `--format=`, `--pretty=`, `--porcelain`,
`--patch`, `--stat`, `--numstat`, `--shortstat`, `--raw`, `--name-only`, or
`--name-status`. Including them would allow callers to produce output that a
parser cannot handle.

**Do** include options that do not affect stdout — for example `--dry-run`/`-n`,
`--force`, `--ignore-errors`, etc.

The test for any option, including `--verbose`/`-v` and `--quiet`/`-q`: run the
command with and without the option and diff stdout. If stdout changes → exclude
it. Do not assume verbosity flags are safe sidechannel options; verify first.

## DSL ordering convention

**Primary rule:** define arguments in the order they appear in the git-scm.com
SYNOPSIS for the command. This keeps the DSL self-documenting and makes it easy
to verify completeness against the man page.

Within a group where the SYNOPSIS does not impose an order (e.g., a block of
interchangeable flags), prefer:

1. literals
2. flag options
3. flag-or-value options
4. value options, immediately followed by `allowed_values` for any option that
   accepts only a fixed set of strings — `allowed_values` supersedes ad-hoc
   `validator:` lambdas for enumerated cases:

   ```ruby
   value_option :cleanup, inline: true
   allowed_values :cleanup, in: %w[verbatim whitespace strip]
   ```

5. operands (positional args)

6. separator-delimited pathspec entries — either form:

   - `operand :pathspec, repeatable: true, separator: '--'` (positional calling convention)
   - `value_option :pathspec, as_operand: true, separator: '--', repeatable: true` (keyword calling convention)

   **When to use each form** — consult the git-scm.com SYNOPSIS:

   - **`--` present** (e.g., `[<tree-ish>] [--] [<pathspec>...]`) → use the **keyword
     form** (`value_option … as_operand: true`). The post-`--` group is
     *independently reachable*; a caller must be able to supply pathspecs without
     also providing a tree-ish. Without the keyword form, a single positional value
     would silently bind to the first operand (the tree-ish), making pathspec-only
     calls impossible.

     ```ruby
     operand :tree_ish                                             # positional
     value_option :pathspec, as_operand: true, separator: '--',   # keyword
                  repeatable: true
     # cmd.call                               → git <sub>
     # cmd.call('HEAD~3')                     → git <sub> HEAD~3
     # cmd.call(pathspec: ['file.rb'])        → git <sub> -- file.rb
     # cmd.call('HEAD~3', pathspec: ['f.rb']) → git <sub> HEAD~3 -- f.rb
     ```

   - **`--` absent / pure nesting** (e.g., `[<commit1> [<commit2>]]`) → use **two
     plain `operand` entries**. The second is only meaningful when the first is
     present, so left-to-right positional binding is unambiguous.

     ```ruby
     operand :commit1   # optional
     operand :commit2   # optional — only meaningful when commit1 is given
     # cmd.call                    → git <sub>
     # cmd.call('HEAD~3')          → git <sub> HEAD~3
     # cmd.call('HEAD~3', 'HEAD')  → git <sub> HEAD~3 HEAD
     ```

   Constraint declarations always come last, after all arguments they reference
   are defined:

7. `conflicts` declarations — presence-based mutual exclusion

8. `forbid_values` declarations — exact-value tuple constraints for negatable
   flags where some value-pairings are contradictory but others are equivalent:

   ```ruby
   forbid_values all: true,  ignore_removal: true   # contradictory
   forbid_values all: false, ignore_removal: false  # contradictory
   # allows: all: true + ignore_removal: false (equivalent pair)
   ```

9. `requires_exactly_one_of` declarations — when a group must have exactly one
   member present. Replaces the two-declaration pattern of `requires_one_of` +
   `conflicts` for the same names:

   ```ruby
   requires_exactly_one_of :mode_a, :mode_b, :mode_c
   ```

   This is equivalent to (but preferred over):

   ```ruby
   requires_one_of :mode_a, :mode_b, :mode_c
   conflicts       :mode_a, :mode_b, :mode_c
   ```

10.  `requires_one_of` declarations (unconditional and `when:` conditional forms) —
    use these when only an at-least-one constraint is needed (no at-most-one)

11.  `requires` declarations (single-argument conditional form)

Use aliases for long/short forms (`%i[force f]`, `%i[all A]`, `%i[intent_to_add N]`),
with long name first. The DSL preserves symbol case, so uppercase single-char aliases
like `:A` and `:N` correctly produce `-A` and `-N` without needing `as:`.
`as:` is an escape hatch — it emits its value verbatim, bypassing the DSL's
automatic name-to-flag mapping. This removes the property that a reviewer can
verify the flag by reading the symbol name alone, so every use of `as:` adds a
manual audit burden. Avoid it unless one of these three cases applies:

1. **Ruby keyword conflict** — the git flag's natural name is a Ruby keyword and
   cannot be written as a symbol literal. Rename the alias and supply the real
   flag via `as:`:
   ```ruby
   flag_option %i[begin_rev], as: '--begin'
   ```

2. **Combined short flag** — git accepts a repeated short flag in combined form
   (e.g. `--force --force` → `-ff`) and there is no single long-form equivalent:
   ```ruby
   flag_option %i[force_force ff], as: '-ff'
   ```

3. **Multi-token flag** — the option must emit two or more CLI tokens. Pass an
   array (valid on `flag_option` only):
   ```ruby
   flag_option :double_force, as: ['--force', '--force']
   ```

Outside these cases, a DSL entry that uses `as:` where a plain symbol or alias
would work should be corrected.

When two or more arguments are mutually exclusive — options, operands, or a mix —
declare them with `conflicts`. Names may be option names or operand names.
Unknown names raise `ArgumentError` at load time.

**Presence semantics:** a value is present when it is not `nil`, `[]`, or `''`. For
**negatable flag options** (`negatable: true`), `false` also counts as present
because it emits `--no-flag`. Non-negatable `false` is absent.

Examples:

```ruby
conflicts :gpg_sign, :no_gpg_sign        # option vs option
conflicts :merge, :tree_ish              # option vs operand
```

When a group of mutually exclusive arguments also requires **exactly one** member to
be present, use `requires_exactly_one_of` instead of separate `requires_one_of` +
`conflicts` declarations. It combines both constraints in a single declaration and
eliminates the risk of the two lists diverging:

```ruby
requires_exactly_one_of :mode_a, :mode_b, :mode_c
```

This is equivalent to (but preferred over):

```ruby
requires_one_of :mode_a, :mode_b, :mode_c
conflicts       :mode_a, :mode_b, :mode_c
```

When at least one of a group of arguments must be present — options, operands, or
a mix — but the group is **not** mutually exclusive, declare it with `requires_one_of`.
Names may be option names or operand names. Unknown names raise `ArgumentError` at
load time. Examples:

```ruby
requires_one_of :pathspec, :pathspec_from_file   # at least one option required
requires_one_of :all, :paths                     # option or operand required
```

When an argument is only required if a *specific trigger* argument is present, use
`requires` (single name) or `requires_one_of ... when:` (group). Both forms skip
the check when the trigger is absent. Unknown names raise `ArgumentError` at load
time.

**Presence semantics (trigger):** the trigger fires when its value is not `nil`,
`false`, `[]`, or `''`. A negatable flag set to `false` means the feature is **off**;
the trigger does **not** fire. The satisfied-by check uses the same rule as
`conflicts`: negatable `false` counts as present.

Examples:

```ruby
# Single: :pathspec_from_file must be present whenever :pathspec_file_nul is present
requires :pathspec_from_file, when: :pathspec_file_nul
# Single: :dry_run must be present whenever :ignore_missing is present
requires :dry_run,            when: :ignore_missing

# Group: at least one of :message/:file must be present whenever :annotate is present
requires_one_of :message, :file, when: :annotate
requires_one_of :message, :file, when: :sign
requires_one_of :message, :file, when: :local_user
```

## Exit status guidance

- Default: no declaration needed (`0..0` from `Base`)
- Non-default: declare `allow_exit_status <range>` and add rationale comment

Examples:

```ruby
# git diff exits 1 when differences are found (not an error)
allow_exit_status 0..1
```

```ruby
# fsck uses exit codes 0-7 as bit flags for findings
allow_exit_status 0..7
```

## Unit tests

Command unit tests should verify:

- exact arguments passed to `execution_context.command`
- inclusion of `raise_on_failure: false` (from `Base` behavior)
- execution-option forwarding where relevant (`timeout:`, etc.)
- allow-exit-status behavior where declared
- input validation (`ArgumentError`)

## Integration tests

Minimal structure:

- `describe 'when the command succeeds'`
- `describe 'when the command fails'`

Include at least one failure case per command.

## YARD requirements

- use `# @!method call(*, **)` YARD directive with nested `@overload` blocks for per-command docs
- add `@overload` blocks for valid call shapes, indented under `@!method`
- keep tags aligned with `arguments do` and `allow_exit_status` behavior

## Phased rollout, compatibility, and quality gates

See **Review Command Implementation** for the canonical phased rollout checklist,
internal compatibility contract, and quality gate commands. In summary:

- **always work on a feature branch** — never commit or push directly to `main`;
  create a branch before starting (`git checkout -b <feature-branch-name>`) and
  open a pull request when the slice is ready
- migrate in small slices (pilot or family), not all commands at once
- keep each slice independently revertible
- pass per-slice gates: `bundle exec rspec`, `bundle exec rake test`,
  `bundle exec rubocop`, `bundle exec yard`
