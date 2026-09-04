# Upgrading the `git` Gem

This document covers breaking changes and migration steps when upgrading the
`git` gem to a new major version. Each section describes what changed and how
to update your code when upgrading from the preceding major version.

- [Upgrading to v6.0.0](#upgrading-to-v600)
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
    - [Module-level `Git` function deprecations](#module-level-git-function-deprecations)
    - [`Git::Author` deprecated](#gitauthor-deprecated)
    - [`Git::Branch#stashes` deprecated](#gitbranchstashes-deprecated)
    - [Legacy stash API deprecated](#legacy-stash-api-deprecated)
    - [`Git::Repository#remotes` deprecated](#gitrepositoryremotes-deprecated)
    - [`Git::Remote` deprecated](#gitremote-deprecated)
    - [`Git::Commands::CatFile::Raw` `allow_unknown_type` option deprecated](#gitcommandscatfileraw-allow_unknown_type-option-deprecated)
    - [`Git::Branch` and `Git::Branches` deprecated](#gitbranch-and-gitbranches-deprecated)
    - [`Git::Object::Tag` deprecated](#gitobjecttag-deprecated)
    - [`Git::Status` deprecated](#gitstatus-deprecated)
    - [`Git::Worktree` and `Git::Worktrees` deprecated](#gitworktree-and-gitworktrees-deprecated)

## Upgrading to v6.0.0

v6.0.0 is not yet released. This section will be completed when it ships.

v6.0.0 removes the APIs deprecated during v5.x under the project's
[deprecation policy](README.md#deprecation-policy).
[Issue 1717](https://github.com/ruby-git/ruby-git/issues/1717) tracks its scope.

To prepare:

1. Upgrade to the latest v5.x release.
2. Set `GIT_DEPRECATION_BEHAVIOR=raise` (or `Git::Deprecation.behavior = :raise`) in
   your test suite and, if possible, staging.
3. Fix each deprecation using the entries under
   [Deprecated methods](#deprecated-methods) until the suite is clean.
4. Upgrade to v6.0.0.

---

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
| `g.lib.stash_list` | `g.stash_infos` — returns `Array<Git::StashInfo>`, newest first |
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
| `g.lib.list_files(ref_dir)` | Walked `.git/refs/` directly. Use `g.branch_list`, `g.tag_list`, or `g.remote_list` instead. |

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
purpose-named methods. The same applies to the module-level
`Git.global_config`, which is replaced by `Git.config_get`, `Git.config_set`,
and `Git.config_list` called with `global: true`.

> **Return type change:** The v4.x `g.config(name)` and `Git.global_config(name)`
> returned a `String`; `g.config` and `Git.global_config` returned a `Hash`. The
> v5.x replacements `config_get` and `config_list` return `Git::ConfigEntryInfo`
> (or `nil` when the key is not set) and `Array<Git::ConfigEntryInfo>`
> respectively. Use `.value` to get the String value:
> - `g.config_get(name)&.value` → String or nil
> - `g.config_list.to_h { |e| [e.key, e.value] }` → Hash (key → value)
>
> The setters `g.config(name, value)` and `Git.global_config(name, value)`
> returned the raw command result; `config_set` returns `nil`.

| Deprecated call (works in v5.x, removed in v6.0.0) | Replacement |
|-----------------------------------------------------|-------------|
| `g.config(name)` | `g.config_get(name)` — returns `Git::ConfigEntryInfo`; use `.value` for the String |
| `g.config` | `g.config_list` — returns `Array<Git::ConfigEntryInfo>` |
| `g.config(name, value)` | `g.config_set(name, value)` |
| `g.global_config(name)` | `g.config_get(name, global: true)` |
| `g.global_config` | `g.config_list(global: true)` |
| `g.global_config(name, value)` | `g.config_set(name, value, global: true)` |
| `Git.global_config(name)` | `Git.config_get(name, global: true)` — returns `Git::ConfigEntryInfo` or `nil`; use `.value` for the String |
| `Git.global_config` | `Git.config_list(global: true)` — returns `Array<Git::ConfigEntryInfo>` |
| `Git.global_config(name, value)` | `Git.config_set(name, value, global: true)` |

#### `Git` module mixin deprecations

Extending or including the `Git` module to call `config` and `global_config`
as bare methods is deprecated:

| Deprecated usage | Replacement |
|-----------------|-------------|
| `include Git; config(name)` | `Git.config_get(name)` |
| `include Git; config(name, value)` | `Git.config_set(name, value)` |
| `include Git; config` | `Git.config_list` |
| `include Git; global_config(name)` | `Git.config_get(name, global: true)` |
| `include Git; global_config(name, value)` | `Git.config_set(name, value, global: true)` |
| `include Git; global_config` | `Git.config_list(global: true)` |

`Git.config_get`, `Git.config_set`, and `Git.config_list` run `git config` in
the current directory, which is what the mixin `config` method did. The
return types differ as described under
[v4.x-style configuration methods](#v4x-style-configuration-methods).

#### Module-level `Git` function deprecations

Two module-level functions on `Git` accept a legacy call shape or return a
legacy type that is deprecated:

- `Git.ls_remote` defaults its repository argument to `'.'`. Passing `nil`
  explicitly still works but warns; omit the argument or pass `'.'`. The
  options hash is positional, so when you pass options you must also pass the
  repository: `Git.ls_remote('.', opts)`, not `Git.ls_remote(opts)`.
- `Git.binary_version` is replaced by `Git.git_version`, which keeps the
  optional binary path argument.

> **Return type change:** `Git.binary_version` returned an `Array<Integer>` of
> `[major, minor, patch]`. `Git.git_version` returns a `Git::Version`, which
> supports comparison and exposes `major`, `minor`, and `patch`.
> `Git.git_version.to_a` reproduces the legacy array. The return value of
> `Git.ls_remote` is unchanged.

| Deprecated call (works in v5.x, removed in v6.0.0) | Replacement |
|-----------------------------------------------------|-------------|
| `Git.ls_remote(nil)` | `Git.ls_remote` or `Git.ls_remote('.')` |
| `Git.ls_remote(nil, opts)` | `Git.ls_remote('.', opts)` |
| `Git.binary_version` | `Git.git_version` — returns `Git::Version`; use `.to_a` for the `[major, minor, patch]` Array |
| `Git.binary_version(binary_path)` | `Git.git_version(binary_path)` |

#### `Git::Author` deprecated

Starting in v5.3.0, methods that return author, committer, or tagger data —
`Git::Object::Commit#author`, `Git::Object::Commit#committer`,
`Git::Object::Tag#tagger`, and `Git::TagInfo#tagger` — return an immutable
`Git::AuthorInfo` value object instead of the mutable `Git::Author`.

`Git::AuthorInfo` exposes the same `name`, `email`, and `date` readers, so code
that only reads these attributes needs no changes. Code that mutated a
`Git::Author` (via `name=`, `email=`, or `date=`) must be updated:
`Git::AuthorInfo` is frozen, and `#with` returns a modified copy rather than
updating in place (e.g. `info = info.with(name: 'New Name')`).

Constructing `Git::Author` directly emits a deprecation warning naming
`Git::AuthorInfo` as the replacement. The class is removed in v6.0.0.

| Deprecated usage | Replacement |
|-----------------|-------------|
| `Git::Author.new('Name <email> 1627849923 +0200')` | `Git::AuthorInfo.parse('Name <email> 1627849923 +0200')` |
| `author.name = 'New Name'` | `author = author.with(name: 'New Name')` (returns a new object) |

#### `Git::Branch#stashes` deprecated

`Git::Branch#stashes` ignores the branch it is called on and returns every stash
in the repository, so `g.branch('feature').stashes` and `g.branch('main').stashes`
return the same entries. Call `Git::Repository#stash_infos` instead; it is the
query `Git::Branch#stashes` was already running.

> **Return type change:** `Git::Branch#stashes` returns a `Git::Stashes`
> collection of `Git::Stash` objects. `g.stash_infos` returns an array of
> `Git::StashInfo` values. Both are newest first, so indexes carry over unchanged.
> `Git::Stash#message` strips the `WIP on <branch>:` or `On <branch>:` prefix;
> `Git::StashInfo#message` keeps the full message and exposes the branch name as
> `Git::StashInfo#branch`.

`Git::Stashes` also exposes `save`, `apply`, and `clear`. Those map to the
repository's `stash_push`, `stash_apply`, and `stash_clear`. `Git::Stashes#apply(i)`
already passed `i` to git as `stash@{i}` (`0` = newest), and `g.stash_apply(i)` does
the same, so that index needs no conversion. The `Git::Stashes` class is deprecated
as well; [Legacy stash API deprecated](#legacy-stash-api-deprecated) maps each of
its methods.

| Deprecated call (works in v5.x, removed in v6.0.0) | Replacement |
|-----------------------------------------------------|-------------|
| `g.branch(name).stashes` | `g.stash_infos` — returns `Array<Git::StashInfo>`, newest first |
| `g.branch(name).stashes.each { \|s\| puts s.message }` | `g.stash_infos.each { \|info\| puts info.message }` |
| `g.branch(name).stashes.all` (`[index, message]` pairs, oldest first) | `g.stash_infos.reverse` — see the ordering note in [Legacy stash API deprecated](#legacy-stash-api-deprecated) |
| `g.branch(name).stashes.size` | `g.stash_infos.size` |
| `g.branch(name).stashes[i].message` (`0` = newest, `i` coerced with `to_i`) | `g.stash_infos[i.to_i].message` |
| `g.branch(name).stashes.save(message)` | `g.stash_push(message: message)` |
| `g.branch(name).stashes.apply` | `g.stash_apply` |
| `g.branch(name).stashes.apply(i)` (`0` = newest) | `g.stash_apply(i)` |
| `g.branch(name).stashes.clear` | `g.stash_clear` — returns git's stdout (normally `""`, which is truthy) where `Git::Stashes#clear` returned `nil` |

#### Legacy stash API deprecated

Starting in v5.4.0, the stash methods on `Git::Repository` are built around the
immutable `Git::StashInfo` value object. `g.stash_infos` returns every entry as a
`Git::StashInfo`, and `stash_push`, `stash_pop`, `stash_drop`, `stash_show`,
`stash_branch`, `stash_create`, and `stash_store` each map onto the `git stash`
subcommand of the same name. Every method that takes a stash (`stash_apply`,
`stash_pop`, `stash_drop`, `stash_show`, `stash_branch`) accepts a `Git::StashInfo`,
a `stash@{N}` name, an Integer index (`0` = newest), or `nil` for the newest entry.

The legacy methods and classes are deprecated and removed in v6.0.0:
`Git::Repository#stashes_all`, `Git::Repository#stash_save`,
`Git::Repository#stash_list`, `Git::Stash`, and `Git::Stashes`. Constructing a
`Git::Stash` or `Git::Stashes` emits one warning per object.

> **Ordering flip:** `g.stashes_all` returns entries **oldest first** with a
> sequential index of its own (`0` is the oldest). `g.stash_infos` returns entries
> **newest first**, the order `git stash list` uses, and `Git::StashInfo#index` is
> git's own `stash@{N}` number (`0` is the newest). `g.stashes_all.first` is
> `g.stash_infos.last`. Code that reads an entry by position must reverse the
> array or the index.

> **Message difference:** `g.stashes_all` strips the `WIP on <branch>:` or
> `On <branch>:` prefix from each message. `Git::StashInfo#message` keeps the full
> message git stores, and `Git::StashInfo#branch` holds the branch name. A stash
> created from a detached HEAD has the branch `"(no branch)"`, the label git writes
> in its message. `branch` is `nil` only when the message has no branch prefix at
> all, as for a `stash_store` entry with a custom message.

`g.stash_save(message)` returned `true` when it created a stash and `false` when
there were no local changes to save. `g.stash_push(message: message)` returns the
new `Git::StashInfo`, or `nil` when there were no local changes, so a truthiness
check such as `if g.stash_push(message: 'WIP')` still works.

`g.stash_list` returned the `git stash list` text as a String. Build that text from
`g.stash_infos` if you need it. In v6.0.0, `stash_list` returns
`Array<Git::StashInfo>`, the same value as `stash_infos`, and `stash_infos` stays as
a permanent alias. Move String callers of `stash_list` to `stash_infos` before
upgrading so the return type change cannot go unnoticed.

| Deprecated call (works in v5.x, removed in v6.0.0) | Replacement |
|-----------------------------------------------------|-------------|
| `g.stashes_all` | `g.stash_infos` — returns `Array<Git::StashInfo>`, newest first |
| `g.stashes_all.each { \|index, message\| ... }` | `g.stash_infos.reverse_each.with_index { \|info, index\| ... info.message }` |
| `g.stashes_all[i]` (`0` = oldest) | `g.stash_infos.reverse[i]` |
| `g.stashes_all.last` | `g.stash_infos.first` |
| `g.stash_save(message)` | `g.stash_push(message: message)` — returns `Git::StashInfo` or `nil` |
| `g.stash_list` (String) | `g.stash_infos.map { \|s\| "#{s.name}: #{s.message}" }.join("\n")` |
| `Git::Stash.new(g, message)` | `info = g.stash_push(message: message)` |
| `Git::Stash.new(g, message, existing: true)` | `message` — `existing: true` only wrapped the String and never looked an entry up; code that needs a real entry picks one from `g.stash_infos` by index or name |
| `stash.save` | `info = g.stash_push(message: message)` |
| `stash.saved?` | `!info.nil?` — check the value `stash_push` returned rather than pushing again |
| `stash.message` / `stash.to_s` | `info.message` — keeps the branch prefix; see the note above |
| `Git::Stashes.new(g)` | `g.stash_infos` |
| `stashes.all` (`[index, message]` pairs, oldest first) | `g.stash_infos.reverse` — see the ordering note above |
| `stashes.each { \|s\| ... }` (newest first) | `g.stash_infos.each { \|info\| ... }` |
| `stashes[i]` (`0` = newest, `i` coerced with `to_i`) | `g.stash_infos[i.to_i]` |
| `stashes.size` | `g.stash_infos.size` |
| `stashes.save(message)` | `g.stash_push(message: message)` |
| `stashes.apply` / `stashes.apply(i)` | `g.stash_apply` / `g.stash_apply(i)` |
| `stashes.clear` | `g.stash_clear` — returns git's stdout (normally `""`, which is truthy) where `Git::Stashes#clear` returned `nil` |

#### `Git::Repository#remotes` deprecated

`Git::Repository#remotes` is deprecated in favor of `Git::Repository#remote_list`
and is removed in v6.0.0. Its return value is unchanged. Calling `remotes` emits
one deprecation warning for itself plus one `Git::Remote` constructor warning for
each remote it returns (see the `Git::Remote` deprecation below), so a repository
with N remotes produces N + 1 warnings per call.

> **Return type change:** `remotes` returns `Array<Git::Remote>` — mutable
> objects with `name`, `url`, and `fetch_opts` accessors and `fetch`, `merge`,
> `branch`, and `remove` operations. `remote_list` returns
> `Array<Git::RemoteInfo>` — immutable value objects read from the repository's
> git config, with fields such as `name`, `url`, `push_url`, `fetch`, and `push`.
> Because a remote may carry more than one URL or refspec, `url`, `push_url`,
> `fetch`, and `push` are always frozen `Array<String>`. When a remote has more
> than one URL, git fetches from the first; the legacy `Git::Remote#url` returned
> the last one configured, so use `r.url.last` to reproduce that exact value.
> Likewise, `Git::Remote#fetch_opts` returned only the last configured fetch
> refspec, while `fetch` holds all of them. Operations that lived on
> `Git::Remote` are called on the repository with the remote name instead.
>
> **Order change:** `remotes` lists remotes in the order `git remote` prints
> them, while `remote_list` keeps the order in which remotes first appear in the
> config. When the legacy order matters, iterate `g.remote_names` (the same
> `git remote` order) or sort `g.remote_list` explicitly.

| Deprecated call (works in v5.x, removed in v6.0.0) | Replacement |
|-----------------------------------------------------|-------------|
| `g.remotes` | `g.remote_list` — returns `Array<Git::RemoteInfo>` |
| `g.remotes.map(&:name)` | `g.remote_list.map(&:name)` or `g.remote_names` |
| `g.remotes.map(&:to_s)` | `g.remote_list.map(&:name)` — `Git::RemoteInfo#to_s` is not the name |
| `g.remotes.map(&:url)` | `g.remote_list.map { \|r\| r.url.first }` — `url` is an `Array<String>` |
| `g.remotes.map(&:fetch_opts)` | `g.remote_list.map { \|r\| r.fetch.last }` — `fetch` holds every refspec |
| `g.remotes.each(&:fetch)` | `g.remote_names.each { \|name\| g.fetch(name) }` — same order as `remotes` |
| `remote.fetch` | `g.fetch(remote.name)` |
| `remote.fetch(opts)` | `g.fetch(remote.name, opts)` — same options hash |
| `remote.merge` | `g.merge("#{remote.name}/#{g.current_branch}")` |
| `remote.merge(branch)` | `g.merge("#{remote.name}/#{branch}")` |
| `remote.branch` | `g.branch_list("#{remote.name}/#{g.current_branch}").first` — returns a `Git::BranchInfo` |
| `remote.branch(name)` | `g.branch_list("#{remote.name}/#{name}").first` — returns a `Git::BranchInfo` |
| `remote.remove` | `g.remote_remove(remote.name)` |

#### `Git::Remote` deprecated

`Git::Remote`, `Git::Repository#remote`, and `Git::Repository#config_remote` are
deprecated and are removed in v6.0.0. Read a remote's configuration through
`Git::Repository#remote_list`, which returns one `Git::RemoteInfo` value object per
remote, and call the repository-level operations (`fetch`, `merge`, `branch_list`,
`remote_remove`) with the remote name. Return values are unchanged. Constructing a
`Git::Remote` directly emits one deprecation warning, and so does calling
`g.config_remote`. Calling `g.remote` emits two: one for `Git::Repository#remote`
and one for the `Git::Remote` it constructs. Likewise `g.remotes` emits one warning
for itself plus one per `Git::Remote` it returns (N + 1 for N remotes). The extra
warnings from `g.remote` and `g.remotes` are expected, not a bug.

> **Return type changes:** `Git::RemoteInfo#url` and `Git::RemoteInfo#fetch` are
> frozen `Array<String>` because a remote may carry more than one URL or fetch
> refspec. The legacy `Git::Remote#url` and `Git::Remote#fetch_opts` returned only
> the last configured value, so `r.url.last` and `r.fetch.last` reproduce them
> exactly; `r.url.first` is the URL git actually fetches from.
> `config_remote` returned a flat `Hash{String => String}` in which a repeated
> `url` or `fetch` key overwrote the earlier value, so it could not report every
> configured URL or refspec; `remote_list` keeps all of them. In the other
> direction, `Git::RemoteInfo` models only the remote variables git defines and
> drops any other `remote.<name>.*` key, while `config_remote` returned every key.
> Code that reads custom keys should filter `g.config_list` instead (see the
> table); that yields the same `Hash{String => String}` as `config_remote`.
> `Git::Remote#branch` returned a `Git::Branch`. Its replacement,
> `g.branch_list("#{name}/#{branch}").first`, returns a `Git::BranchInfo` value
> object, or `nil` when the remote-tracking branch does not exist.

In the table, `name` is the remote name (`g.remote` defaults it to `'origin'`).

| Deprecated call (works in v5.x, removed in v6.0.0) | Replacement |
|-----------------------------------------------------|-------------|
| `g.remote` | `g.remote_list.find { \|r\| r.name == 'origin' }` — returns a `Git::RemoteInfo`; the deprecated call emits two warnings |
| `g.remote(name)` | `g.remote_list.find { \|r\| r.name == name }` — returns a `Git::RemoteInfo`; the deprecated call emits two warnings |
| `g.config_remote(name)` for `url`, `fetch`, and the other modeled fields | `g.remote_list.find { \|r\| r.name == name }` — a `Git::RemoteInfo`, not a `Hash` |
| `g.config_remote(name)` for every key, including custom ones | `g.config_list.select { \|e\| e.key.start_with?("remote.#{name}.") }.to_h { \|e\| [e.key.delete_prefix("remote.#{name}."), e.value] }` — the same `Hash{String => String}` |
| `remote.name`, `remote.to_s` | `g.remote_list.find { \|r\| r.name == name }.name` or `g.remote_names` |
| `remote.url` | `g.remote_list.find { \|r\| r.name == name }.url` — `Array<String>`; `.first` for the single-URL case |
| `remote.fetch_opts` | `g.remote_list.find { \|r\| r.name == name }.fetch` — `Array<String>` of refspecs |
| `remote.fetch` | `g.fetch(name)` |
| `remote.fetch(opts)` | `g.fetch(name, opts)` — same option keys |
| `remote.merge` | `g.merge("#{name}/#{g.current_branch}")` |
| `remote.merge(branch)` | `g.merge("#{name}/#{branch}")` |
| `remote.branch` | `g.branch_list("#{name}/#{g.current_branch}").first` — returns a `Git::BranchInfo` |
| `remote.branch(branch)` | `g.branch_list("#{name}/#{branch}").first` — returns a `Git::BranchInfo` |
| `remote.remove` | `g.remote_remove(name)` |

#### `Git::Commands::CatFile::Raw` `allow_unknown_type` option deprecated

The `allow_unknown_type:` option of `Git::Commands::CatFile::Raw` is deprecated
and is removed in v6.0.0. Passing it emits a deprecation warning; the
`--allow-unknown-type` flag still reaches git unchanged until the option is
removed.

There is no replacement. Git 2.50 removed the unknown-type feature, so on git
2.50 and later `--allow-unknown-type` is an accepted no-op and the option has no
effect. On git 2.28 through 2.49 the flag still lets `t: true` and `s: true`
report the type and size of an object whose type git does not recognize, but
that behavior is dropped together with the option. The class is internal
(`@api private`) and no `Git::Repository` method passes the option, so only code
that constructs the command class directly is affected.

| Deprecated call (works in v5.x, removed in v6.0.0) | Replacement |
|-----------------------------------------------------|-------------|
| `Git::Commands::CatFile::Raw.new(ctx).call(sha, t: true, allow_unknown_type: true)` | `Git::Commands::CatFile::Raw.new(ctx).call(sha, t: true)` |
| `Git::Commands::CatFile::Raw.new(ctx).call(sha, s: true, allow_unknown_type: true)` | `Git::Commands::CatFile::Raw.new(ctx).call(sha, s: true)` |

#### `Git::Branch` and `Git::Branches` deprecated

`Git::Branch`, `Git::Branches`, `Git::Repository#branch`, and
`Git::Repository#branches` are deprecated and are removed in v6.0.0. Read branch
data through `Git::Repository#branch_list`, which returns one `Git::BranchInfo`
value object per local and remote-tracking branch, and call the repository-level
operations (`checkout`, `branch_new`, `branch_delete`, `merge`, `merge_into`,
`in_branch`, and so on) with the branch name. Calling `g.branch` or `g.branches`,
constructing a `Git::Branches`, and calling any operation on a `Git::Branch` each
emit a deprecation warning; their return values are unchanged. The `full`,
`name`, `remote`, `to_s`, and `to_a` readers on `Git::Branch` do not warn.

> **Return shape change:** `Git::Branch` exposes `full` (`main` or
> `remotes/origin/main`), `name`, and `remote` (a `Git::Remote`, or `nil`).
> `Git::BranchInfo` exposes `refname` (always the full ref: `refs/heads/main` or
> `refs/remotes/origin/main`), `short_name` (`main` for both), `remote_name` (a
> `String`, or `nil`), `remote?`, `current?`, `target_oid`, `upstream`,
> `worktree_path`, and `symref`. `Git::BranchInfo#to_s` is the full ref, not the
> `remotes/origin/main` form `Git::Branch#to_s` returned. `branch_list` takes
> `git branch --list` patterns: `'main'` matches the local branch and
> `'origin/main'` matches the remote-tracking branch. The `remotes/origin/main`
> and `refs/...` forms that `g.branches[...]` accepted match nothing.
>
> **`checkout` no longer creates the branch:** `g.branch('x').checkout` created
> `x` when it did not exist, ignoring any error from that attempt, and then
> checked it out. `g.checkout('x')` does not create a missing local branch,
> with one exception that is git's own: when exactly one remote has a branch
> named `x`, git creates a local tracking branch from it (its default guess
> behavior). Otherwise the checkout fails. To reproduce create-or-checkout,
> call `g.branch_new('x') unless g.local_branch?('x')` and then
> `g.checkout('x')`. Use `g.checkout('x', new_branch: true)` only when `x` is
> known not to exist; like `g.branch_new('x')`, it fails when `x` already
> exists. Likewise `g.branch('x').create` ignored every error, while
> `g.branch_new('x')` raises `Git::FailedError` when `x` already exists.
>
> **`in_branch` and `merge_into` differences:**
>
> 1. **Branch creation.** `g.branch('x').in_branch { ... }` created `x` if it did
>    not exist. `g.in_branch('x') { ... }` raises `ArgumentError` unless `x` is an
>    existing local branch, so call `g.branch_new('x')` first. A commit SHA, tag,
>    or remote-tracking name is also rejected before any checkout.
> 2. **Detached HEAD.** `Git::Branch#in_branch` recorded the literal `HEAD` and
>    could not restore a detached HEAD to its original commit. `g.in_branch` and
>    `g.merge_into` record the SHA and restore it.
> 3. **Unborn HEAD.** Both new methods raise `Git::Error` before checking anything
>    out when HEAD is on a branch with no commits. The old methods failed later,
>    mid-flow.
> 4. **Merge overload.** `g.branch('main').merge('feature')` returned stdout from
>    the final restore checkout and ran a hard reset after the merge.
>    `g.merge_into('main', 'feature')` returns the merge's stdout and does no
>    reset. It also rejects the `:no_commit` option; callers who need
>    `--no-commit` use `checkout` and `merge` directly.
> 5. **Remote-tracking receivers.** Called on a remote-tracking `Git::Branch`,
>    `in_branch` and `merge(branch)` checked out the remote-tracking ref,
>    detaching HEAD, and any commit made there was left dangling. `g.in_branch`
>    and `g.merge_into` take an existing local branch only. Create one from the
>    remote-tracking ref first, with
>    `g.branch_new(name, "remotes/#{remote}/#{name}")`, and pass that branch.

In the table, `name` is the branch name (`g.branch` defaults it to the current
branch), `remote` is the remote name of a remote-tracking branch, `b` is a
`Git::Branch`, and `info` is the `Git::BranchInfo` that replaces it. Where a
row says to pass `info.refname` for a remote-tracking branch, `b.full` (the
`remotes/<remote>/<name>` form) works too; the shorter `"#{remote}/#{name}"`
can resolve a local branch of that name and is only used where git expects it
(`branch_delete` with `remotes: true`).

| Deprecated call (works in v5.x, removed in v6.0.0) | Replacement |
|-----------------------------------------------------|-------------|
| `g.branch(name)` | `g.branch_list(name).first` for a local branch, or `g.branch_list("#{remote}/#{name}").find(&:remote?)` for a remote-tracking one — a `Git::BranchInfo`, or `nil` when the branch does not exist; the `remotes/` and `refs/` forms match nothing |
| `g.branch` | `g.branch_list(g.current_branch).first` — `nil` when HEAD is detached or unborn; use `g.current_branch_state` there |
| `g.branches` | `g.branch_list` — returns `Array<Git::BranchInfo>` |
| `g.branches[name]` | `g.branch_list(name).first`, or `g.branch_list("#{remote}/#{name}").find(&:remote?)` for a remote-tracking branch |
| `g.branches.local` | `g.branch_list.reject(&:remote?)` |
| `g.branches.remote` | `g.branch_list.select(&:remote?)` |
| `g.branches.size` | `g.branch_list.size` |
| `g.branches.each { \|b\| ... }` | `g.branch_list.each { \|info\| ... }` |
| `g.branches.to_s` | `g.branch_list.map { \|i\| "#{i.current? ? '* ' : '  '}#{i.refname}\n" }.join` — full refs, not `remotes/...` |
| `b.full`, `b.to_s` | `info.refname` — `refs/remotes/origin/main` rather than `remotes/origin/main` |
| `b.to_a` | `[info.refname]` |
| `b.name` | `info.short_name` |
| `b.remote` | `info.remote_name` — a `String`, or `nil` for a local branch |
| `b.gcommit` | `g.gcommit(name)` — pass `info.refname` for a remote-tracking branch |
| `b.checkout` | `g.checkout(name)` — does not create the branch (see above); pass `info.refname` for a remote-tracking branch |
| `b.create` | `g.branch_new(name)` — raises when the branch already exists |
| `b.delete` (local) | `g.branch_delete(name)` |
| `b.delete` (remote-tracking) | `g.branch_delete("#{remote}/#{name}", remotes: true)` |
| `b.current` | `g.current_branch == name` |
| `b.contains?(commit)` | `!g.branch_contains(commit, name).empty?` |
| `b.merge` | `g.merge(name)` |
| `b.merge(branch, message)` | `g.merge_into(name, branch, message)` — local `b` only; see the differences above |
| `b.update_ref(commit)` (local) | `g.update_ref(name, commit)` |
| `b.update_ref(commit)` (remote-tracking) | `g.update_ref("remotes/#{remote}/#{name}", commit)` |
| `b.archive(file, opts)` | `g.archive(name, file, opts)` — pass `info.refname` for a remote-tracking branch |
| `b.in_branch(message) { ... }` | `g.in_branch(name, message) { ... }` — local `b` only; see the differences above |
| `b.stashes` | `g.stash_infos` — see [`Git::Branch#stashes` deprecated](#gitbranchstashes-deprecated) |

#### `Git::Object::Tag` deprecated

`Git::Object::Tag`, `Git::Repository#tag`, `Git::Repository#tags`, and
`Git::Repository#tag_add` are deprecated and are removed in v6.0.0. Read tag data
through `Git::Repository#tag_list`, which returns one `Git::TagInfo` value object per
tag, create tags with `Git::Repository#tag_create`, which returns the new tag's
`Git::TagInfo`, and call the repository-level operations (`archive`, `log`, `diff`,
`cat_file_contents`, and so on) with the tag's object ID,
`info.oid || info.target_oid`, which is the object a `Git::Object::Tag` pinned when
it was constructed. Calling `g.tag`, `g.tags`, or
`g.tag_add`, and constructing a `Git::Object::Tag`, each emit one deprecation
warning; their return values are unchanged. `g.add_tag` already warned, pointing at
`g.tag_add`, and now emits two warnings for a creation call, one for itself and one
for the `g.tag_add` it calls; `g.add_tag(name, d: true)` emits three, adding the
`:d`/`:delete` warning described below. The readers on a `Git::Object::Tag` do not
warn.

> **Return shape change:** `Git::Object::Tag` exposes `name`, `sha`, `objectish`,
> `annotated?`, `message`, and `tagger`. `Git::TagInfo` exposes `name`, `oid`,
> `target_oid`, `objecttype`, `annotated?`, `lightweight?`, `message`, and
> `tagger`. `name` and `annotated?` are unchanged. `tagger` keeps the same `name`
> and `email`, but `tagger.date` differs: `t.tagger.date` is a `Time` in the
> process's local zone, while `info.tagger.date` keeps the UTC offset recorded in
> the tag object. Both name the same instant. `message` differs for an annotated
> tag created with an empty message (`message: ''`): `t.message` returns `""` and
> `info.message` returns `nil`, the same value a lightweight tag has. `t.sha` and
> `t.objectish` are the tag object's ID for an annotated tag and
> the tagged object's ID for a lightweight tag. `Git::TagInfo` separates the two:
> `oid` is the tag object's ID (`nil` for a lightweight tag) and `target_oid` is
> the ID of the object the tag points to (set for both kinds), so
> `info.oid || info.target_oid` reproduces `t.sha`. The target is usually a
> commit, but a tag can point at any git object, and `info.objecttype` reports
> which kind (`tag` for an annotated tag, or the target's own type such as
> `commit` or `blob` for a lightweight one).
>
> **Missing tags:** `g.tag(name)` raises `Git::UnexpectedResultError` when no tag
> has that name. `g.tag_list(name).first` returns `nil`.
>
> **Deleting through `tag_add`:** `g.tag_add(name, d: true)`, which was already
> deprecated, deletes the tag and emits a second warning pointing at
> `g.tag_delete`. `g.tag_create` rejects `:d` and `:delete` with `ArgumentError`.
>
> **Extra positional arguments:** `g.tag_add(name, target, extra)` ignores
> `extra` and tags `target`. `g.tag_create` raises `ArgumentError` when more than
> one positional argument follows the name.
>
> **Object identity:** every `Git::Object::Tag` resolves its tag to an object ID
> when it is constructed and runs `size`, `contents`, `grep`, `diff`, `log`, and
> `archive` against that ID, so moving or deleting the tag afterwards does not
> redirect an existing object. `Git::Object::Tag.new(g, sha, name)` uses the
> supplied `sha` as that ID; the other forms look it up from the ref. `annotated?`,
> `message`, and `tagger` always read the ref `name`. `Git::TagInfo` describes the
> ref only: `g.tag_list(name).first` returns whatever `name` points at now, or
> `nil` once the tag is deleted. Keep the same identity by passing `id` (see the
> table) rather than `name` to the operation replacements; they accept any object.
> To read an annotated tag object by ID without going through its ref, use
> `g.cat_file_tag(id)`, which returns the tag object's `object`, `type`, `tag`,
> `tagger`, and `message`.

In the table, `name` is the tag name, `t` is a `Git::Object::Tag`, `info` is the
`Git::TagInfo` that replaces it, and `id` is `info.oid || info.target_oid` (or the
`sha` given to the three-argument constructor), the object `t` pinned.

| Deprecated call (works in v5.x, removed in v6.0.0) | Replacement |
|-----------------------------------------------------|-------------|
| `g.tag(name)` | `g.tag_list(name).first` — a `Git::TagInfo`, or `nil` when the tag does not exist |
| `g.tags` | `g.tag_list` — returns `Array<Git::TagInfo>` |
| `g.tags.map(&:name)` | `g.tag_list.map(&:name)` |
| `g.tag_add(name, opts)` | `g.tag_create(name, opts)` — returns a `Git::TagInfo` |
| `g.tag_add(name, target, opts)` | `g.tag_create(name, target, opts)` |
| `g.tag_add(name, d: true)` | `g.tag_delete(name)` |
| `g.add_tag(name, opts)`, `g.add_tag(name, target, opts)` | `g.tag_create(name, ...)` — its warning names `g.tag_add`, which is deprecated too; go straight to `g.tag_create` |
| `g.add_tag(name, d: true)` | `g.tag_delete(name)` — `g.tag_create` rejects `:d`; see the deletion note above |
| `Git::Object::Tag.new(g, name)` | `g.tag_list(name).first` |
| `Git::Object::Tag.new(g, sha, name)` | `g.tag_list(name).first` — reads the ref rather than `sha`; use `sha` as `id` for the operations below, or read the object with `g.cat_file_tag(sha)`; see the object identity note above |
| `Git::Object.new(g, name, nil, true)` | `g.tag_list(name).first` — its warning names `Git::Object::Tag.new`, which is deprecated too |
| `t.name` | `info.name` |
| `t.sha`, `t.objectish`, `t.to_s` | `info.oid \|\| info.target_oid` — see the return shape change above |
| `t.annotated?` | `info.annotated?` |
| `t.message` | `info.message` — `nil` rather than `""` for an annotated tag with an empty message |
| `t.tagger` | `info.tagger` — `date` keeps the recorded UTC offset; see the return shape change above |
| `t.tag?` | not needed; every `Git::TagInfo` is a tag |
| `t.size` | `g.cat_file_size(id)` — `id` rather than `name` keeps this and the operations below on the object `t` pinned; see the object identity note above |
| `t.contents` | `g.cat_file_contents(id)` |
| `t.contents { \|file\| ... }` | `g.cat_file_contents(id) { \|file\| ... }` — streams to a temporary file instead of buffering the object |
| `t.contents_array` | `g.cat_file_contents(id).split("\n")` |
| `t.grep(string, path, opts)` | `g.grep(string, path, opts.merge(object: id))` |
| `t.diff(other)` | `g.diff(id, other)` |
| `t.log(count)` | `g.log(count).object(id)` |
| `t.archive(file, opts)` | `g.archive(id, file, opts)` |

#### `Git::Status` deprecated

Starting in v5.4.0, `Git::Status`, `Git::Status::StatusFile`, and
`Git::Repository#status` are deprecated and will be removed in v6.0.0. Read the
index and working tree state through `Git::Repository#status_info`, which
returns an immutable `Git::StatusInfo` holding one `Git::StatusFileInfo` per
path that `git status --porcelain=v2` reports. Calling `g.status` emits one
deprecation warning, and so does constructing a `Git::Status` directly.

`Git::StatusInfo` keeps the `changed`, `added`, `deleted`, and `untracked`
readers and the `changed?`, `added?`, `deleted?`, and `untracked?` predicates,
so code that only uses those can change `status` to `status_info` and needs
no other edit, subject to the category differences below. The readers now
return `Hash{String => Git::StatusFileInfo}`, and a new `unmerged` reader
lists conflicted paths, which `Git::Status` did not report. The predicates
still compare paths case-insensitively when `core.ignoreCase` is `true`.
`Git::StatusInfo` is not `Enumerable`; iterate `status_info.files`, an
`Array<Git::StatusFileInfo>` in git's output order.

The categories are derived differently. `Git::Status` gave each file one
`type`, and `changed` held only files whose type was `M`, so `changed`,
`added`, and `deleted` were disjoint: a file staged as new and then modified
in the working tree was only `added`. `Git::StatusInfo` derives the
categories from both status characters, so `changed` also includes type
changes (`T`), and one path can be in more than one category: that same file
(`AM`) is in both `added` and `changed`, and a file modified in the index and
then deleted from the working tree (`MD`) is in both `changed` and `deleted`.
Code that relied on the sets being disjoint should test `index_status` and
`worktree_status` directly.

`Git::StatusInfo` holds only the paths `git status` reports. `Git::Status`
also held an entry for every clean tracked file, seeded from `git ls-files`,
so `status[path]` returned a `Git::Status::StatusFile` with a `nil` type for an
unchanged path and `status.each` yielded one. `status_info[path]` returns `nil`
for a clean path and `status_info.files` omits it. Code that inspected clean
files should read `g.ls_files`, which still returns the index mode and SHA of
every tracked path.

`Git::StatusFileInfo` replaces the single `type` character with the two status
characters of the porcelain v2 format, `index_status` (HEAD versus index) and
`worktree_status` (index versus working tree), plus the `changed?`, `added?`,
`deleted?`, `renamed?`, `unmerged?`, `untracked?`, and `ignored?` predicates:
`added?` is true when `index_status` is `A`, `deleted?` when either status is
`D`, and `changed?` when either status is `M` or `T`. It holds no repository
reference, so `blob` is gone; fetch the object through the repository instead.
`stage` is gone too: an unmerged entry carries its stage 1, 2, and 3 modes and
SHAs in `unmerged_stages`, and every other entry is at stage 0.

> **Field renames:** the legacy mode and SHA readers were named for the wrong
> sides. `sha_index` and `mode_index` held the working-tree side of the diff:
> the index blob when the working tree matched the index, and an all-zero SHA
> when it did not. `sha_repo` and `mode_repo` held the side git compared the
> working tree against: the index in a repository with no commits, and HEAD
> once a commit exists (the factory applied `git diff-index HEAD` last). The
> new names follow git: `sha_head` and `mode_head` are the HEAD side,
> `sha_index` and `mode_index` are the index (staged) side, and
> `mode_worktree` is the working-tree mode. There is no working-tree SHA
> because `git status` does not compute one; `worktree_status` says whether
> the working tree differs from the index.

In the table, `g` is a `Git::Repository`, `status` is the `Git::Status` from
`g.status`, `file` is a `Git::Status::StatusFile`, and `info` is the
`Git::StatusFileInfo` that replaces it.

| Deprecated call (works in v5.x, removed in v6.0.0) | Replacement |
|-----------------------------------------------------|-------------|
| `g.status` | `g.status_info` — returns a `Git::StatusInfo` |
| `Git::Status.new(g)` | `g.status_info` |
| `status.changed`, `status.added`, `status.deleted`, `status.untracked` | same names on `g.status_info` — now `Hash{String => Git::StatusFileInfo}` keyed by path |
| `status.changed?(path)`, `status.added?(path)`, `status.deleted?(path)`, `status.untracked?(path)` | same names on `g.status_info` |
| `status[path]` | `g.status_info[path]` — a `Git::StatusFileInfo`, or `nil`; `nil` for a clean tracked path, which `status[path]` reported (see above) |
| `status.each { \|file\| ... }` | `g.status_info.files.each { \|info\| ... }` — does not yield clean tracked paths (see above) |
| `status.pretty` | no replacement; format `g.status_info.files` yourself |
| `file.path` | `info.path` |
| `file.type` | `info.index_status` and `info.worktree_status`, or the `info.changed?`, `info.added?`, and `info.deleted?` predicates |
| `file.untracked` | `info.untracked?` |
| `file.stage` | gone; `info.unmerged?` and `info.unmerged_stages` describe conflicted entries |
| `file.sha_repo` | `info.sha_head`, or `info.sha_index` in a repository with no commits |
| `file.mode_repo` | `info.mode_head`, or `info.mode_index` in a repository with no commits |
| `file.sha_index` | `info.sha_index` for the staged blob; `info.worktree_status` says whether the working tree differs from it |
| `file.mode_index` | `info.mode_worktree` |
| `file.blob` | `g.object(info.sha_index)` when `info.sha_index` is set and not all zeros — it is `nil` for untracked, ignored, and unmerged entries and all zeros when the path is not in the index; legacy `blob` returned `nil` without a lookup when no SHA was available and fell back to `sha_repo` when `sha_index` was `nil`. For an unmerged entry read a stage instead: `g.object(info.unmerged_stages[2][:sha])` |
| `file.blob(:repo)` | `g.object(info.sha_head)` when `info.sha_head` is set and not all zeros — it is `nil` for untracked, ignored, and unmerged entries and all zeros when the path is not in HEAD |

#### `Git::Worktree` and `Git::Worktrees` deprecated

`Git::Worktree`, `Git::Worktrees`, `Git::Repository#worktree`,
`Git::Repository#worktrees`, and `Git::Repository#worktrees_all` are deprecated
and are removed in v6.0.0. Read worktree data through
`Git::Repository#worktree_list`, which returns one `Git::WorktreeInfo` value
object per worktree, and call the repository-level operations (`worktree_add`,
`worktree_remove`, `worktree_move`, `worktree_lock`, `worktree_unlock`,
`worktree_repair`, and `worktree_prune`) with the worktree path or its
`Git::WorktreeInfo`. Return values are unchanged. Calling `g.worktree`,
`g.worktrees`, or `g.worktrees_all`, constructing a `Git::Worktrees`, and calling
`gcommit`, `add`, or `remove` on a `Git::Worktree` each emit a deprecation
warning; the `dir`, `full`, `to_s`, and `to_a` readers on `Git::Worktree` do not.
`g.worktrees` emits two warnings, one for itself and one for the `Git::Worktrees`
it constructs, and `g.worktree(dir).add` emits one for `g.worktree` and one for
`add`.

> **Return shape change:** `worktrees_all` returns `[directory, sha]` pairs and
> omits the main worktree of a bare repository, which has no checked-out commit.
> `worktree_list` returns `Git::WorktreeInfo` objects with `path`, `head`,
> `branch` (the full refname, such as `refs/heads/main`, or `nil` when detached
> or bare), `bare?`, `detached?`, `locked?` with `lock_reason`, and `prunable?`
> with `prune_reason`. It includes the bare main worktree, with `head` and
> `branch` set to `nil`. `Git::WorktreeInfo#to_s` is the path, so an entry can be
> passed to any method that takes a worktree path.
>
> **`gcommit` return type:** `Git::Worktree#gcommit` returned a
> `Git::Object::Commit` for a worktree obtained from `g.worktree(dir)` and a raw
> SHA `String` for one obtained from `g.worktrees`. `info.head` is always a
> `String` (or `nil` for a bare main worktree); call `g.gcommit(info.head)` for
> the commit object.
>
> **`full` and `to_s`:** `Git::Worktree#full` and `#to_s` append the commitish
> given at construction to the path, so entries from `g.worktrees` read
> `"/path/to/wt <sha>"`. `Git::WorktreeInfo#to_s` is the path alone.

In the table, `dir` is the worktree path, `wt` is a `Git::Worktree`, and `info`
is the `Git::WorktreeInfo` that replaces it.

| Deprecated call (works in v5.x, removed in v6.0.0) | Replacement |
|-----------------------------------------------------|-------------|
| `g.worktrees_all` | `g.worktree_list.map { \|w\| [w.path, w.head] }` — includes a bare main worktree as `[path, nil]`; add `.reject(&:bare?)` before `map` to omit it as `worktrees_all` did |
| `g.worktrees` | `g.worktree_list` — returns `Array<Git::WorktreeInfo>`; the deprecated call emits two warnings |
| `g.worktrees[dir]` | `g.worktree_list.find { \|w\| w.path == dir }` — `nil` when not found; `dir` is the path as git reports it (absolute, with symlinks resolved), as before |
| `g.worktrees.size` | `g.worktree_list.size` |
| `g.worktrees.each { \|wt\| ... }` | `g.worktree_list.each { \|info\| ... }` |
| `g.worktrees.to_s` | `g.worktree_list.map { \|w\| "#{w.path} #{w.head}\n" }.join` |
| `g.worktrees.prune` | `g.worktree_prune` |
| `g.worktree(dir).add` | `g.worktree_add(dir)` |
| `g.worktree(dir, commitish).add` | `g.worktree_add(dir, commitish)` |
| `g.worktree(dir).remove` | `g.worktree_remove(dir)` — or `g.worktree_remove(info)` |
| `wt.gcommit` | `info.head` — always a `String`, or `nil` for a bare main worktree; `g.gcommit(info.head)` for the commit object |
| `wt.dir` | `info.path` |
| `wt.full`, `wt.to_s` | `info.path` — or `"#{info.path} #{info.head}"` for the descriptor that entries from `g.worktrees` produced |
| `wt.to_a` | `[info.path]` |

---
