# Upgrading the `git` Gem

This document covers breaking changes and migration steps when upgrading the
`git` gem to a new major version. Each section describes what changed and how
to update your code when upgrading from the preceding major version.

- [Upgrading to v5.x](#upgrading-to-v5x)
  - [Overview](#overview)
  - [Breaking changes](#breaking-changes)
    - [`Git::Base` removed](#gitbase-removed)
    - [Return type of `Git.open`, `Git.clone`, `Git.init`, `Git.bare`](#return-type-of-gitopen-gitclone-gitinit-gitbare)
    - [Unsupported options raise `ArgumentError`](#unsupported-options-raise-argumenterror)
    - [`Git::Lib` removed](#gitlib-removed)
    - [`Git::Log#object` is not a path limiter](#gitlogobject-is-not-a-path-limiter)
    - [`Git::CommandLineResult` deprecated](#gitcommandlineresult-deprecated)
  - [Deprecated methods](#deprecated-methods)
    - [Facade method renames](#facade-method-renames)
    - [v4.x-style configuration methods](#v4x-style-configuration-methods)
    - [`Git` module mixin deprecations](#git-module-mixin-deprecations)

## Upgrading to v5.x

### Overview

v5.0.0 delivers a new internal architecture while keeping the v4.x API working
for the vast majority of users. Most v4.x code requires **no changes** to run on
v5.x.

The new architecture introduces a layered design (`Git::Commands`,
`Git::Repository`, and associated parsers). Compatibility shims — deprecated
forwarding methods that map old call patterns to the new API — ensure that v4.x
code continues to work. These shims emit deprecation warnings that tell you
exactly what to change and what will be eliminated in v6.0.0.

Hard breaks are limited to a small number of things that had no safe migration
path. These are described in the [Breaking changes](#breaking-changes) section,
followed by [Deprecated methods](#deprecated-methods) that still work in v5.x
but are removed in v6.0.0.

For information on how to suppress or configure deprecation warnings, see the
[Deprecations](README.md#deprecations) section of the README.

**Changes at a glance:**

| Change | Type | Impact | Action required |
|--------|------|--------|-----------------|
| `Git::Base` removed | Hard break | High for code that references it by name | Replace with `Git::Repository` (returned by `Git.open` etc.) |
| `Git::Lib` removed | Hard break | High for `.lib.*` callers | Use the equivalent method directly on the repo object (see table below) |
| `Git.open` etc. return `Git::Repository` (not `Git::Base`) | Hard break | Low for most callers; breaks `is_a?(Git::Base)` | Update type checks and update `be_a(Git::Base)` in tests |
| Unsupported options now raise `ArgumentError` | Behavior change | Medium for code passing unknown or misspelled options | Check option names against the documented API |
| `Git::Log#object` is not a path limiter | Behavior change | Medium for code that used `object(path)` to filter logs by path | Use `Git::Log#path` for path filtering |
| `Git::CommandLineResult` deprecated | Deprecation (removed in v6.0.0) | Low; only affects code that references the constant by name | Use `Git::CommandLine::Result` instead |

---

### Breaking changes

#### `Git::Base` removed

`Git::Base` — the class previously returned by `Git.open`, `Git.clone`,
`Git.init`, and `Git.bare` — is removed in v5.0.0. The replacement is
`Git::Repository`, which is returned by all four entry points and exposes the
same public API.

**Code that must be updated:**

```ruby
# v4.x — explicit Git::Base reference (raises NameError in v5.x)
repo = Git::Base.new(working_directory: '/path/to/repo')

# v5.x — use the entry-point methods; do not construct Git::Repository directly
repo = Git.open('/path/to/repo')
```

```ruby
# v4.x — type-checking against Git::Base (raises NameError in v5.x because Git::Base is removed)
raise unless repo.is_a?(Git::Base)

# v5.x — check against Git::Repository
raise unless repo.is_a?(Git::Repository)
```

```ruby
# v4.x — requiring the internal file (raises LoadError in v5.x)
require 'git/base'

# v5.x — the public entry point is git itself; no internal require needed
require 'git'
```

**Public API is preserved:** `Git::Repository` provides every method that
`Git::Base` did. Code that simply calls methods on the object returned by
`Git.open` (e.g., `repo.commit`, `repo.status`, `repo.add`) requires no
changes.

**Monkeypatching `Git::Base` is deprecated:** v5.x includes a temporary
compatibility shim for applications that define instance methods on `Git::Base`.
Those methods are made available on `Git::Repository` instances, but each method
definition emits a deprecation warning and this shim will be removed in v6.0.0.

Move custom repository helpers to an application-owned extension module and
include or prepend that module into `Git::Repository` during application setup:

```ruby
# Deprecated in v5.x and will be removed in v6.0.0
module Git::Base
  def worktree_clean?
    status.changed.empty?
  end
end

# v5.x — keep the extension in application-owned code
module MyAppGitRepositoryExtensions
  def worktree_clean?
    status.changed.empty?
  end
end

Git::Repository.include(MyAppGitRepositoryExtensions)
```

---

#### Return type of `Git.open`, `Git.clone`, `Git.init`, `Git.bare`

`Git.open`, `Git.clone`, `Git.init`, and `Git.bare` now return
`Git::Repository` instead of `Git::Base`.

For most callers this is transparent — the returned object responds to the same
methods. Code that explicitly checks `is_a?(Git::Base)` or `be_a(Git::Base)` in
tests must be updated:

```ruby
# v4.x
expect(Git.open(repo_path)).to be_a(Git::Base)

# v5.x
expect(Git.open(repo_path)).to be_a(Git::Repository)
```

`Git::Repository` does not define `.open`, `.bare`, `.clone`, or `.init` class
methods. Always use `Git.open`, `Git.bare`, `Git.clone`, and `Git.init` to
construct a repository object.

---

#### Unsupported options raise `ArgumentError`

v5.x validates options more strictly for factory methods and command APIs.
Unknown options that were silently ignored in v4.x may now raise
`ArgumentError`. Check option names against the documented API when upgrading,
especially for calls that pass keyword options through helper methods or shared
option hashes.

For example, `Git.clone` supports `log:`, not `logger:`. A misspelled or
unsupported option that v4.x ignored must be corrected:

```ruby
# v4.x — silently ignored; did not configure clone logging
Git.clone(url, path, logger: logger)

# v5.x — use the documented option name
Git.clone(url, path, log: logger)
```

---

#### `Git::Lib` removed

The object returned by `Git.open`, `Git.clone`, `Git.init`, and `Git.bare` previously
exposed a `#lib` method that gave access to `Git::Lib`, the gem's internal
implementation class. `Git::Lib` is removed in v5.0.0.

In v5.x, calling `#lib` on a repo object returns `self` with a deprecation
warning. This means `g.lib.some_method(args)` is forwarded to
`g.some_method(args)` — but only if `some_method` exists on `Git::Repository`.
Methods that were unique to `Git::Lib` and have no counterpart on
`Git::Repository` raise `NoMethodError` immediately. The `#lib` method itself
is removed in v6.0.0.

Most public behavior previously accessible via `g.lib.*` is available directly
on the repository object (`g.*`). See the tables below for every affected
method.

##### Methods that work via the `#lib` shim (with deprecation warning)

The following v4.x `g.lib.*` call shapes are forwarded to their `Git::Repository`
counterpart by the `#lib → self` shim. They emit a deprecation warning; migrate
to the replacement shown to silence it.

> **Note — config return type change:** `g.lib.config_get(name)` returned a
> `String`; `g.lib.config_list` returned a `Hash`.
> The v5.x replacements `config_get` and `config_list` return
> `Git::ConfigEntryInfo` and `Array<Git::ConfigEntryInfo>` respectively — richer
> objects that expose `.value` (the String), `.key`, `.scope`, and `.origin`.
>
> If you only need the String value:
> - `g.config_get(name)&.value` → replaces `g.lib.config_get(name)`
> - `g.config_list.to_h { |e| [e.key, e.value] }` → replaces `g.lib.config_list`
>
> If your code was using the v4.x public `g.config(name)` API (not `g.lib.*`),
> that deprecated bridge still returns a `String` in v5.x and continues to work
> until v6.0.0.

| v4.x call | Replacement in v5.x |
|-----------|---------------------|
| `g.lib.config_get(name)` | `g.config_get(name)` — returns `Git::ConfigEntryInfo`; use `.value` for the String |
| `g.lib.config_list` | `g.config_list` — returns `Array<Git::ConfigEntryInfo>` |
| `g.lib.config_set(name, value)` | `g.config_set(name, value)` |
| `g.lib.git_version` | `g.git_version` |
| `g.lib.stash_list` | `g.stashes_all` |
| `g.lib.unmerged` | `g.unmerged` |
| `g.lib.change_head_branch(name)` | `g.change_head_branch(name)` |
| `g.lib.ls_remote(location, opts)` | `g.ls_remote(location, opts)` |
| `g.lib.current_branch_state` | `g.current_branch_state` |

> **Note — `current_branch_state` return type change:** `g.lib.current_branch_state`
> returned a `Git::Lib::HeadState` (a mutable `Struct`). `g.current_branch_state`
> returns a `Git::Repository::Branching::HeadState` (an immutable `Data` object).
> Both expose `.state` (`:active`, `:unborn`, or `:detached`) and `.name`. If your
> code relies on the struct being mutable or uses positional construction
> (`Git::Lib::HeadState.new(:active, 'main')`), update to keyword construction:
> `Git::Repository::Branching::HeadState.new(state: :active, name: 'main')`.

##### Methods that raise `NoMethodError` in v5.x

These `Git::Lib` method names have no counterpart on `Git::Repository`, so
`g.lib.method_name` raises `NoMethodError` even in v5.x (the `#lib → self`
shim cannot forward them). Update call sites directly:

| v4.x call | Replacement in v5.x |
|-----------|---------------------|
| `g.lib.global_config_get(name)` | `g.config_get(name, global: true)` |
| `g.lib.global_config_list` | `g.config_list(global: true)` |
| `g.lib.global_config_set(name, value)` | `g.config_set(name, value, global: true)` |
| `g.lib.branch_current` | `g.current_branch` |
| `g.lib.parse_config(file)` | `g.config_list(file: file)` |

##### Methods with no replacement

| v4.x call | Notes |
|-----------|-------|
| `g.lib.list_files(ref_dir)` | Walked `.git/refs/` directly. Use `g.branches`, `g.tags`, or `g.remotes` instead. |

##### Internal plumbing methods (no replacement)

The following methods were technically public on `Git::Lib` but are internal
helpers with no plausible external use. They have no replacement in v5.0.0:

- `assert_args_are_not_options`
- `assert_valid_opts`
- `cat_file_object_meta`
- `command_capturing`
- `command_streaming`
- `each_cat_file_header`
- `handle_deprecated_path_option`
- `normalize_pathspecs`
- `parse_cat_file_meta`
- `parse_config_list`
- `process_commit_data`
- `validate_pathspec_types`

---

#### `Git::Log#object` is not a path limiter

In previous 4.x releases, some uses of `Git::Log#object(path)` could appear to
filter log output by path when combined with `#between` or other revision range
options. This relied on ambiguous `git log` argument handling and was not the
intended API for path filtering.

In v5.x, `Git::Log#object` should be treated as a revision expression. When both
`#object` and `#between` are specified, `#between` takes precedence. Code that
used `#object` to limit commits to a path should use `#path` instead.

```ruby
# v4.x — ambiguous; could appear to filter commits touching this path
git.log(500).object('cookbooks/mycookbook').between('1.0.0', 'HEAD').execute

# v5.x — use #path for path filtering
git.log(500).path('cookbooks/mycookbook').between('1.0.0', 'HEAD').execute

# #object remains appropriate for revision expressions
git.log.object('HEAD~10..HEAD').execute
```

---

#### `Git::CommandLineResult` deprecated

`Git::CommandLineResult` was an alias for `Git::CommandLine::Result` introduced
for backward compatibility. It is deprecated in v5.0.0 and removed in v6.0.0.
Accessing `Git::CommandLineResult` emits a deprecation warning.

```ruby
# v4.x
result.is_a?(Git::CommandLineResult)

# v5.x
result.is_a?(Git::CommandLine::Result)
```

This change is only relevant if your code references `Git::CommandLineResult`
by name (typically in type checks or documentation). Code that simply uses the
result object returned by git commands is unaffected.

---

### Deprecated methods

The following methods are available in v5.x with deprecation warnings and are
removed in v6.0.0. Migrate to the replacement shown to silence the warnings.

#### Facade method renames

Five methods were renamed to follow the project's `noun_verb` naming convention.
The old names continue to work but emit deprecation warnings:

| Deprecated call (works in v5.x, removed in v6.0.0) | Replacement |
|-----------------------------------------------------|-------------|
| `g.add_remote(name, url, opts)` | `g.remote_add(name, url, opts)` |
| `g.remove_remote(name)` | `g.remote_remove(name)` |
| `g.set_remote_url(name, url)` | `g.remote_set_url(name, url)` |
| `g.add_tag(name, ...)` | `g.tag_add(name, ...)` |
| `g.delete_tag(name)` | `g.tag_delete(name)` |

#### v4.x-style configuration methods

The v4.x `config` and `global_config` methods accepted varying argument shapes
to read, write, or list configuration. These are replaced by separate,
purpose-named methods.

> **Return type change:** The v4.x `g.config(name)` returned a `String` and
> `g.config` returned a `Hash`. The v5.x replacements `config_get` and
> `config_list` return `Git::ConfigEntryInfo` and `Array<Git::ConfigEntryInfo>`
> respectively. Use `.value` to get the String value:
> - `g.config_get(name)&.value` → String or nil
> - `g.config_list.to_h { |e| [e.key, e.value] }` → Hash (key → value)

| Deprecated call (works in v5.x, removed in v6.0.0) | Replacement |
|-----------------------------------------------------|-------------|
| `g.config(name)` | `g.config_get(name)` — returns `Git::ConfigEntryInfo`; use `.value` for the String |
| `g.config` | `g.config_list` — returns `Array<Git::ConfigEntryInfo>` |
| `g.config(name, value)` | `g.config_set(name, value)` |
| `g.global_config(name)` | `g.config_get(name, global: true)` |
| `g.global_config` | `g.config_list(global: true)` |
| `g.global_config(name, value)` | `g.config_set(name, value, global: true)` |
| `g.parse_config(file)` | `g.config_list(file: file)` |
| `g.stash_list` | `g.stashes_all` |

#### `Git` module mixin deprecations

Extending or including the `Git` module to call `config` and `global_config`
as bare methods is deprecated:

| Deprecated usage | Replacement |
|-----------------|-------------|
| `include Git; config(name)` | `Git.open(Dir.pwd).config_get(name)` |
| `include Git; config(name, value)` | `Git.open(Dir.pwd).config_set(name, value)` |
| `include Git; config` | `Git.open(Dir.pwd).config_list` |
| `include Git; global_config(name)` | `Git.config_get(name, global: true)` |
| `include Git; global_config(name, value)` | `Git.config_set(name, value, global: true)` |
| `include Git; global_config` | `Git.config_list(global: true)` |

---
