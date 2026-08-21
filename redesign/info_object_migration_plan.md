# Plan: Migrate ActiveRecord-style classes to `*Info` value objects

This document is the durable summary and issue index for the effort to migrate
ruby-git's "ActiveRecord-style" domain classes (rich objects constructed with
`def initialize(base, ...)` that both hold data **and** perform git operations)
toward immutable `*Info` value objects (DAOs), following the pattern established
by `Git::BranchInfo` and `Git::RemoteInfo`.

It captures analysis and decisions so they are not re-derived in future sessions.
It is a planning/index document, not a specification — each tracked issue owns the
detailed design for its area.

## Contents

- [Motivation](#motivation)
- [The pattern](#the-pattern)
- [Status of each class](#status-of-each-class)
- [Issue index](#issue-index)
- [Versioning and sequencing](#versioning-and-sequencing)
- [Key decisions](#key-decisions)
- [Open threads](#open-threads)

## Motivation

The modern facade design returns immutable, parser-built value objects
(`Git::BranchInfo`, `Git::RemoteInfo`, `Git::StashInfo`, `Git::TagInfo`,
`Git::ConfigEntryInfo`, the `Diff*Info` family, …). Several older classes predate
this and mix data with operations while holding a repository reference (`@base`).
They are harder to test, encourage stateful usage, and (in some cases) carry
latent bugs. Migrating them to `*Info` value objects plus name-based facade
operations aligns the whole API and unblocks cleaner deprecations.

The recurring "tell" for a migration candidate is a `def initialize(base, ...)`
constructor combined with operation methods — the object both *is* data and
*does* work.

## The pattern

For each domain:

1. **Value object** — an immutable `Data.define` `*Info` at the top-level `Git::`
   namespace holding only parsed metadata, with `#to_s` returning the string a
   caller can pass back to git-facing methods (e.g. a refname or stash selector).
2. **Parser** — a `Git::Parsers::*` that builds `Array<*Info>` from raw git output.
3. **Facade** — `Git::Repository::*` methods that return the value objects and that
   accept names / `*Info` / any `#to_s` for operations.
4. **Deprecation** — the legacy AR class, its collection, and the facade methods
   that return them are deprecated (additive, non-breaking) in one major and
   removed in the next.

## Status of each class

| Domain | AR class(es) | Value object | State |
| --- | --- | --- | --- |
| Branch | `Git::Branch` / `Git::Branches` | `Git::BranchInfo`, `Git::DetachedHeadInfo` | Value object + `branch_list` shipped; deprecation of AR classes tracked (#1639) |
| Remote | `Git::Remote` | `Git::RemoteInfo` | `RemoteInfo` + parser shipped; `remotes` deprecation tracked (#1640); `Git::Remote` class deprecation tracked (#1643) |
| Stash | `Git::Stash` / `Git::Stashes` | `Git::StashInfo` (exists) | Redesign tracked (#1634); `Git::Branch#stashes` cleanup (#1637) |
| Worktree | `Git::Worktree` / `Git::Worktrees` | *(needs `Git::WorktreeInfo`)* | Redesign tracked (#1635) — value object + parser do not exist yet |
| Tag | `Git::Object::Tag` | `Git::TagInfo` (exists) | Half-migrated; finish tracked under umbrella (#1636) |
| Commit / Tree / Blob | `Git::Object::Commit/Tree/Blob` | *(none)* | Deferred, umbrella (#1636) |
| Status | `Git::Status` / `Git::Status::StatusFile` | *(none)* | Deferred, umbrella (#1636) |
| Author | `Git::Author` (mutable) | *(none)* | Deferred, umbrella (#1636) |
| Diff / Log | `Git::Diff`, `Git::Log` | many `Diff*Info`, `Git::Log::Result` | Value layer largely exists; return-type audit deferred (#1636) |

## Issue index

- **#1631** — bug: slash-containing remote names in the `Git::Branch` string
  constructor path. Kept open; resolution is to route users to the `BranchInfo`
  path (folds into #1639).
- **#1634** — redesign `Git::Repository::Stashing` around `Git::StashInfo`.
- **#1635** — redesign `Git::Repository::WorktreeOperations` around a new
  `Git::WorktreeInfo` (needs value object + parser first).
- **#1636** — umbrella tracker for post-7.x AR→`*Info` migrations
  (Commit/Tree/Blob, finish Tag, Status, Author, Diff/Log audit).
- **#1637** — deprecate `Git::Branch#stashes` (ignores the branch, returns all
  repo stashes) in favor of `Git::Repository#stashes_all`.
- **#1639** — deprecate `Git::Branch` / `Git::Branches` and
  `Git::Repository#branch` / `#branches` in favor of the `BranchInfo` API.
- **#1640** — deprecate `Git::Repository#remotes` in favor of `#remote_list`
  (from `remote_refactor_plan.md` PR 3, Step 5).
- **#1641** — add `Git::Repository#in_branch` and a merge-into-branch facade path
  (preconditions for #1639).
- **#1643** — deprecate `Git::Remote` (and `Git::Repository#remote`) in favor of
  the `RemoteInfo` API (remote analog of #1639; depends on #1640).

## Versioning and sequencing

- Each migration is **additive + deprecate** in one major, **remove** in the next
  (e.g. deprecate in 5.x → remove in 6.x, or the analogous later pair).
- Stash (#1634) and Worktree (#1635) are the in-flight redesigns; the remaining
  candidates in #1636 are intentionally deferred until after the 7.x cycle.
- **Guardrail during any major:** do not add *new* public APIs that return
  AR-style objects that are already destined for deprecation. When touching these
  areas, prefer adding the value-object-returning method. The `Git::Object::Tag`
  vs `Git::TagInfo` split is the most important to watch (already half-migrated).

## Key decisions

- **`Git::WorktreeInfo` should capture the full porcelain record** — `path`,
  `head`, `branch`, `bare`, `detached`, `locked` (+reason), `prunable` (+reason) —
  not just the `[dir, sha]` tuple `worktrees_all` returns today.
- **Branch has no capability gap.** An audit confirmed every `Git::Branch`
  operation already delegates to an existing `Git::Repository` facade method that
  accepts a name/string. The only missing pieces are two composites — `in_branch`
  and the `merge(branch)` overload — tracked in #1641 as deprecation preconditions.
- **`checkout` semantic wrinkle:** `Git::Branch#checkout` auto-creates the branch
  first; `Git::Repository#checkout(name)` does not. Deprecation notes must call
  this out.
- **`Git::Branch#stashes` is effectively a latent bug** — it ignores the branch
  receiver and returns all repository stashes — so it is "deprecate and delete,"
  not "migrate" (#1637).
- **`Git::Repository::Branching` / `RemoteOperations` / `WorktreeOperations` are
  the replacements, not deprecation targets.** Only the specific methods that
  return AR objects (`#branch`, `#branches`, `#remotes`, `#worktree`,
  `#worktrees`) are deprecated; the operation methods stay.
- **Stashes are not branch-scoped in git**, so no branch-scoped stash API is
  warranted.

## Open threads

All previously loose threads are now tracked within the issues above:

- **`Git::Repository#worktree` / `#worktrees` factory deprecation** — in scope of
  #1635 (confirmed in its transition plan).
- **`config_remote` relationship to `remote_list`** — folded into #1640 as an open
  question to resolve during that work.
