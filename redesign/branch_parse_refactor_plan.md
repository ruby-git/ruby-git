# Plan: Fix Issue #919 — BranchInfo slash-remote parsing (PR series)

## Goal
Fix `BranchInfo#remote_name` and `#short_name` for remote names containing `/`
(e.g. `team/upstream`). Root cause: `BRANCH_REFNAME_REGEXP` uses `[^/]+` which
can only capture one path segment. Fix: resolve at parse time using the configured
remote list.

## PR sequence overview
- **PR 1** — Add `remote_names` facade method. Independent. No deps.
- **PR 2** — `BranchInfo` stored fields + remote-aware parser. Independent. No deps.
- **PR 3** — Wire `branch_list` end-to-end (closes #919). Depends on PR 1 + PR 2.

PR 1 and PR 2 can be developed in parallel. PR 3 merges last.

```
PR1 ─┐
     ├─> PR3 (closes #919)
PR2 ─┘
```

---

## PR 1 — Add `remote_names` to RemoteOperations
**Branch:** `feat/remote-names`
**Depends on:** nothing
**Value:** new public API `repo.remote_names` → `Array<String>` (lightweight; no RemoteInfo).

### Changes
- `lib/git/repository/remote_operations.rb`: add `remote_names` near `remotes` (~line 592).
  - Calls `Git::Commands::Remote::List.new(@execution_context).call`, splits stdout on `"\n"`.
  - Returns `Array<String>`. Empty array when no remotes.
  - Full YARD with `@api public`, `@example`, `@return`, `@raise [Git::FailedError]`.

### Tests
- `spec/unit/git/repository/remote_operations_spec.rb`: stub `Commands::Remote::List` →
  stdout `"origin\nteam/upstream\n"`, assert `["origin", "team/upstream"]`; empty-stdout → `[]`.
- `spec/integration/git/repository/remote_operations_spec.rb`: real repo with two remotes
  (one slash name), assert both names are returned.

### Done when
- Unit + integration green; RuboCop clean; YARD coverage clean.

---

## PR 2 — BranchInfo stored fields + remote-aware parser
**Branch:** `feat/branchinfo-slash-remote-parsing`
**Depends on:** nothing (backward compatible; default behavior unchanged)
**Value:** `Git::Parsers::Branch.parse_list(stdout, remote_names: [...])` resolves slash
remotes correctly; `BranchInfo` can carry an explicit `remote_name` (with `short_name` derived).

### Changes — `lib/git/branch_info.rb`
- **Alt 1-lite: store ONLY `:remote_name` as a new `Data.define` member; keep `short_name`
  DERIVED (not a member).**
- Add `:remote_name` to the `Data.define` member list (NOT `:short_name`).
- Add `initialize` override inside the block using private `UNSET = Object.new.freeze`
  sentinel: when `remote_name:` not supplied, derive via `BRANCH_REFNAME_REGEXP`
  (preserves all existing `BranchInfo.new` callsites); when supplied, store as given.
- Keep `short_name` as a COMPUTED method: derive from `refname` given the (now reliable)
  `remote_name` — strip `(refs/)?remotes/<remote_name>/` for remote branches, or
  `refs/heads/` for local branches. Deterministic from `refname` + `remote_name`, so it
  never needs storing and stays out of `Data` equality/hash/with.
- Remove only the `remote_name` computed method body (now a field accessor); `short_name`
  stays a method (rewritten to use `remote_name`).
- Keep `detached?`, `unborn?`, `remote?`, `current?`, `other_worktree?`, `symref?`, `to_s`.
- YARD: add `@!attribute` doc for the single new stored field `remote_name`; keep `short_name`
  documented as a derived method; soften the `BRANCH_REFNAME_REGEXP` `@note` (now a fallback
  used inside `initialize`, not the sole path).

### Changes — `lib/git/parsers/branch.rb`
- Add private `resolve_remote_name(refname, remote_names)`:
  - `nil` if refname is not under `(refs/)?remotes/`.
  - Strip `(refs/)?remotes/` prefix; select configured names that are a prefix of `path + "/"`;
    pick the LONGEST match.
  - When `remote_names` empty OR no match (stale ref): fall back to single-segment regex.
- `build_branch_info(fields, remote_names: [])`: call `resolve_remote_name`; pass only
  `:remote_name` explicitly to `BranchInfo.new` (`short_name` is derived by BranchInfo).
- Thread `remote_names:` through `parse_branch_line(line, remote_names: [])` and
  `parse_list(stdout, remote_names: [])`. Default `[]` = current behavior (regex fallback).
- YARD `@param remote_names` on the three methods.
- Note: no separate `resolve_short_name` helper needed — BranchInfo derives `short_name`
  from `refname` + the resolved `remote_name`.

### Tests
- `spec/unit/git/branch_info_spec.rb`: existing callsites unchanged (fallback); add examples
  that an explicit `remote_name:` is stored and that `short_name` is correctly derived from it
  (incl. slash-remote case); equality note (`Data#==` now includes ONE new member,
  `remote_name` — for non-slash remotes regex==explicit so still equal). Audit for `.with` usage.
- `spec/unit/git/parsers/branch_spec.rb`: update stubs to new signature; add
  `parse_list(stdout, remote_names: ['team/upstream'])` correctness (both `remote_name` and the
  derived `short_name`); longest-prefix example (both `team` and `team/upstream` configured →
  `team/upstream` wins); stale-ref fallback example.
- `spec/integration/git/parsers/branch_spec.rb`: repo with `team/upstream` remote,
  `remote_names: ['team/upstream']` → correct `remote_name`/`short_name`.

### Done when
- All existing branch specs still green (no behavior change at default); new specs green;
  RuboCop + YARD clean.

---

## PR 3 — Wire `branch_list` end-to-end (closes #919)
**Branch:** `fix/919-branch-list-slash-remote`
**Depends on:** PR 1 (`remote_names`) + PR 2 (parser accepts `remote_names:`)
**Value:** `repo.branch_list`, `repo.branches`, `branches_all`, and `Git::Branches#[]` all
report correct remote/branch split for slash remotes. Closes #919.

### Changes — `lib/git/repository/branching.rb`
- `branch_list(*patterns, remote_names: nil)`:
  - When `remote_names` nil, call `self.remote_names` to fetch automatically.
  - Pass `remote_names:` to `Git::Parsers::Branch.parse_list`.

### Changes — docs / scope note
- `lib/git/branch.rb`: update the `@note` on `BRANCH_NAME_REGEXP` (the string-constructor path)
  to state slash remotes are not resolved there and reference #919 + the follow-up issue.

### Tests
- `spec/unit/git/repository/branching_spec.rb` `#branch_list`: update `parse_list` stub
  expectations to `(stdout, remote_names: [...])`; add test that `remote_names` is auto-called
  when not given; add test that explicit `remote_names:` bypasses the auto call.
- `spec/integration/git/repository/branching_spec.rb`: repo with `team/upstream` remote →
  `branch_list` returns `BranchInfo` with `remote_name == 'team/upstream'`, `short_name == 'main'`.
- `spec/unit/git/branches_spec.rb` (or integration): `Git::Branches#[]` lookup with a slash
  remote resolves correctly (`branch.full` = `remotes/team/upstream/main`, and the
  `remotes/`-stripped key works).

### Finalize
- File a follow-up issue for the `Git::Branch` string-constructor path
  (`BRANCH_NAME_REGEXP`) and link it from the `@note` and from #919.
- Confirm #919 acceptance examples (`remote_name` → `'team/upstream'`, `short_name` →
  `'feature/foo'`) are covered by integration tests.

