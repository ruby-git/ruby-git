# Upgrading the `git` Gem

> **⚠️ Work in progress — v5.0.0 is currently in beta.**
> This document is updated incrementally as development continues and is not yet
> complete. If you encounter a compatibility problem not covered here, please
> [open an issue](https://github.com/ruby-git/ruby-git/issues).

- [Upgrading from v4.x to v5.x](#upgrading-from-v4x-to-v5x)
  - [Overview](#overview)
  - [`Git::Lib` removal](#gitlib-removal)
    - [Methods with a direct replacement](#methods-with-a-direct-replacement)
    - [Methods with no replacement](#methods-with-no-replacement)
    - [Internal plumbing methods (no replacement)](#internal-plumbing-methods-no-replacement)
  - [Deprecated methods](#deprecated-methods)

## Upgrading from v4.x to v5.x

### Overview

The primary goal of v5.0.0 is to move everyone onto a new internal architecture
while keeping the existing v4.x API working. The vast majority of v4.x code
requires no changes to run on v5.x.

The new architecture delivered in v5.0.0 is the foundation for future API
improvements across upcoming major releases.

The new architecture introduces a layered design (`Git::Commands`, `Git::Repository`,
and associated parsers). Compatibility shims — deprecated forwarding methods that map
old call patterns to the new API — ensure that v4.x code continues to work. These
shims emit deprecation warnings that tell you exactly what to change and what will be
eliminated in a future major release (most likely v6.0.0).

Hard breaks are limited to a small number of methods that had no safe
migration path — these are described in detail below.

Our intent is to make upgrading to v5.x as smooth as possible. For information
on how to suppress or configure deprecation warnings, see the
[Deprecations](README.md#deprecations) section of the README.

---

### `Git::Lib` removal

The object returned by `Git.open`, `Git.clone`, and `Git.init` — the object
you call methods on to interact with your repository — inadvertently exposed
a `#lib` method that gave access to `Git::Lib`, the gem's internal
implementation class. This was never intended to be public; it was an
implementation detail that leaked out. `Git::Lib` is removed in v5.0.0.

Calling `#lib` on the repository object returns `self` with a deprecation
warning so that existing `g.lib.*` call chains continue to work during
migration. The `#lib` method itself is removed in v6.0.0. Calls to methods
that have no replacement (see below) raise `NoMethodError` with an
informative message.

Most public behavior previously accessible via `g.lib.*` is available
directly on the repository object (i.e., `g.*`). A small number of methods
have no replacement — see below. The sections below list every affected method.

#### Methods with a direct replacement

All of the following `g.lib.*` calls work in v5.x but emit a deprecation
warning. Migrate to the replacement shown to silence the `g.lib.*` deprecation
warning; note that some replacements are themselves deprecated — see the table
notes for the final migration target.

| Deprecated call (works in v5.x, removed in v6.0.0) | Replacement |
|---------------------------------------------------|-------------|
| `g.lib.config_get(name)` | `g.config(name)` |
| `g.lib.config_list` | `g.config` |
| `g.lib.config_set(name, value)` | `g.config(name, value)` |
| `g.lib.git_version` | `g.git_version` |
| `g.lib.global_config_get(name)` | `g.global_config(name)` |
| `g.lib.global_config_list` | `g.global_config` |
| `g.lib.global_config_set(name, value)` | `g.global_config(name, value)` |
| `g.lib.parse_config(file)` | `g.config(file: file)` |
| `g.lib.stash_list` | `g.stash_list` *(also deprecated — use `g.stashes_all`)* |
| `g.lib.unmerged` | `g.unmerged` |
| `g.lib.change_head_branch(name)` | `g.change_head_branch(name)` |
| `g.lib.branch_current` | `g.current_branch` |
| `g.lib.ls_remote(location, opts)` | `g.ls_remote(location, opts)` |

#### Methods with no replacement

| v4.x call | Notes |
|-----------|-------|
| `g.lib.list_files(ref_dir)` | Walked `.git/refs/` directly. Use `g.branches`, `g.tags`, or `g.remotes` instead. |

#### Internal plumbing methods (no replacement)

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

### Deprecated methods

The following methods are available in v5.x with deprecation warnings and
are removed in v6.0.0.

| Deprecated call (works in v5.x, removed in v6.0.0) | Replacement |
|---------------------------------------------------|-------------|
| `g.config_get(name)` | `g.config(name)` |
| `g.config_list` | `g.config` |
| `g.config_set(name, value)` | `g.config(name, value)` |
| `g.global_config_get(name)` | `g.global_config(name)` |
| `g.global_config_list` | `g.global_config` |
| `g.global_config_set(name, value)` | `g.global_config(name, value)` |
| `g.parse_config(file)` | `g.config(file: file)` |
| `g.stash_list` | `g.stashes_all` |

---
