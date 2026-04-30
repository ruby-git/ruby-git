---
name: facade-yard-documentation
description: "Facade-specific YARD documentation rules for Git::Repository::* topic modules and their facade methods, overriding and extending the general yard-documentation skill. Use when writing or reviewing YARD docs for facade modules under lib/git/repository/."
---

# Facade YARD Documentation

Write and verify YARD documentation for facade modules and methods on
`Git::Repository::*`. This skill overrides and extends the general
[YARD Documentation](../yard-documentation/SKILL.md) skill with facade-specific
rules.

The facade is the **public API surface** of the gem. Facade docs describe what
the caller passes and what they get back — never the internal command class,
parser, or execution context that implements the behavior.

## Contents

- [Related skills](#related-skills)
- [Input](#input)
- [Reference](#reference)
  - [Module-level docs](#module-level-docs)
  - [Method-level docs](#method-level-docs)
  - [Documenting forwarded options with `@overload`](#documenting-forwarded-options-with-overload)
  - [Return type rules](#return-type-rules)
  - [`@raise` rules](#raise-rules)
  - [Cross-referencing the implementation](#cross-referencing-the-implementation)
  - [Common issues](#common-issues)
- [Workflow](#workflow)
- [Output](#output)

## Related skills

- [YARD Documentation](../yard-documentation/SKILL.md) — authoritative source for
  general YARD formatting rules; **must be loaded** as a prerequisite
- [Facade Implementation](../facade-implementation/SKILL.md) — facade module
  structure and orchestration patterns
- [Facade Test Conventions](../facade-test-conventions/SKILL.md) — unit and
  integration test conventions for facade methods
- [Command YARD Documentation](../command-yard-documentation/SKILL.md) — sibling
  skill for the underlying command classes (different rules — facade docs do
  **not** mirror command DSL)

## Input

Before starting, you **MUST** load the following skill(s) in their entirety:

- [YARD Documentation](../yard-documentation/SKILL.md) — authoritative source for
  YARD formatting rules and writing standards

Then gather:

1. **Facade module source** — `lib/git/repository/<topic>.rb`
2. **Underlying command class(es)** — `lib/git/commands/<command>.rb` for each
   command the facade method calls. Use these to confirm option semantics, but
   do **not** copy the command's `@option` docs verbatim — the facade only
   exposes the options it documents in its public contract.
3. **Underlying parser/result class** — when the facade returns a structured
   value, read the parser or result class to confirm the documented return type.

## Reference

### Module-level docs

Every facade module under `lib/git/repository/` requires a module-level YARD
block:

```ruby
module Git
  class Repository
    # Short summary of the topic and the facade methods it provides
    #
    # Included by {Git::Repository}.
    #
    # @api public
    #
    module Topic
      # ...
    end
  end
end
```

Module-level tags appear in the order required by
[YARD Documentation — Modules](../yard-documentation/SKILL.md#element-specific-rules):
`@note`, `@deprecated`, `@see`, `@api`. (Facade modules do not use module-level
`@example` — see the override note below.)

Required tags:

- [ ] short summary describing the topic (e.g. "Facade methods for staging-area
  operations: adding and resetting files") — follows the short-description
  rules in [YARD Documentation](../yard-documentation/SKILL.md)
- [ ] sentence noting "Included by {Git::Repository}." with the YARD link
- [ ] `@api public` — every facade module is part of the public API

Do **not** add:

- `@see Git::Commands::*` at the module level — implementation detail
- `@see https://git-scm.com/docs/...` at the module level — git man-page
  links belong on the individual facade methods, where the link maps directly
  to the command being invoked. A module typically groups several facade
  methods (sometimes spanning multiple git commands), so a single module-level
  link is misleading; for single-command modules it is redundant with the
  method-level link.
- `@example` blocks at the module level — **facade-specific override of
  [YARD Documentation — Modules](../yard-documentation/SKILL.md#element-specific-rules)**,
  which permits module-level `@example` when a module provides standalone
  methods. Facade modules do provide standalone methods, but every facade
  method already carries its own `@example`, so a module-level example would
  be redundant. Examples belong on the methods.

### Method-level docs

Every facade method requires full YARD docs. Two acceptable forms:

**Form A — `@overload` with anonymous splat in the `def`** (the **default**
for any method that forwards positional args and/or keyword options unchanged
to the underlying command). The `def` uses an anonymous splat — `**`, `*`, or
`...` — to satisfy RuboCop's `Style/ArgumentsForwarding` cop, and the
`@overload` block introduces named parameters that `@param` and `@option` bind
to:

```ruby
# Update the index with the current content found in the working tree
#
# @overload add(paths = '.', **options)
#
#   @example Stage all changed files
#     repo.add
#
#   @example Stage a specific file
#     repo.add('README.md')
#
#   @param paths [String, Array<String>] a file or files to add (relative to
#     the worktree root); defaults to `'.'` (all files)
#
#   @param options [Hash] options for the add command
#
#   @option options [Boolean] :all (false) add, modify, and remove index
#     entries to match the worktree
#
#   @option options [Boolean] :force (false) allow adding otherwise ignored
#     files
#
#   @return [String] git's stdout from the add
#
# @raise [ArgumentError] if unsupported options are provided
#
# @raise [Git::FailedError] if `git add` exits with a non-zero status
#
def add(paths = '.', **)
  Git::Repository::Internal.assert_valid_opts!(ADD_ALLOWED_OPTS, **)
  Git::Commands::Add.new(@execution_context).call(*Array(paths), **).stdout
end
```

See [Documenting forwarded options with
`@overload`](#documenting-forwarded-options-with-overload) for the rationale
and variations (`*`, `...`, multiple call shapes).

**Form B — direct doc comment on a fully named signature** (the **narrow
exception**: use only when the method body must inspect or mutate the options
hash before forwarding it, or when the signature has no splat at all). When
the `def` has a named parameter for every documented argument, `@param` and
`@option` bind directly:

```ruby
# Commit staged changes
#
# @example Commit with a message
#   repo.commit('Initial commit')
#
# @example Amend the previous commit
#   repo.commit('Updated message', amend: true)
#
# @param message [String] the commit message
#
# @param opts [Hash] commit options
#
# @option opts [Boolean] :amend (false) amend the previous commit
#
# @return [String] git's stdout from the commit
#
# @raise [ArgumentError] if unsupported options are provided
#
# @raise [Git::FailedError] if `git commit` exits with a non-zero status
#
def commit(message, opts = {})
  Git::Repository::Internal.assert_valid_opts!(COMMIT_ALLOWED_OPTS, **opts)
  opts = opts.merge(message: message) if message
  Git::Commands::Commit.new(@execution_context).call(no_edit: true, **opts).stdout
end
```

Form B is required here because the method body needs a named variable (`opts`)
to build and transform before forwarding — e.g. `opts.merge(message: message)`
returns a new hash that is assigned back, and `opts = deprecate_commit_no_gpg_sign_option(opts)`
reassigns it; an anonymous `**` in the `def` provides no named variable to
operate on.

When a method has multiple genuinely distinct call shapes (e.g.
`commit(message)` vs. `commit(message, opts)` with materially different
return types), use one `@overload` block per shape — see
[YARD Documentation — Overload
template](../yard-documentation/SKILL.md#overload-template).

Required elements (apply to both forms):

- [ ] one-line summary describing what the method does from the caller's
  perspective (not "calls `Git::Commands::Foo`")
- [ ] at least one `@example` block with a descriptive title (required on every
  public facade method; use representative input and show the return value)
- [ ] `@param` for every positional parameter, with type and short description
- [ ] `@param <name> [Hash]` preceding any `@option` tags — the name comes
  from the `@overload` signature (e.g. `options` or `opts`) when the actual
  `def` uses anonymous `**` for `Style/ArgumentsForwarding`; otherwise it
  matches the named parameter on the `def` itself
- [ ] `@option` for every option the facade exposes (the caller-facing contract,
  not every option the underlying command accepts)
- [ ] `@return` with the **documented public return type** (see [Return type
  rules](#return-type-rules))
- [ ] `@raise` for every error the caller can hit (see [`@raise`
  rules](#raise-rules))

### Documenting forwarded options with `@overload`

When a facade method forwards positional args and/or keyword options unchanged
to the underlying command, keep the anonymous splat (`**`, `*`, or `...`) in
the `def` (so `Style/ArgumentsForwarding` stays satisfied) and document the
call shape with an `@overload` block that names the parameters — Form A in
[Method-level docs](#method-level-docs) above shows the canonical `add`
example.

Key constraints:

- **Do not** name the splat — or expand `...` into `*args, **kwargs, &block` —
  solely to make `@param`/`@option` bind. **Do not** suppress
  `Style/ArgumentsForwarding` with `# rubocop:disable`. The `@overload` form is
  the project-standard resolution.
- The `@overload` signature owns the parameter names; `@param`, `@option`,
  `@yield`, and `@yieldparam` tags inside the overload bind to those names.
- When a facade method has multiple distinct call shapes (e.g.
  `commit(message)` vs. `commit(message, **opts)`), write one `@overload`
  block per shape.
- Form B (named splat, direct doc comment) is the narrow exception — use only
  when the body inspects or mutates the options hash before forwarding it.
- The **anonymous block parameter (`&`)** is not covered by this rule.
  `@yield`/`@yieldparam`/`@yieldreturn` describe what is yielded rather than
  the block parameter itself, so anonymous `&` is fine. Name the block
  (`&block`) only when documenting it as a first-class `Proc` value.

See the general
[YARD Documentation — Documenting anonymous splats with `@overload`](../yard-documentation/SKILL.md#documenting-anonymous-splats-with-overload)
for the underlying rule.

### Return type rules

The `@return` annotation must reflect the **public contract** of the facade
method, not the type of the underlying call expression.

| Facade does | `@return` type |
|---|---|
| Returns the raw `CommandLineResult` | `[Git::CommandLineResult]` |
| Returns `result.stdout` (chomped or raw) | `[String]` |
| Returns parsed structured data via a parser | The parser's return type (e.g. `[Array<Git::BranchInfo>]`, `[Hash]`) |
| Returns a result-class instance via a factory | The result class (e.g. `[Git::BranchDeleteResult]`) |
| Returns a single Boolean derived from the result | `[Boolean]` |

Never write `@return [Git::Commands::Foo::Result]` — command-class result types
are internal. Surface `Git::CommandLineResult` only when the topic module's
documented contract is to expose raw results.

### `@raise` rules

- Always include `@raise [Git::FailedError]` for any facade method that can
  cause git to exit non-zero. Use the canonical generic wording matching the
  command's exit-status range:

  | Command's `allow_exit_status` | Facade `@raise` wording |
  |---|---|
  | none / `0..0` | `if git exits with a non-zero exit status` |
  | `0..1` | `if git exits outside the allowed range (exit code > 1)` |

- When the facade calls `assert_valid_opts!`, include
  `@raise [ArgumentError] if unsupported options are provided`.
- When the facade itself validates arguments and raises (e.g. "you must specify
  a remote if a branch is specified"), document with a specific `@raise
  [ArgumentError]` line that names the constraint.
- Do **not** enumerate specific git failure causes (no "if the branch doesn't
  exist", no "if the working tree is dirty"). Use the generic form.

### Cross-referencing the implementation

When useful, cross-link to the underlying components with `@see` tags **at the
end** of the method's doc block:

```ruby
# @see Git::Commands::Branch::List
# @see Git::Parsers::Branch
# @see https://git-scm.com/docs/git-branch git-branch
```

Use sparingly — only when the cross-link helps a reader navigate to non-obvious
internals. Do not add `@see` for every command and parser by default; trivial
delegators do not need them.

### Common issues

- **`@return [Git::CommandLineResult]` on a method that actually returns a
  parsed value.** Match the actual return value, not the inner call expression.
- **Copying `@option` blocks from the command class.** The facade exposes only
  the options listed in its public contract (and the `<METHOD>_ALLOWED_OPTS`
  whitelist when present). Do not copy every option the command DSL declares.
- **Documenting policy defaults as caller options.** When the facade hardcodes
  `no_edit: true`, do not list `:no_edit` as a caller option. The facade's contract
  is "non-interactive commit"; mention the policy in prose if relevant, not as
  an `@option`.
- **Documenting the underlying command in the summary.** Wrong: "Calls
  `Git::Commands::Add.#call`". Right: "Update the index with the current
  content found in the working tree."
- **Leaking `Git::ExecutionContext::Repository` into docs.** The execution
  context is injected once at construction; facade method docs do not mention
  it.
- **Missing `@example` on a public method.** Every public facade method requires
  at least one `@example` block with a descriptive title. Examples belong on the
  method, not at the module level.
- **Missing `@param <name> [Hash]` before `@option` tags.** Every `@option` tag
  requires a preceding `@param` for the options hash. Use the parameter name from
  the `@overload` signature when the `def` uses anonymous `**`.
- **Missing `@api public` on the module.** Every facade module is part of the
  public API and must declare it.
- **Uppercase first letter or trailing period on tag short descriptions.** Same
  rule as command YARD: lowercase start, no trailing punctuation on the short
  description.
- **Raw blank line inside a doc comment block.** A line with no leading `#`
  silently terminates the YARD block. Use blank comment lines (`#`) inside
  multi-paragraph descriptions.

## Workflow

For each facade module file, run through these checks in order:

### 1. Module-level docs

- [ ] short topic summary (per
  [YARD Documentation](../yard-documentation/SKILL.md) short-description rules)
- [ ] "Included by {Git::Repository}." sentence with the YARD link
- [ ] `@api public`
- [ ] no `@example` at the module level
- [ ] no `@see Git::Commands::*` at the module level
- [ ] no `@see https://git-scm.com/docs/...` at the module level (those belong
  on the individual facade methods)

### 2. Method-level docs (per method)

- [ ] one-line summary describing caller-facing behavior
- [ ] at least one `@example` block with a descriptive title
- [ ] every positional parameter has `@param` with type and short description
- [ ] every facade-exposed option has `@option` (matching the
  `<METHOD>_ALLOWED_OPTS` whitelist when present)
- [ ] when `@option` is used, `@param <name> [Hash]` precedes the `@option`
  tags; for methods using `@overload`, the parameter name comes from the
  overload signature (e.g. `@overload add(paths, **options)`) — the `def`
  may still use anonymous `**`
- [ ] options that exist on the underlying command but are not exposed by the
  facade are **not** listed
- [ ] policy defaults the facade hardcodes are not listed as `@option`
- [ ] `@return` matches the actual return value type per [Return type
  rules](#return-type-rules)
- [ ] `@raise` tags follow [`@raise` rules](#raise-rules)
- [ ] `@see` tags appear at the end and are limited to non-obvious cross-links

### 3. Formatting consistency

- [ ] every YARD tag is preceded by a blank comment line (`#`)
- [ ] no raw blank lines inside any doc block
- [ ] tag short descriptions start lowercase and have no trailing punctuation
- [ ] multi-paragraph tag descriptions have a blank `#` line between paragraphs
- [ ] all general formatting rules from
  [YARD Documentation](../yard-documentation/SKILL.md) are satisfied

## Output

### When writing new facade YARD docs

Produce the complete YARD doc block(s) for the module and each method, then
self-verify by running every checklist item from [Workflow](#workflow) against
your output. Fix and re-verify until all checks pass.

### When reviewing existing facade YARD docs

For each file, provide:

1. issue table

   | Check | Status | Issue |
   | --- | --- | --- |

2. corrected doc block snippets (only where needed)

3. **Self-verify before concluding** — re-run every checklist item against
   your proposed snippets until all checks pass.

> **Branch workflow:** Implement any fixes on a feature branch. Never commit or
> push directly to `main` — open a pull request when changes are ready to merge.
