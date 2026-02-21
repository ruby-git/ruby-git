# Review YARD Documentation

Verify YARD documentation for command classes is complete, accurate, and aligned
with the `Git::Commands::Base` pattern.

## How to use this prompt

Attach this file to your Copilot Chat context, then invoke it with one or more
command source files whose YARD docs should be reviewed. Examples:

```text
Using the Review YARD Documentation prompt, review
lib/git/commands/branch/delete.rb.
```

```text
Review YARD Documentation: lib/git/commands/stash/push.rb
lib/git/commands/stash/pop.rb
```

The invocation needs the command file(s) to review.

## Related prompts

- **Review Arguments DSL** — verifying DSL entries match git CLI
- **Review Command Implementation** — class structure, phased rollout gates, and
  internal compatibility contracts
- **Review Command Tests** — unit/integration test expectations for command classes

## Input

One or more command files from `lib/git/commands/` containing:

- `class < Git::Commands::Base`
- `arguments do ... end`
- optional `allow_exit_status`
- `# @!method call(*, **)` YARD directive with nested `@overload` blocks

## Required documentation model

Each command must use the `@!method` YARD directive to attach per-command
documentation to the inherited `call` method:

```ruby
# @!method call(*, **)
#
#   @overload call(**options)
#
#     Execute the git ... command.
#
#     @param options [Hash] command options
#
#     @option options [Boolean] :force (nil) ...
#
#     @return [Git::CommandLineResult]
```

This directive is documentation scaffolding — YARD uses it to render per-command
docs on the inherited `call` method without requiring a method definition in the
subclass.

## What to Check

### 1. Class-level docs

- [ ] one-line summary
- [ ] brief behavior description
- [ ] `@api private`
- [ ] `@see` to parent command module where applicable
- [ ] `@see` to relevant git docs

### 2. Arguments docs

- [ ] `@overload` blocks cover valid call shapes
- [ ] every positional arg has `@param`
- [ ] every applicable option has `@option`
- [ ] `@option` entries appear in the same order as the corresponding entries in
      the `arguments do` block
- [ ] `@option` types match the DSL method used to define the option:

  | DSL method | YARD type |
  |---|---|
  | `flag_option` | `[Boolean]` |
  | `flag_or_value_option` | `[Boolean, String]` (or the specific value type) |
  | `value_option` | `[String]` (or a more specific type where known) |
  | `operand` (repeatable) | `[Array<String>]` |
  | `operand` (single) | `[String]` |

- [ ] option defaults/types are consistent with DSL definitions

### 3. Return and raise tags

- [ ] `@return [Git::CommandLineResult]` with wording:
      `the result of calling \`git <subcommand>\``
- [ ] `@raise [Git::FailedError]` reflects range-based behavior
      (outside default `0..0` or declared `allow_exit_status` range)

### 4. `allow_exit_status` rationale consistency

When command declares non-default exit range:

- [ ] includes short rationale comment above declaration
- [ ] YARD `@raise` text does not contradict accepted status behavior

### 5. Formatting consistency

- [ ] blank comment line before each YARD tag block
- [ ] `@option` description text starts with a capital letter (sentence case)
- [ ] consistent option wording and defaults across sibling commands
- [ ] no stale references to removed per-command implementation details

### 6. Avoid internal implementation detail leakage

Prefer interface-level wording (what callers can pass/expect), not internals.

## Common issues

- Missing `# @!method call(*, **)` directive (loses child-specific docs in generated YARD)
- `@option` docs out of sync with `arguments do`
- Missing/incorrect `@raise` guidance for `allow_exit_status`
- Legacy references to `ARGS` constant or command-specific `initialize`

## Output

For each file, provide:

1. issue table

   | Check | Status | Issue |
   | --- | --- | --- |

2. corrected doc block snippets (only where needed)

> **Branch workflow:** Implement any fixes on a feature branch. Never commit or
> push directly to `main` — open a pull request when changes are ready to merge.
