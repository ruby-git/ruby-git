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

---

## Review YARD Documentation

Verify YARD documentation for command classes is complete, accurate, and aligned
with the `Git::Commands::Base` pattern.

### Related prompts

- **Review Arguments DSL** — verifying DSL entries match git CLI
- **Review Command Implementation** — class structure, phased rollout gates, and
  internal compatibility contracts
- **Review Command Tests** — unit/integration test expectations for command classes

### Input

One or more command files from `lib/git/commands/` containing:

- `class < Base`
- `arguments do ... end`
- optional `allow_exit_status`
- one-line method shim `def call(...) = super`

### Required documentation model

Because YARD does not attach command-specific `@overload` docs to purely inherited
methods, each command must keep:

```ruby
def call(...) = super # rubocop:disable Lint/UselessMethodDefinition
```

This method is documentation scaffolding and should have full per-command YARD tags.
The rubocop disable comment suppresses the Lint/UselessMethodDefinition warning that
occurs because the method appears "useless" to the linter (it is required for YARD).

### What to Check

#### 1. Class-level docs

- [ ] one-line summary
- [ ] brief behavior description
- [ ] `@api private`
- [ ] `@see` to parent command module where applicable
- [ ] `@see` to relevant git docs

#### 2. Arguments docs

- [ ] `@overload` blocks cover valid call shapes
- [ ] every positional arg has `@param`
- [ ] every applicable option has `@option`
- [ ] option defaults/types are consistent with DSL definitions

#### 3. Return and raise tags

- [ ] `@return [Git::CommandLineResult]` with wording:
      `the result of calling \`git <subcommand>\``
- [ ] `@raise [Git::FailedError]` reflects range-based behavior
      (outside default `0..0` or declared `allow_exit_status` range)

#### 4. `allow_exit_status` rationale consistency

When command declares non-default exit range:

- [ ] includes short rationale comment above declaration
- [ ] YARD `@raise` text does not contradict accepted status behavior

#### 5. Formatting consistency

- [ ] blank comment line before each YARD tag block
- [ ] consistent option wording and defaults across sibling commands
- [ ] no stale references to removed per-command implementation details

#### 6. Avoid internal implementation detail leakage

Prefer interface-level wording (what callers can pass/expect), not internals.

### Common issues

- Missing `def call(...) = super` (loses child-specific docs in generated YARD)
- `@option` docs out of sync with `arguments do`
- Missing/incorrect `@raise` guidance for `allow_exit_status`
- Legacy references to `ARGS` constant or command-specific `initialize`

### Output

For each file, provide:

1. issue table

| Check | Status | Issue |
|---|---|---|

2. corrected doc block snippets (only where needed)
