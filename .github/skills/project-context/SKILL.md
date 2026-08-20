---
name: project-context
description: 'Reference guide for ruby-git architecture, coding standards, design philosophy, key technical details, and compatibility requirements. Use when answering architecture questions, deciding where new code belongs, reviewing coding standards, or understanding the layered command/parser/facade design.'
---

# Project Context

Reference for ruby-git's architecture, coding standards, design philosophy, and
technical constraints. Load this skill when answering questions about code structure,
where logic belongs, or how the layers interact.

## Contents

- [How to use this skill](#how-to-use-this-skill)
- [Related skills](#related-skills)
- [Architecture & Module Organization](#architecture--module-organization)
- [Layer Responsibilities](#layer-responsibilities)
- [Coding Standards](#coding-standards)
- [Design Philosophy](#design-philosophy)
- [Key Technical Details](#key-technical-details)
- [Compatibility](#compatibility)
- [Performance](#performance)
- [Implementation Notes](#implementation-notes)

## How to use this skill

Attach this file to your Copilot Chat context when you need architecture guidance,
coding standard details, or implementation constraints.

## Related skills

- [Development Workflow](../development-workflow/SKILL.md) — TDD cycle and commit
  conventions for day-to-day work
- [Command Implementation](../command-implementation/SKILL.md) — generating and
  reviewing command classes in the layered architecture
- [Facade Implementation](../facade-implementation/SKILL.md) — generating and
  reviewing `Git::Repository::*` facade methods, the gem's public API layer
- [YARD Documentation](../yard-documentation/SKILL.md) — documentation
  standards

## Architecture & Module Organization

**Key modules and their roles:**

| Class | Role |
| --- | --- |
| `Git::Repository` | Main facade — entry point for all user-facing operations; methods live in `Git::Repository::*` topic modules under `lib/git/repository/`, included into the class |
| `Git::ExecutionContext::*` | Configured subprocess runner; holds binary path, env vars, and global opts; provides `#command_capturing`/`#command_streaming` to command classes |
| `Git::Commands::*` | Command classes: define CLI API, bind args, execute → return `CommandLineResult` |
| `Git::CommandLine` | Subprocess execution: escaping, timeout, stdout/stderr capture |
| `Git::Parsers::*` | Transform raw stdout into structured data |
| `Git::Object::*` | Immutable Git objects (Commit, Tree, Blob, Tag) |
| `Git::Status` | Working-directory status (enumerable `StatusFile` collection) |
| `Git::Diff` | Diff operations (enumerable `DiffFile` collection) |
| `Git::Log` | Chainable commit-history query builder |
| `Git::Branch/Branches` | Branch management (local + remote) |
| `Git::Remote` | Remote repository references |
| `Git::Worktree/Worktrees` | Worktree support |
| `Git::Stash/Stashes` | Stash management |

**Key directories:**

- `lib/git/` — Core library code
- `lib/git/commands/` — Command classes (new architecture)
- `lib/git/repository/` — Facade topic modules (`Git::Repository::*`)
- `spec/unit/` — RSpec unit tests (mocked execution context)
- `spec/integration/` — RSpec integration tests (real git repositories)
- `spec/support/` — Shared test contexts and helpers
- `redesign/` — Record of the completed v5.x architectural redesign. History, not
  current policy; current standards live in `.github/skills/`

## Layer Responsibilities

The three-layer architecture separates concerns cleanly:

```
Git::Repository (facade — topic modules under lib/git/repository/)
  └── Git::Commands::* (defines CLI API, binds args, executes via execution_context)
        └── Git::ExecutionContext::* (configured subprocess runner: env, binary, global opts)
              └── Git::CommandLine (subprocess execution)
```

- **Commands layer** (`Git::Commands::*`): Owns the git CLI contract. Declares
  arguments via DSL, executes command, returns `CommandLineResult`. No parsing.
  - `literal` entries are **only** for operation selectors (subcommand names,
    mode flags like `--delete` that define what the class does). Output-format
    flags, parser-contract options, and other caller-controlled options belong as
    `flag_option` / `value_option` — not as `literal` entries.
  - Each command class represents **one operation**, not one output format.
    Output-mode flags (`--patch`, `--numstat`, `--raw`, `--format=…`) are options
    declared in the DSL; the facade chooses which to pass. Separate subclasses
    for the same operation with different output modes are an anti-pattern.
- **Parser layer** (`Git::Parsers::*`): Transforms raw stdout/stderr into structured
  Ruby data. No execution.
- **Facade layer** (`Git::Repository::*`): Pre-processes caller arguments, invokes
  the right command class, calls parsers, constructs rich response objects.
  **Parser-contract options** (e.g. `no_color: true`, `pretty: 'raw'`,
  `format: FORMAT_STRING`) are passed explicitly at the facade call site — this makes
  the parser contract auditable by reading the topic module method.

`Git::Commands::Base` provides default `#initialize(execution_context)` and `#call`.
Command classes that need non-zero successful exits declare
`allow_exit_status <Range>` with a rationale comment.

### Command-layer neutrality

Command classes are neutral, faithful representations of the git CLI. They declare
options via the DSL but never embed policy choices (output-control flags, editor
suppression, progress, verbose mode). The facade (`Git::Repository::*`) sets safe defaults
at each call site. Some defaults are **fixed** (not in `ALLOWED_OPTS` — rejected by
`assert_valid_opts!` before reaching the command); others are **overridable** (in
`ALLOWED_OPTS`, placed before the caller's `**opts` so the caller's value wins).
The execution layer (`GIT_EDITOR='true'`) is an unconditional safety net.

> **Anti-pattern:** `literal '--no-edit'`, `literal '--verbose'`,
> `literal '--no-progress'` inside a command class.
>
> **Correct pattern:** `flag_option :edit, negatable: true` in the command;
> `no_edit: true` passed from the facade call site.

### Validation Boundaries

This section is the authority on what command classes validate and what they delegate
to git. Skills that need the rule link here.

Command classes use per-argument validation parameters (`required:`, `type:`,
`allow_nil:`, etc.) and operand format validation. They generally do **not** declare
cross-argument constraint methods (`conflicts`, `requires`, `requires_one_of`,
`requires_exactly_one_of`, `forbid_values`, `allowed_values`) — git is the single source
of truth for its own option semantics. There are two narrow exceptions — **arguments
git cannot observe in its argv**, and **git-visible combinations that make git silently
discard data** — both spelled out under
[Exception criteria for constraint declarations](#exception-criteria-for-constraint-declarations).

| Validated by Commands | Mechanism |
| --- | --- |
| Unknown options | `validate_unsupported_options!` in Arguments DSL |
| Required options | `required: true` in Arguments DSL |
| Type checking | `type:` in Arguments DSL |
| Option-like operand rejection | Automatic for operands before `--` |

| Delegated to git (semantic) | Surfaced as |
| --- | --- |
| Option conflicts (`--soft` vs `--hard`) | `Git::FailedError` |
| Option dependencies (`--all-match` requires `--grep`) | `Git::FailedError` |
| At-least-one-of groups | `Git::FailedError` |
| Value-set membership | `Git::FailedError` |
| Forbidden value combinations | `Git::FailedError` |

The constraint DSL infrastructure (`conflicts`, `requires`, `requires_one_of`,
`requires_exactly_one_of`, `forbid_values`, `allowed_values`) remains available in
`Git::Commands::Arguments` and is kept intact, but command classes reach for it only
under the exception criteria below.

#### Exception criteria for constraint declarations

The test: **does this argument appear in git's argv?**

- **Yes** (normal `flag_option`, `value_option`, etc.) — git can observe it and report
  the error, so do not declare a constraint.
- **No** — the argument is consumed entirely on the Ruby side and has no argv
  representation at all: `skip_cli: true` operands, `execution_option` entries, and
  anything else that never becomes a token git can see. Git has no mechanism to detect
  incompatibilities, so Ruby must enforce them with a constraint declaration.

This is about *presence in argv*, not about transformation. Every DSL entry transforms
something — `flag_option :force` turns `force: true` into `--force` — and those still
belong to the **Yes** branch, because `--force` reaches git and git can object to it.

The canonical case is `skip_cli: true` operands routed via stdin. `cat-file --batch`
commands declare both `conflicts :object, :batch_all_objects` and
`requires_one_of :object, :batch_all_objects`. `:object` is `skip_cli: true`, so it
reaches git over stdin rather than in argv — git does receive the object names, but it
has no argv token to reason about them with, and `--batch-all-objects` makes it discard
stdin unread. Both failure modes are therefore silent:

| Passed | What git does | Exit |
| --- | --- | --- |
| both | ignores stdin, dumps the entire object database | 0 |
| neither | reads nothing from stdin, emits nothing | 0 |

Neither is an error git can report, so Ruby must enforce those constraints.

The distinction matters when reasoning about a new command: `skip_cli: true` means
*absent from argv*, not *invisible to git*. A stdin-fed value git still reads is covered
by this exception because git cannot correlate it with the argv flags, not because git
never receives it.

`Git::Commands::Archive` is the other shape: it declares `conflicts :output, :out`
because `:out` is an `execution_option` naming a Ruby IO object to stream into. Only
`--output` reaches argv, so git cannot see that both were requested.

A secondary exception: if a combination of **git-visible** arguments causes git to
**silently discard data** (no error, wrong result), a `conflicts` declaration MAY be
added with a code comment explaining why, a reference to the git version(s) where the
behavior was verified, and a test.

One command deviates from the argv-visibility rule above (not from this secondary
exception). `Git::Commands::CatFile::Raw` declares
`requires_one_of :t, :s, when: :allow_unknown_type` on a git-visible `flag_option`
that git already rejects in other modes. It predates this policy and is not a
template — see the note in
[Command Implementation](../command-implementation/REFERENCE.md#options-completeness--consult-the-latest-version-docs-first).

#### Why the semantic checks are delegated

1. **Git is the single source of truth.** Git validates its own option interactions and
   reports clear errors via stderr, surfaced as `Git::FailedError`. Ruby-side constraints
   duplicate that validation and risk going stale — potentially blocking valid usage when
   git relaxes a restriction in a newer version.
2. **Partial coverage is worse than none.** Inconsistent constraint coverage creates a
   false promise of safety: users cannot tell whether the absence of an `ArgumentError`
   means "this combination is valid" or "this command has no constraints."
3. **Constraint violations are programming errors.** A developer who passes conflicting
   options must stop and fix their code either way, so the cost difference between
   `ArgumentError` and `Git::FailedError` is negligible.
4. **Uniform error semantics.** Every *semantic* rejection in the delegated table
   above surfaces the same way — `Git::FailedError` carrying git's actual message —
   rather than as a mix of Ruby constraint errors and git rejections. The
   per-argument checks in the first table still raise `ArgumentError`; the split is
   between "this call is malformed" and "git says no", not between two arbitrary
   error classes.

## Coding Standards

### Ruby Style

- `frozen_string_literal: true` at the top of every Ruby file
- Ruby 3.2.0+ idioms; keyword arguments for multi-parameter methods
- `private` keyword form (not `private :method_name`)
- Pattern matching for complex conditionals where appropriate

### Naming

| Kind | Convention | Example |
| --- | --- | --- |
| Class/Module | PascalCase | `Git::CommandLine` |
| Method/variable | snake_case | `current_branch` |
| Constant | UPPER_SNAKE_CASE | `VERSION` |
| Predicate | ends with `?` | `bare?` |
| Mutating method | ends with `!` | `reset!` |
| Parsed metadata struct (top-level `Git::`) | `*Info` suffix | `BranchInfo`, `TagInfo`, `StashInfo` |
| Mutating-operation outcome struct (top-level `Git::`) | `*Result` suffix | `BranchDeleteResult`, `TagDeleteResult` |

**Result class constraints:**

- `*Info` / `*Result` suffixes are reserved for top-level `Git::` data structs.
  Never apply them to `Git::Commands::*` classes — command classes are subprocess
  runners, not data structs, and a name like `Commands::Foo::BarInfo` misleads
  readers.
- Never name a sub-command class `Object` — it shadows Ruby's `::Object`.

### Code Organization

- Single-responsibility classes; one public class per file as a general rule
- Tightly-coupled helper classes may share a file
- Core code in `lib/git/`; command classes in `lib/git/commands/`

### Documentation

- YARD for all public methods: `@param`, `@return`, `@raise`, `@example`
- Use `@overload` with explicit keyword params when methods use `**`
- `@api private` on internal methods
- Document edge cases, platform differences, security considerations

## Design Philosophy

See [CONTRIBUTING.md](../../CONTRIBUTING.md) for authoritative, complete guidelines.

**Summary:**

- **Lightweight wrapper** — minimal abstraction over `git` CLI
- **Principle of least surprise** — predictable, follows git conventions
- **Direct CLI mapping** — `git add` → `Git::Repository#add`; use prefix + suffix for
  multi-purpose commands (`#ls_files_untracked`, `#ls_files_staged`)
- **Parameter naming** mirrors long CLI options
- **Rich output objects** — translate git output to Ruby objects when useful to
  callers
- **No unnecessary extensions** — stay close to git's actual behavior

## Key Technical Details

### Error Hierarchy

All gem errors inherit from `Git::Error`:

- `Git::FailedError` — non-zero exit status
- `Git::SignaledError` — killed by signal
- `Git::TimeoutError` — exceeded timeout (subclass of `SignaledError`)
- `ArgumentError` — invalid arguments

All errors include structured data (command, output, status) for debugging. Never
swallow exceptions silently.

### Path Handling

- Working-directory paths: relative to repo working directory
- Paths stored as `Pathname` objects on `Git::Repository`
- `Git::EscapedPath` for paths with special characters
- Handle Windows path separators; test with Unicode filenames

### Encoding

- Use `rchardet` for automatic encoding detection
- Handle UTF-8, ASCII, and platform-default encodings
- Be aware of binary vs. text mode differences on Windows

### Timeouts

- Global timeout configurable; per-command override available
- `Git::TimeoutError` is raised on expiry
- Built into `Git::CommandLine`; document implications in YARD

### Dependencies

- `activesupport` (≥ 5.0) — utilities and deprecation handling
- `addressable` (~> 2.8) — URI parsing
- `process_executer` (~> 4.0) — subprocess execution with timeout
- `rchardet` (~> 1.9) — character encoding detection

## Compatibility

- **Minimum Ruby (language level):** 3.2.0
- **Supported Rubies:** MRI (macOS, Linux, Windows); latest JRuby and TruffleRuby on Linux
- **Minimum Git:** 2.28.0
- **Platforms:** macOS, Linux, Windows (JRuby/TruffleRuby officially supported on Linux only)
- Use `File.join` and forward slashes; avoid platform-specific paths in tests
- Windows has different path handling, file-system behavior, and line endings; JRuby on Windows is not supported
- Document git version requirements for features that need newer git

## Performance

### Commands and subprocesses

- Commands execute with global or per-command configurable timeout
- Subprocess execution is handled by `Git::CommandLine`; do not shell out directly
- Clean up resources (file handles, temp files) after every operation
- Handle large repository operations efficiently

### Memory

- Lazy-load Git objects when possible; cache appropriately
- Stream large outputs rather than buffering everything
- Be mindful of memory with large diffs and logs

### Repository operations

- Minimize Git command executions; use batch operations where possible
- Cache Git objects when appropriate
- Consider performance implications of deep history traversal

## Implementation Notes

### Adding new commands

Follow the three-layer pattern: command class (CLI contract) → parser (output
transform) → `Git::Repository::*` facade method (orchestration + rich object). See
[Command Implementation](../command-implementation/SKILL.md).

### Working with paths

- Store as `Pathname`; use `Git::EscapedPath` for special chars
- Test with Unicode filenames and Windows separators

### Working with repository objects

- Handle missing/invalid objects gracefully
- Test with all object types (commits, trees, blobs, tags)

### Security

- Use `Git::CommandLine` for all command execution — it handles proper escaping
- Validate and sanitize user-supplied paths and arguments
- Document security implications in YARD
- Be aware of git hook execution risks