### Done when
- Full suite green; RuboCop + YARD clean; #919 examples demonstrably fixed; follow-up issue filed.

---

## Accepted decisions (finalized)
1. String path (`Git::Branch::BRANCH_NAME_REGEXP`): leave as documented limitation (PR 3 note +
   follow-up issue). Not fixed in this series.
2. Design is **Alt 1-lite**: store ONLY `remote_name` as a new `Data.define` member; keep
   `short_name` derived from `refname` + `remote_name`. One new member → smaller
   equality/hash/with footprint than storing both.
3. Stale `refs/remotes/` ref matching no configured remote: fall back to single-segment regex.
4. Keyword arg named `remote_names:` everywhere (parser + facade).
5. Add BOTH unit and integration tests for `remote_names`.
6. Defer the two-pass "only fetch remotes if refs/remotes present" optimization.
7. Full YARD updates in each PR.
8. Add a `Git::Branches#[]` slash-remote lookup test (PR 3).
9. #919 is satisfied by PR 3 (issue is scoped to `BranchInfo#remote_name`/`#short_name`).

## Relevant files
- `lib/git/repository/remote_operations.rb` — PR 1 (`remote_names`)
- `lib/git/branch_info.rb` — PR 2 (fields, `initialize`, YARD)
- `lib/git/parsers/branch.rb` — PR 2 (`remote_names:` threading, resolve helpers)
- `lib/git/repository/branching.rb` — PR 3 (`branch_list`)
- `lib/git/branch.rb` — PR 3 (string-path `@note` only; no code fix)
- specs: remote_operations (PR1), branch_info + parsers/branch (PR2), branching + branches (PR3)

## Not changing (auto-correct after PR 3)
- `branches_all` — uses `info.remote_name`/`#short_name`; values become correct.
- `Git::Branch#initialize_from_branch_info` — uses these; values become correct.
- All existing `BranchInfo.new` callsites — `initialize` fallback keeps them working.
