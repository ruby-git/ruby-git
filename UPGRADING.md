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
    - [`Git::Author` deprecated](#gitauthor-deprecated)
    - [`Git::Branch#stashes` deprecated](#gitbranchstashes-deprecated)
    - [`Git::Repository#remotes` deprecated](#gitrepositoryremotes-deprecated)
    - [`Git::Remote` deprecated](#gitremote-deprecated)
    - [`Git::Commands::CatFile::Raw` `allow_unknown_type` option deprecated](#gitcommandscatfileraw-allow_unknown_type-option-deprecated)

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
| `g.lib.list_files(ref_dir)` | Walked `.git/refs/` directly. Use `g.branches`, `g.tags`, or `g.remote_list` instead. |

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
return the same entries. Call `Git::Repository#stashes_all` instead; it is the
query `Git::Branch#stashes` was already running.

> **Return type change:** `Git::Branch#stashes` returns a `Git::Stashes`
> collection of `Git::Stash` objects, newest first. `g.stashes_all` returns an
> array of `[index, message]` pairs, oldest first. Code that read `stash.message`
> from each entry should read the second element of each pair instead. Code that
> iterated or indexed the collection must reverse the order first, because
> `Git::Stashes` yields and indexes newest first while `g.stashes_all` is oldest
> first.

`Git::Stashes` also exposes `save`, `apply`, and `clear`. Those map to the
repository's `stash_save`, `stash_apply`, and `stash_clear`, which are not
deprecated. `Git::Stashes#apply(i)` already passed `i` to git as `stash@{i}`
(`0` = newest), and `g.stash_apply(i)` does the same, so that index needs no
conversion.

| Deprecated call (works in v5.x, removed in v6.0.0) | Replacement |
|-----------------------------------------------------|-------------|
| `g.branch(name).stashes` | `g.stashes_all` — returns `[[index, message], ...]` |
| `g.branch(name).stashes.each { \|s\| puts s.message }` | `g.stashes_all.reverse_each { \|_index, message\| puts message }` |
| `g.branch(name).stashes.all` | `g.stashes_all` |
| `g.branch(name).stashes.size` | `g.stashes_all.size` |
| `g.branch(name).stashes[i].message` (`0` = newest, `i` coerced with `to_i`) | `g.stashes_all.reverse[i.to_i][1]` |
| `g.branch(name).stashes.save(message)` | `g.stash_save(message)` |
| `g.branch(name).stashes.apply` | `g.stash_apply` |
| `g.branch(name).stashes.apply(i)` (`0` = newest) | `g.stash_apply(i)` |
| `g.branch(name).stashes.clear` | `g.stash_clear` |
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

---
