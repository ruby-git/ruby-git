# Bucket 6 Decision Brief — `Git::Lib` Orphaned Public Methods

**Date:** 2026-06-09

**Branch:** `agents/redesignc1c2bucket6decisionbrief`

**Companion to:** `redesign/c1c2_audit.md` §7.3

- [1. Purpose](#1-purpose)
- [2. The ❌ Confirmed Removal](#2-the--confirmed-removal)
  - [`list_files(ref_dir)`](#list_filesref_dir)
- [3. Decision Items](#3-decision-items)
  - [3.1 `change_head_branch(branch_name)`](#31-change_head_branchbranch_name)
  - [3.2 `config_get(name)`, `config_list`, and `config_set(name, value, options = {})`](#32-config_getname-config_list-and-config_setname-value-options--)
    - [`config_get(name)`](#config_getname)
    - [`config_list`](#config_list)
    - [`config_set(name, value, options = {})`](#config_setname-value-options--)
  - [3.3 `global_config_get(name)`, `global_config_list`, and `global_config_set(name, value)`](#33-global_config_getname-global_config_list-and-global_config_setname-value)
    - [`global_config_get(name)`](#global_config_getname)
    - [`global_config_list`](#global_config_list)
    - [`global_config_set(name, value)`](#global_config_setname-value)
  - [3.4 `parse_config(file)`](#34-parse_configfile)
  - [3.5 `stash_list`](#35-stash_list)
  - [3.6 `unmerged`](#36-unmerged)
- [4. Pre-resolved questions](#4-pre-resolved-questions)
  - [4.1 Global config API surface breadth (§3.3) — **Resolved**](#41-global-config-api-surface-breadth-33--resolved)
  - [4.2 `change_head_branch` guard semantics (§3.1) — **Resolved**](#42-change_head_branch-guard-semantics-31--resolved)
  - [4.3 `config()` overload complexity with `:file` for reads (§3.4) — **Resolved**](#43-config-overload-complexity-with-file-for-reads-34--resolved)
  - [4.4 Semver classification of `stash_list` non-promotion (§3.5) — **Resolved**](#44-semver-classification-of-stash_list-non-promotion-35--resolved)
- [5. Next Steps](#5-next-steps)

---

## 1. Purpose

This document is the companion decision brief for the 10 🔍 human-decision
items and 1 ❌ confirmed removal identified in §7.3 of
`redesign/c1c2_audit.md`. Each of those items is a public method on
`Git::Lib` that has no existing `Git::Repository` facade and therefore has no
safe landing place when `Git::Lib` is deleted in Phase 4. Before the final
Bucket 6 remediation work (PR 5h+) can begin, a human reviewer must examine
each item, evaluate the concrete options provided below, and record a binding
decision in the **Decision** field of the relevant section. Once all 11 items
are resolved, this document serves as the authoritative specification for
whoever opens PR 5h.

---

## 2. The ❌ Confirmed Removal

### `list_files(ref_dir)`

**Current implementation:** Constructs the path
`File.join(@git_dir, 'refs', ref_dir)` and returns
`Dir.glob('**/*', base: dir).select { |f| File.file?(...) }` — a raw
filesystem walk over the `.git/refs/` directory tree. No git command is
invoked; this is pure internal plumbing that bypasses the git object model
entirely.

**Why it must go:** There is no plausible clean public use for directly
walking `.git/refs/`. Callers who need to enumerate refs should use the
`git for-each-ref` family of commands, which is already surfaced via
`Git::Repository::Branching`, `Git::Repository::ObjectOperations`, and the
various ref-inspection methods on `Git::Repository`. Exposing filesystem
access to the packed-refs store would be misleading and would silently break
on repositories that use the packed-refs file instead of loose ref files.

**Upgrade note for callers:**

> Direct `repo.lib.list_files` calls are unsupported. Use
> `Git::Repository` ref-inspection methods (e.g., `branches`, `tags`,
> `remotes`) instead.

**Action required:** Add this note to `UPGRADING.md`. No migration
path is provided.

---

## 3. Decision Items

### 3.1 `change_head_branch(branch_name)`

**Signature:** `change_head_branch(branch_name)`

**Description:** Calls
`Git::Commands::SymbolicRef::Update.new(self).call('HEAD', "refs/heads/#{branch_name}")`,
which is a direct write of the `HEAD` symbolic reference to
`refs/heads/<branch_name>`. This is equivalent to
`git symbolic-ref HEAD refs/heads/<name>` and is how git implements branch
renaming and orphan-branch checkout under the hood. `Git::Lib` uses it
internally in at least two workflows. There is no `Git::Base` delegator.

**Context:** No existing `Git::Repository` facade covers this operation.
The `Git::Commands::SymbolicRef::Update` command class already exists and is
wired correctly. The operation is low-level and requires caller awareness: pointing HEAD at a
branch that does not yet exist places the repository in unborn-branch state,
which is valid and intentional for initialization workflows but unexpected if
done by mistake. It is exactly what external tooling (e.g., repository
initialization scripts, branch-rename utilities) needs when git's own
higher-level commands are not available. No test-suite usage was found for
direct `lib.change_head_branch` calls, which suggests no external callers
have relied on it via `g.lib`.

**Options:**

- **A — Promote to `Git::Repository::Branching`:** Add a public facade
  method `change_head_branch(branch_name)` with appropriate YARD docs and a
  `Git::Base` delegator. Surface the footgun risk in the documentation.
- **B — Mark as internal:** Leave the method behind `private` in `Git::Lib`
  and document that it has no public equivalent. Callers requiring this
  low-level operation must use `git symbolic-ref` directly.
- **C — Promote with a guard:** Promote as Option A but add a guard that
  raises `ArgumentError` when the target branch does not exist locally.

**Recommendation:** **Option A.** The operation has genuine tooling utility
and the command class is already in place, making the implementation cost
low. No guard should be added: the unborn-branch workflow — pointing HEAD
at a branch that does not yet exist before any commits land — is a
first-class git pattern used by repository initialization tooling. A guard
that rejects non-existent branches would silently break that workflow (see
§4.2). Promote to `Git::Repository::Branching` as a clean pass-through with
clear documentation explaining unborn-branch semantics.

**Decision:** Accepted. Promote `change_head_branch(branch_name)` to `Git::Repository::Branching` with a `Git::Base` delegator. No guard. Document unborn-branch semantics in YARD.

**Status:** ✅ Implemented — facade in `Git::Repository::Branching` + `Git::Base` delegator added (PR 5h-1).

---

### 3.2 `config_get(name)`, `config_list`, and `config_set(name, value, options = {})`

These three are treated together because they are the low-level primitives
that the existing `Git::Repository::Configuring#config()` facade already
dispatches to internally. The key question is whether to expose them as
additional public methods or to clarify that `config()` already covers all
three cases.

#### `config_get(name)`

**Signature:** `config_get(name)`

**Description:** Calls `Git::Commands::ConfigOptionSyntax::Get`, raises
`Git::FailedError` if the exit status is non-zero, and returns the raw
stdout string (the config value, newline-stripped).

**Context:** `Git::Repository::Configuring#config(name)` (one-argument form)
already calls the identical private helper `Private.config_get` with
identical behavior. The two implementations are functionally the same.
There is no `Git::Base` delegator.

#### `config_list`

**Signature:** `config_list`

**Description:** Calls `Git::Commands::ConfigOptionSyntax::List` and parses
the output into a `Hash{String => String}` via `parse_config_list`.

**Context:** `Git::Repository::Configuring#config()` (zero-argument form)
already calls the identical private helper `Private.config_list` and returns
the same hash. Functionally identical.

#### `config_set(name, value, options = {})`

**Signature:** `config_set(name, value, options = {})`

**Description:** Validates options against `CONFIG_SET_ALLOWED_OPTS =
%i[file]` and calls `Git::Commands::ConfigOptionSyntax::Set`. The `:file`
option allows writing to an arbitrary config file rather than the default
`.git/config`. The facade `config(name, value, options = {})` also accepts
a `:file` option and calls the same `Set` command.

**Context:** `Git::Repository::Configuring#config(name, value)` (two-argument
form) already calls the identical private helper `Private.config_set` with
the same `:file` passthrough. Functionally identical.

**Options for all three:**

- **A — Mark as covered; no new public methods:** Document in the upgrade
  guide that `config_get`, `config_list`, and `config_set` are now accessed
  via the unified `config()` facade, and that callers should migrate to
  `repo.config`, `repo.config(name)`, and `repo.config(name, value)`
  respectively.
- **B — Promote all three as public aliases:** Add `config_get`, `config_list`,
  and `config_set` as public methods on `Git::Repository::Configuring` that
  simply delegate to the private helpers, giving callers a named-method API.
- **C — Partial promotion:** Promote only `config_set` (since it takes extra
  options that users may wish to call explicitly) while documenting that
  `config_get` and `config_list` are covered by the overloaded `config()`.

**Recommendation:** **Deprecated forwarding aliases over `config()`, with Option A as the canonical v5 API.**
The `config()` facade is already a clean, well-documented, three-overload API
that covers every case. Adding parallel methods with the same behavior would
create API surface duplication without benefit in the long term. However, to
preserve backward compatibility, also add `config_get`, `config_list`, and
`config_set` as deprecated forwarding methods on `Git::Repository::Configuring`
(and corresponding `Git::Base` delegators), each emitting a runtime warning
via `Git::Deprecation.warn`:

```ruby
# @deprecated Use {#config} instead.
def config_get(name)
  Git::Deprecation.warn(
    'config_get is deprecated and will be removed in a future version. ' \
    'Use config(name) instead.'
  )
  config(name)
end

# @deprecated Use {#config} instead.
def config_list
  Git::Deprecation.warn(
    'config_list is deprecated and will be removed in a future version. ' \
    'Use config instead.'
  )
  config
end

# @deprecated Use {#config} instead.
def config_set(name, value, opts = {})
  Git::Deprecation.warn(
    'config_set is deprecated and will be removed in a future version. ' \
    'Use config(name, value) instead.'
  )
  config(name, value, opts)
end
```

Callers drop the `.lib.` prefix and get a runtime deprecation warning; no
method-name change is required until v6. Remove all three aliases in v6.

**Decision:** Accepted. Add deprecated forwarding methods `config_get`, `config_list`, and `config_set` to `Git::Repository::Configuring` with `Git::Deprecation.warn` calls pointing to `config()`. Add `Git::Base` delegators. Remove in v6.

---

### 3.3 `global_config_get(name)`, `global_config_list`, and `global_config_set(name, value)`

These three are treated together as the global-config variants of the local
config primitives above.

#### `global_config_get(name)`

**Signature:** `global_config_get(name)`

**Description:** Identical to `config_get` except it passes `global: true`
to `Git::Commands::ConfigOptionSyntax::Get`, targeting `~/.gitconfig` (or
`$XDG_CONFIG_HOME/git/config`) rather than the repository's `.git/config`.

#### `global_config_list`

**Signature:** `global_config_list`

**Description:** Identical to `config_list` except it passes `global: true`
to `Git::Commands::ConfigOptionSyntax::List`.

#### `global_config_set(name, value)`

**Signature:** `global_config_set(name, value)`

**Description:** Calls `Git::Commands::ConfigOptionSyntax::Set` with
`global: true`, writing to the user's global git config. Takes no `:file`
option (global mode is mutually exclusive with `--file`).

**Context:** This is a **genuine gap** in the current `Git::Repository`
API. Unlike the local config methods above, `Git::Repository::Configuring#config()`
has no `:global` option and provides no way to read or write global config
at all. Any caller currently using `g.lib.global_config_get(name)` would
lose that capability entirely under v5 with no migration path unless this
gap is addressed.

**Options:**

- **A — Add a `:global` option to `config()`:** Extend the existing facade
  with `config(name = nil, value = nil, global: false, **options)`. All
  three overloads (get, list, set) would gain a global variant by passing
  `global: true`. Keeps the API surface minimal.
- **B — Add dedicated `global_config_get/list/set` methods:** Mirror the
  `Git::Lib` names exactly as public methods on `Git::Repository::Configuring`.
  More discoverable by name; no overloading.
- **C — Add a separate `global_config(name = nil, value = nil)` facade:**
  A parallel unified method that follows the same dispatch logic as `config()`
  but targets global config. Clean API symmetry, no keyword arg overloading.

**Recommendation:** **Option C, with backward-compatible deprecated aliases.**
A dedicated `global_config()` method with identical dispatch logic to
`config()` (list/get/set based on argument count) gives the cleanest API
symmetry. Option A risks a confusing mix of positional and keyword arguments
on an already-overloaded method. Option B re-introduces three separate names
when the project has already committed to the unified `config()` pattern.
`global_config()` is obvious, memorable, and mirrors the existing `config()`
contract exactly.

To preserve backward compatibility, also add the three `Git::Lib` names as
deprecated forwarding methods on `Git::Repository::Configuring` (and
corresponding `Git::Base` delegators):

```ruby
# @deprecated Use {#global_config} instead.
def global_config_get(name)
  Git::Deprecation.warn(
    'global_config_get is deprecated and will be removed in a future version. ' \
    'Use global_config(name) instead.'
  )
  global_config(name)
end

# @deprecated Use {#global_config} instead.
def global_config_list
  Git::Deprecation.warn(
    'global_config_list is deprecated and will be removed in a future version. ' \
    'Use global_config instead.'
  )
  global_config
end

# @deprecated Use {#global_config} instead.
def global_config_set(name, value)
  Git::Deprecation.warn(
    'global_config_set is deprecated and will be removed in a future version. ' \
    'Use global_config(name, value) instead.'
  )
  global_config(name, value)
end
```

These can be removed in v6 after a full deprecation cycle.

**Decision:** Accepted. Add `global_config(name = nil, value = nil)` to `Git::Repository::Configuring` with three-way dispatch (list/get/set). Add deprecated forwarding methods `global_config_get`, `global_config_list`, `global_config_set` with `Git::Deprecation.warn` calls. Add `Git::Base` delegators for all four. Remove deprecated aliases in v6.

---

### 3.4 `parse_config(file)`

**Signature:** `parse_config(file)`

**Description:** Calls
`Git::Commands::ConfigOptionSyntax::List.new(self).call(file: file)` and
parses the output into a `Hash{String => String}` via `parse_config_list`.
The `file` argument is an arbitrary filesystem path to any
`.gitconfig`-format file — not necessarily the repository's own config.
This is the mechanism `Git::Lib` uses internally for reading `~/.gitconfig`
or any other git-style config file by path.

**Context:** `Git::Repository::Configuring#config()` already accepts a
`:file` option in its **set** overload (to write to a custom file), but has
no `:file` support in the **get** or **list** overloads, and there is no
way to read an arbitrary config file via the current facade. This is a
partial gap: write-to-file is covered, read-from-file is not.

**Options:**

- **A — Extend `config()` with a `:file` option for read operations:**
  Allow `repo.config(file: '/path')` (list-from-file) and
  `repo.config('key', file: '/path')` (get-from-file). Consistent with the
  existing `config()` contract and the `:file` option already used for set.
- **B — Promote as a standalone `parse_config(file)` method:** Add
  `parse_config(file)` directly to `Git::Repository::Configuring` (or a
  suitable module) with the same signature. Preserves backward compatibility
  for any callers using `g.lib.parse_config(path)`.
- **C — Mark as internal; no public equivalent:** The use case of reading
  an arbitrary git config file is niche. Callers who need it can invoke
  `git config --list --file <path>` via `Git::Commands` directly.

**Recommendation:** **Option A, with a backward-compatible deprecated alias.**
The `:file` option is already part of the `config()` facade for writes;
extending it to reads creates a consistent, symmetric API. The implementation
is trivial (pass `file:` to the `Get` and `List` command calls). To preserve
backward compatibility, also add `parse_config` as a deprecated forwarding
method on `Git::Repository::Configuring` (and a corresponding `Git::Base`
delegator):

```ruby
# @deprecated Use {#config} with the :file option instead.
def parse_config(file)
  Git::Deprecation.warn(
    'parse_config is deprecated and will be removed in a future version. ' \
    'Use config(file: <path>) instead.'
  )
  config(file: file)
end
```

Callers migrating from `lib.parse_config(path)` can drop to
`repo.parse_config(path)` immediately (no method-name change needed), then
migrate to `repo.config(file: path)` at their own pace. Remove in v6.

**Decision:** Accepted. Extend `Git::Repository::Configuring#config()` to accept `:file` on the get and list overloads. Add deprecated `parse_config(file)` forwarding method with `Git::Deprecation.warn` call pointing to `config(file: <path>)`. Add `Git::Base` delegator. Remove deprecated alias in v6.

---

### 3.5 `stash_list`

**Signature:** `stash_list`

**Description:** Calls `Git::Commands::Stash::List` and parses the result
via `Git::Parsers::Stash.parse_list`, then formats the structured data back
into a plain `String` of the form `"stash@{0}: On main: WIP\nstash@{1}: On
feature: test"`. This replicates the raw output of `git stash list` and
exists specifically to preserve the v4 backward-compatible return type (a
formatted string rather than structured objects).

**Context:** `Git::Repository::Stashing#stashes_all` (already promoted in
§7.2) returns `Array<[Integer, String]>` — pairs of `[index, message_string]`
where the message has the branch prefix stripped (e.g., `[0, "Fix bug"]`
rather than `"stash@{0}: WIP on main: Fix bug"`). The two methods serve
different callers: `stashes_all` is the clean v5 API returning structured
data; `stash_list` returns the full formatted-string representation that v4
callers depending on `"stash@{n}: ..."` format may depend on. There is no
`Git::Base` delegator for `stash_list`.

**Options:**

- **A — Promote `stash_list` as a deprecated method:** Add `stash_list` to
  `Git::Repository::Stashing` with a `@deprecated` YARD tag pointing callers
  to `stashes_all`. Keep the formatted-string behavior to avoid a breaking
  change for v4 callers.
- **B — Deprecate without promotion; add upgrade note only:** Do not expose
  `stash_list` on `Git::Repository`. Document in `UPGRADING.md` that
  callers should migrate to `stashes_all`. This is a breaking change for
  anyone calling `g.lib.stash_list` and expecting a string.
- **C — Mark as covered; no action:** Treat `stash_list` as already
  superseded by `stashes_all` and silently remove it. Same breaking-change
  risk as Option B but without an upgrade note.

**Recommendation:** **Option A.** The formatted-string return type is the
kind of low-effort backward-compatible shim that prevents v4 callers from
hitting a hard error during migration. The method must emit a runtime
deprecation warning via `Git::Deprecation.warn`, consistent with every other
deprecated method in the project. Because `stashes_all` returns
`[index, message_string]` pairs with a different format, `stash_list` must
call the stash command directly to preserve the `"stash@{n}: <full message>"`
format that v4 callers expect. The implementation is:

```ruby
# @deprecated Use {#stashes_all} instead.
def stash_list
  Git::Deprecation.warn(
    'stash_list is deprecated and will be removed in a future version. ' \
    'Use stashes_all instead.'
  )
  result = Git::Commands::Stash::List.new(@execution_context).call
  stashes = Git::Parsers::Stash.parse_list(result.stdout)
  stashes.map { |info| "#{info.name}: #{info.message}" }.join("\n")
end
```

Remove the method in v6 after a full deprecation cycle.

**Decision:** Accepted. Add `stash_list` to `Git::Repository::Stashing` as a deprecated method with `Git::Deprecation.warn` pointing to `stashes_all`. Add `Git::Base` delegator. Remove in v6.

---

### 3.6 `unmerged`

**Signature:** `unmerged`

**Description:** Calls `Git::Commands::Diff.new(self).call(cached: true)`
and scans the output for lines matching `* Unmerged path (.*)`, returning
an `Array<String>` of repository-relative file paths that have unresolved
merge conflicts. It is the same logic as
`Git::Repository::Merging::Private.unmerged_paths` — the private helper
already extracted into the `Merging` module for use by `each_conflict`.

**Context:** `Git::Repository::Merging#each_conflict` already uses
`Private.unmerged_paths` internally and yields those same paths (alongside
temporary files of staged content) to its block. If a caller only needs the
list of conflicting file paths — not the staged content — they currently have
no public API for that; they must call `each_conflict` with a block that
discards the tempfile arguments. The logic for extracting unmerged paths is
already implemented and tested inside the `Merging` module's private layer.

**Options:**

- **A — Promote `unmerged` as a public method on `Git::Repository::Merging`:**
  Surface `Private.unmerged_paths` directly as `unmerged` (or
  `unmerged_paths`). Add a `Git::Base` delegator. One-line implementation;
  no new commands needed.
- **B — Keep `each_conflict` as the only public API:** Document that callers
  who only need the path list should call `each_conflict` and collect the
  first argument in the block. No new methods added.
- **C — Rename the promotion to `conflict_files` (or similar):** Promote
  the functionality under a clearer name that signals it returns a list of
  conflicting file paths rather than "unmerged index entries".

**Recommendation:** **Option A.** Promoting `unmerged` is low-cost (the
private helper already exists) and fills a real usability gap: forcing
callers to use `each_conflict` when they only want a path list is
unnecessarily heavyweight. The name `unmerged` has v4 precedent and is
consistent with git's own terminology (`git diff --cached` unmerged paths).
Use `unmerged` as the promoted name to preserve backward compatibility.

**Decision:** Accepted. Promote `unmerged` as a public method on `Git::Repository::Merging` by surfacing `Private.unmerged_paths`. Add `Git::Base` delegator.

## 4. Pre-resolved questions

The following questions were raised during initial drafting and are now
resolved. The answers are binding on PR 5h unless explicitly overridden.

### 4.1 Global config API surface breadth (§3.3) — **Resolved**

**Question:** Should `global_config()` also accept a `:system` flag for
system-level config, or a `:file` option for arbitrary-path reads?

**Answer: Narrow implementation only — global list/get/set, no `:system`,
no `:file`.**

System-level config (`/etc/gitconfig`) requires elevated filesystem
permissions and belongs to git administration, not application-level
tooling. There is no credible use case for a Ruby gem managing system config.
The `:file` option for arbitrary-path reads is already covered by
`config(file: path)` per §3.4's resolution — `global_config` does not
need to duplicate it. Keeping `global_config()` narrow also avoids questions
about whether `global: true` and `file:` can be combined (they cannot; git
rejects `--global --file` together). The initial signature is:

```ruby
global_config(name = nil, value = nil)
```

with the same three-way dispatch as `config()`. A `:system` variant can be
added in a later minor release if demand materializes.

---

### 4.2 `change_head_branch` guard semantics (§3.1) — **Resolved**

**Question:** Should `change_head_branch` guard against non-existent branch
names, raising `ArgumentError` if the branch does not yet exist?

**Answer: No guard.**

The unborn-branch workflow — pointing HEAD at a ref that does not yet exist,
before the first commit is made — is a first-class git pattern. It is how
`git init --initial-branch=main` works, and it is how repository
initialization scripts change the default branch before any commits land.
A guard that rejects non-existent branches would silently break this
workflow. `git symbolic-ref` itself imposes no such constraint, and neither
should the facade. The method should be promoted as a clean pass-through
with clear documentation explaining that the target branch need not exist,
that pointing HEAD at a non-existent ref places the repository in unborn
state, and that this is intentional for initialization workflows. Callers
who want an existence check can call `repo.branches.local.any? { |b| b.name
== branch_name }` before calling `change_head_branch`.

---

### 4.3 `config()` overload complexity with `:file` for reads (§3.4) — **Resolved**

**Question:** Does extending `config()` to accept `:file` on the get and
list overloads create unacceptable dispatch complexity?

**Answer: Acceptable. Confirm Option A for §3.4.**

The dispatch rule for `config()` is purely positional-argument-count-based
(0 args → list, 1 arg → get, 2 args → set). Adding `:file` as a keyword
modifier does not change that rule; it is a pure option, not a new dispatch
dimension. The resulting overload table is:

| Positional args | `:file` present | Mode |
|-----------------|-----------------|------|
| 0 | no | list from repo |
| 0 | yes | list from file |
| 1 | no | get from repo |
| 1 | yes | get from file |
| 2 | no/yes | set (`:file` already works) |

Every cell is unambiguous. The `:file` option is already documented and
validated for the set overload; extending its meaning to reads is symmetric
and matches caller expectations. There is no new dispatch rule to learn.

---

### 4.4 Semver classification of `stash_list` non-promotion (§3.5) — **Resolved**

**Question:** If `stash_list` is not promoted (Options B or C in §3.5), is
a `BREAKING CHANGE:` CHANGELOG entry mandatory?

**Answer: Yes, mandatory — but moot if the recommended Option A is followed.**

`Git::Base#lib` is a public accessor. The audit's own framing (§7.1)
recognizes that every public method on `Git::Lib` is reachable from external
call sites as `g.lib.method_name`. Any method that disappears from that
surface without a deprecation cycle is a semver major breaking change,
regardless of `Git::Lib`'s `@api private` annotation. If the reviewer
overrides §3.5's recommendation and chooses Option B or C, the implementing
commit **must** carry a `BREAKING CHANGE:` footer and `UPGRADING.md`
must document the removal explicitly. Choosing Option A (promote as
`@deprecated`) avoids this entirely: the method remains callable in v5 with
a deprecation warning, and is removed in v6 after a full deprecation cycle.
Option A is therefore the only path that does not require a BREAKING CHANGE
entry for this specific method.

---

## 5. Next Steps

Complete items 1–4 below, then open PR 5h to implement the decisions.

- [x] Record a decision for each of the 10 items above (§3.1–§3.6) in the
      **Decision** fields. (The four questions in §4 are pre-resolved and
      do not require separate reviewer input.)
- [x] For items decided as **"promote"** (§3.1, §3.5, §3.6): raise a
      follow-up issue or include in the PR 5h scope, specifying the target
      `Git::Repository` module. *(Issues: #1399 `unmerged`, #1400 `stash_list`, #1401 `change_head_branch`)*
- [x] For items decided as **"deprecated forwarding alias over existing facade"**
      (§3.2, §3.3, §3.4): include both the facade extension *and* the
      deprecated forwarding methods (with `Git::Deprecation.warn` calls) in
      PR 5h scope. *(Issues: #1402 `config_get/list/set`, #1403 `global_config`, #1404 `parse_config`)*
- [x] For items decided as **"mark internal / no public equivalent"**: confirm
      the upgrade note wording and ensure it appears in `UPGRADING.md`
      before PR 5h merges. *(No items landed in this bucket — all decisions
      were "promote" or "deprecated forwarding alias". `UPGRADING.md` created
      with all entries pre-populated.)*
- [ ] Once all decisions are recorded, open PR 5h targeting `main` to
      implement the promotions, add the deprecated aliases with runtime
      warnings, add the upgrade notes to `UPGRADING.md`, and close this document's action items.
