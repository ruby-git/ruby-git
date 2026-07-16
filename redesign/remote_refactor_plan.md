# Plan: RemoteInfo + RemoteOperations API Modernization

> **Note:** Issue #919 fix (`BranchInfo#remote_name` for slash-containing remotes) is
> deferred to a separate effort and is not part of this plan.

## TL;DR

Three PRs in order:

- **PR 1** (smallest, independent): `remote_add` / `remote_set_url` return `nil`
- **PR 2** (data layer foundation): `Git::RemoteInfo` value object + `Parsers::Remote`
- **PR 3** (depends on PR 2): `remote_list` facade method + deprecate `remotes`

---

## PR 1 — `remote_add` / `remote_set_url` return `nil` *(independent, smallest)*

**Step A.** `remote_add` — remove `Git::Remote.new(self, name)`, return `nil` explicitly
- File: `lib/git/repository/remote_operations.rb`

**Step B.** `remote_set_url` — same change

**Step C.** Fix deprecated wrappers (can no longer just forward the return value):
- `add_remote` → call `remote_add(...)` then `Git::Remote.new(self, name)`
- `set_remote_url` → call `remote_set_url(...)` then `Git::Remote.new(self, name)`

**Step D.** Update YARD `@return` on `remote_add` and `remote_set_url` to `@return [void]`
  (per project convention: methods with no meaningful return value use `@return [void]`,
  matching `remote_set_branches` and other mutation-only methods)

**Step E.** Update specs that assert `remote_add` / `remote_set_url` return a `Git::Remote`

### Files changed in PR 1

- `lib/git/repository/remote_operations.rb`
- `spec/unit/git/repository/remote_operations_spec.rb`

---

## PR 2 — `Git::RemoteInfo` data class + `Parsers::Remote` *(data layer foundation)*

**Step 1.** Create `lib/git/remote_info.rb`:

```ruby
module Git
  RemoteInfo = Data.define(
    :name,            # String — required
    :url,             # Array<String>
    :push_url,        # Array<String>
    :fetch,           # Array<String>
    :push,            # Array<String>
    :mirror,          # Boolean | nil
    :skip_default_update, # Boolean | nil
    :tag_opt,         # String | nil
    :prune,           # Boolean | nil  (nil = inherit global fetch.prune)
    :prune_tags,      # Boolean | nil  (nil = inherit global fetch.pruneTags)
    :receivepack,     # String | nil
    :uploadpack,      # String | nil
    :promisor,        # Boolean | nil
    :partial_clone_filter, # String | nil
    :vcs              # String | nil
  )
end
```

- Multi-value fields (`:url`, `:push_url`, `:fetch`, `:push`) are always `Array<String>` (never
  `nil`; may be empty). All other fields are nilable except `:name`.
- Use **snake_case** field names throughout

**Step 2.** Create `lib/git/parsers/remote.rb`:

- `Git::Parsers::Remote.parse_list(config_entries)` — accepts an
  `Array<Git::ConfigEntryInfo>` (as returned by `Git::Configuring#config_list`),
  groups entries by remote name, and builds `RemoteInfo` objects
- Using `Array<Git::ConfigEntryInfo>` as input naturally preserves duplicate keys
  (e.g., multiple `remote.<name>.fetch` refspecs or multiple `url` values),
  which a flat `Hash{String=>String}` cannot represent
- Multi-value fields (`:url`, `:push_url`, `:fetch`, `:push`) are collected into arrays
- Boolean fields are coerced matching git's own boolean rules:
  - **True values**: `"true"`, `"yes"`, `"on"`, `"1"`, `""` (key present without a value) → `true`
  - **False values**: `"false"`, `"no"`, `"off"`, `"0"` → `false`
  - **Absent** (key not present in config at all) → `nil`
  - **Unrecognized value**: raise `ArgumentError` (mirrors git's fatal error behavior)
- Config key → Ruby field mapping (for keys that differ from the field name):

| git config key | `RemoteInfo` field |
|---|---|
| `url` | `:url` (Array) |
| `pushurl` | `:push_url` (Array) |
| `fetch` | `:fetch` (Array) |
| `push` | `:push` (Array) |
| `tagOpt` | `:tag_opt` |
| `partialclonefilter` | `:partial_clone_filter` |
| `skipDefaultUpdate` | `:skip_default_update` |
| `pruneTags` | `:prune_tags` |
| `promisor` | `:promisor` (no case change, but in the mapping table) |
| `mirror`, `prune`, `receivepack`, `uploadpack`, `vcs` | direct lowercase match |

**Step 3.** Unit tests for `Parsers::Remote`:
- Single remote with only required fields
- Remote with multiple URLs and fetch specs
- Multiple remotes in one config entry array
- Empty input → empty array
- Boolean field coercion (true/false/nil/raise on unrecognized value)

### Files changed in PR 2

- `lib/git/remote_info.rb` — new file
- `lib/git/parsers/remote.rb` — new file
- `spec/unit/git/remote_info_spec.rb` — new
- `spec/unit/git/parsers/remote_spec.rb` — new

---

## PR 3 — `remote_list` facade method + `remotes` deprecation *(depends on PR 2)*

**Step 4.** Add `remote_list` to `Git::Repository::RemoteOperations`:
- Calls `config_list` (the `Git::Configuring` instance method, already mixed into
  `Git::Repository`) to get all config entries as `Array<Git::ConfigEntryInfo>`
- Filters for entries whose key starts with `remote.`, passes to
  `Git::Parsers::Remote.parse_list`
- Returns `Array<Git::RemoteInfo>`
- File: `lib/git/repository/remote_operations.rb`
- Note: this replaces the use of `Private.config_list` (which returns a flat hash
  that loses duplicate keys and cannot represent multi-value config fields)

**Step 5.** Deprecate `remotes`:
- Add `Git::Deprecation.warn(...)` pointing to `remote_list`
- Keep returning `Array<Git::Remote>` for backward compat

**Step 6.** Unit + integration tests for `remote_list`

### Files changed in PR 3

- `lib/git/repository/remote_operations.rb`
- `spec/unit/git/repository/remote_operations_spec.rb`
- `spec/integration/git/repository/remote_operations_spec.rb`

---

## Decisions

- `remote_show(name)` deferred — add after `remote_list` lands
- `remotes` deprecated (not removed) — still returns `Array<Git::Remote>` for compat
- `remote_add` / `remote_set_url` return `nil` — breaking change acceptable in beta
- Deprecated wrappers (`add_remote`, `set_remote_url`) still return `Git::Remote`
- `RemoteInfo` fields are **snake_case** (not camelCase)
- Data source for `remote_list`: `Git::Configuring#config_list` (the instance method
  mixed into `Git::Repository`), which returns `Array<Git::ConfigEntryInfo>` and
  preserves duplicate keys — **not** `Private.config_list` (which returns a flat
  `Hash{String=>String}` and cannot represent multi-value fields)
- **Boolean fields** are three-state `true`/`false`/`nil`; `nil` means "not configured"
  and is semantically distinct from `false` for `:prune` and `:prune_tags`
  (those inherit from global `fetch.prune` / `fetch.pruneTags` when `nil`)
- **Multi-value fields**: `:url`, `:push_url`, `:fetch`, `:push` are all `Array<String>`
- **`require` statements** are an implementation detail; add as needed
- **`config_remote`** — its relationship to `remote_list` is not addressed in this plan

## Out of scope

- Issue #919 fix (`BranchInfo#remote_name` for slash remotes) — separate effort
- `Git::Remote#branch` deprecation — not part of this plan
- `Git::Remote` and `Git::Branch` deprecation — separate future effort
- `remote_show(name)` single-remote lookup — deferred until after `remote_list` lands
