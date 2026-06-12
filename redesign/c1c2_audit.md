# C1c-2 Audit: `Git::Base` → `Git::Repository` Inventory

**Date:** 2026-06-06

**Branch:** `agents/c1c2-audit-inventory-documentation`

**Produced by:** Step C1c-2 (research-and-documentation only; no production code changed)

This document is the exhaustive public-method inventory required before any
remediation work (PR 2–4) begins. Every public instance method on `Git::Base`
is compared against `Git::Repository`, and every orphaned public method on
`Git::Lib` that would silently break when `Git::Lib` is removed in Phase 4 is
surfaced.

## Status Legend

| Status | Meaning |
|--------|---------|
| ✅ | **Already covered** — method exists on `Git::Repository` (or a module it includes) with equivalent behavior |
| ⬜ | **Needs migration** — method is absent from `Git::Repository`; should be migrated |
| ❌ | **Intentional removal** — method should not survive in v5; must be deprecated with upgrade notes before C1d |
| ⚠️ | **Signature gap** — method exists on `Git::Repository` but its parameter signature is inconsistent with the C1c-1 policy (legacy-contract vs 5.x-native) |
| 🔍 | **Needs human decision** — unclear classification; surfaced for the human reviewer |

---

## 1. Summary Counts

| Bucket | ✅ | ⬜ | ❌ | ⚠️ | 🔍 | Total |
|--------|----|----|----|----|-----|-------|
| 1 — Path/accessors | 4 | 0 | 0 | 0 | 0 | 4 |
| 2 — Compatibility aliases & wrappers | 7 | 0 | 0 | 1 | 0 | 8 |
| 3 — Low-level public methods | 0 | 6 | 0 | 0 | 1 | 7 |
| 4 — Factory & domain-object returns | 12 | 0 | 0 | 0 | 0 | 12 |
| 5 — Keyword-arg signature review | 3 | 0 | 0 | 5 | 1 | 9 |
| 6 — `Git::Lib` orphaned public methods | — | — | — | — | — | **⚠️ see §7** |
| **Grand total (Buckets 1–5)** | **26** | **6** | **0** | **6** | **2** | **40** |

> ⚠️ **Bucket 6 contains more than 40 genuine orphaned public methods**
> (see §7 for the full count breakdown). Per the audit instructions, this
> section recommends splitting the Bucket 6 promotion work into a companion
> document rather than embedding it in the remediation PRs.

---

## 2. Full Inventory Table

Sorted by bucket, then alphabetically within bucket.

| Method | Bucket | Status | Destination / Notes |
|--------|--------|--------|---------------------|
| `dir` | 1 | ✅ | `Git::Repository#dir` (repository.rb:89) |
| `index` | 1 | ✅ | `Git::Repository#index` (repository.rb:113) |
| `repo` | 1 | ✅ | `Git::Repository#repo` (repository.rb:101) |
| `repo_size` | 1 | ✅ | `Git::Repository#repo_size` (repository.rb:131) |
| `checkout` | 2 | ⚠️ | `Branching#checkout(branch = nil, options = {})` diverges from 4.x `(*, **)` — legacy-contract violation; corrected signature is `(*args, **kwargs)` (see §5) |
| `diff_name_status` | 2 | ✅ | `alias diff_name_status diff_path_status` already present in `Git::Repository::Diffing` (diffing.rb:382) |
| `is_branch?` | 2 | ✅ | Deprecated stub added to `Git::Repository::Branching` delegating to `branch?` |
| `is_local_branch?` | 2 | ✅ | Deprecated stub added to `Git::Repository::Branching` delegating to `local_branch?` |
| `is_remote_branch?` | 2 | ✅ | Deprecated stub added to `Git::Repository::Branching` delegating to `remote_branch?` |
| `remove` | 2 | ✅ | `alias remove rm` added to `Git::Repository::Staging` |
| `reset_hard` | 2 | ✅ | `Git::Repository::Staging#reset_hard` — deprecated wrapper delegating to `reset(commitish, hard: true)` |
| `revparse` | 2 | ✅ | `alias revparse rev_parse` added to `Git::Repository::ObjectOperations` |
| `apply` | 3 | ⬜ | New facade in `Git::Repository::Staging` (or new `Patching` module); `Git::Commands::Apply` ✅ |
| `apply_mail` | 3 | ⬜ | Same module as `apply`; `Git::Commands::Am` ✅ |
| `describe` | 3 | ⬜ | New facade in `Git::Repository::Inspecting`; `Git::Commands::Describe` ✅ |
| `gc` | 3 | ⬜ | New facade in new `Git::Repository::Maintenance`; `Git::Commands::Gc` ✅ |
| `read_tree` | 3 | ⬜ | New facade in `Git::Repository::Staging` (already owns index ops); `Git::Commands::ReadTree` ✅ |
| `repack` | 3 | ⬜ | New facade in new `Git::Repository::Maintenance`; `Git::Commands::Repack` ✅ |
| `cat_file` | 3 | 🔍 | `Git::Base#cat_file` delegates to `lib.cat_file` which **does not exist** in `Git::Lib`; the method is silently broken; `Git::Repository::ObjectOperations#cat_file_contents` is the likely intended replacement — see §6 |
| `add_tag` | 4 | ✅ | `Git::Repository::ObjectOperations#add_tag` |
| `branch` | 4 | ✅ | `Git::Repository::Branching#branch` |
| `branches` | 4 | ✅ | `Git::Repository::Branching#branches` |
| `delete_tag` | 4 | ✅ | `Git::Repository::ObjectOperations#delete_tag` |
| `gblob` | 4 | ✅ | `Git::Repository::ObjectOperations#gblob` |
| `gcommit` | 4 | ✅ | `Git::Repository::ObjectOperations#gcommit` |
| `gtree` | 4 | ✅ | `Git::Repository::ObjectOperations#gtree` |
| `object` | 4 | ✅ | `Git::Repository::ObjectOperations#object` |
| `remote` | 4 | ✅ | `Git::Repository::RemoteOperations#remote` |
| `remotes` | 4 | ✅ | `Git::Repository::RemoteOperations#remotes` |
| `tag` | 4 | ✅ | `Git::Repository::ObjectOperations#tag` — returns `Git::Object::Tag` ✅ |
| `tags` | 4 | ✅ | `Git::Repository::ObjectOperations#tags` — returns `Array<Git::Object::Tag>` ✅ |
| `add` | 5 | ✅ | `Git::Base#add(paths = '.', **)` already uses `**`; `Staging#add(paths = '.', **)` matches — no legacy-contract violation |
| `checkout_file` | 5 | ✅ | Branching#checkout_file: `(version, file)` — matches `Git::Base` signature ✅ |
| `commit` | 5 | ⚠️ | Committing#commit: `(message = nil, **opts)` → should be `(message, opts = {})` |
| `commit_all` | 5 | ⚠️ | Committing#commit_all: `(*, **)` → should be `(message, opts = {})` |
| `commit_tree` | 5 | ⚠️ | Committing#commit_tree: `(tree, **opts)` → should be `(tree = nil, opts = {})` |
| `fsck` | 5 | 🔍 | Inspecting#fsck: `(*objects, **)` vs base.rb `(*objects, **opts)` — both already use kwargs; functionally equivalent but `**` is anonymous; needs explicit classification |
| `reset` | 5 | ⚠️ | Staging#reset: `(commitish = nil, **)` → should be `(commitish = nil, opts = {})` |
| `revert` | 5 | ✅ | Merging#revert: `(commitish = nil, opts = {})` — matches `Git::Base` signature ✅ |
| `write_and_commit_tree` | 5 | ⚠️ | Committing#write_and_commit_tree: `(**)` → should be `(opts = {})` (legacy-contract — 4.x `Git::Base#write_and_commit_tree` used `opts = {}`) |

---

## 3. ⬜ Migration Candidates

### Bucket 2

#### `remove`

**Current implementation:** `Git::Base` line 420 — `alias remove rm`.
**Proposed destination:** `Git::Repository::Staging` — add `alias remove rm` after the `rm` method.
**Classification:** `legacy-contract` — 4.x public API alias.
**Effort:** trivial (one-line alias).

#### `revparse`

**Current implementation:** `Git::Base` line 879 — `alias revparse rev_parse`.
**Proposed destination:** `Git::Repository::ObjectOperations` — add `alias revparse rev_parse`.
**Classification:** `legacy-contract` — widely used 4.x shorthand.
**Effort:** trivial (one-line alias).

#### `is_branch?`

**Current implementation:** `Git::Base#is_branch?(branch)` (base.rb:325–331) — already carries `Git::Deprecation.warn` in 4.x and v5. `Git::Repository::Branching#branch?` is the replacement.
**Proposed destination:** `Git::Repository::Branching` — add deprecated stub `is_branch?(branch)` that emits `Git::Deprecation.warn` and delegates to `branch?`.
**Classification:** `legacy-contract` — must be present on `Git::Repository` so callers receive the deprecation warning rather than `NoMethodError`.
**Effort:** trivial (one-method deprecated stub; `@deprecated` YARD tag missing and should be added).

#### `is_local_branch?`

**Current implementation:** `Git::Base#is_local_branch?(branch)` (base.rb:299–305) — already carries `Git::Deprecation.warn` in 4.x and v5. `Git::Repository::Branching#local_branch?` is the replacement.
**Proposed destination:** `Git::Repository::Branching` — add deprecated stub `is_local_branch?(branch)` that emits `Git::Deprecation.warn` and delegates to `local_branch?`.
**Classification:** `legacy-contract` — same rationale as `is_branch?`.
**Effort:** trivial (one-method deprecated stub; `@deprecated` YARD tag missing and should be added).

#### `is_remote_branch?`

**Current implementation:** `Git::Base#is_remote_branch?(branch)` (base.rb:312–318) — already carries `Git::Deprecation.warn` in 4.x and v5. `Git::Repository::Branching#remote_branch?` is the replacement.
**Proposed destination:** `Git::Repository::Branching` — add deprecated stub `is_remote_branch?(branch)` that emits `Git::Deprecation.warn` and delegates to `remote_branch?`.
**Classification:** `legacy-contract` — same rationale as `is_branch?`.
**Effort:** trivial (one-method deprecated stub; `@deprecated` YARD tag missing and should be added).

#### `reset_hard`

**Current implementation:** `Git::Base#reset_hard(commitish = nil, opts = {})` (base.rb:431) — already carries a `Git::Deprecation.warn` and a YARD `@deprecated` tag in v5. In 4.x it was a non-deprecated public method.
**Proposed destination:** `Git::Repository::Staging` — add a deprecated wrapper method `reset_hard(commitish = nil, opts = {})` that emits `Git::Deprecation.warn` and delegates to `reset(commitish, **opts.merge(hard: true))`.
**Classification:** `legacy-contract` — must be present on `Git::Repository` so that callers receive the deprecation warning rather than a `NoMethodError` when `Git.open` switches to return `Git::Repository`.
**Effort:** trivial (one-method deprecated wrapper; `@deprecated` tag already written in `Git::Base`).

### Bucket 3

#### `describe`

**Current implementation:** `Git::Base#describe(committish = nil, opts = {})` (base.rb:466) → `lib.describe(committish, opts)`. `Git::Lib#describe` (lib.rb:223) → `Git::Commands::Describe.new(self).call(...)`. `Git::Commands::Describe` ✅ exists.
**Proposed destination:** `Git::Repository::Inspecting` — already houses `show` and `fsck`; `describe` is a read-only inspection operation.
**Classification:** `legacy-contract` — preserve `(committish = nil, opts = {})` exactly.
**Effort:** moderate — needs option allowlist cross-referenced against 4.x `*_OPTION_MAP`; the `exact-match` → `exact_match` key translation currently in `Git::Lib#describe` must be preserved in the facade.

#### `gc`

**Current implementation:** `Git::Base#gc` (base.rb:699) → `lib.gc`. `Git::Lib#gc` (lib.rb:1778) → `Git::Commands::Gc.new(self).call(prune: true, aggressive: true, auto: true)`. `Git::Commands::Gc` ✅ exists.
**Proposed destination:** New `Git::Repository::Maintenance` topic module (pair with `repack`). Alternatively `Git::Repository::Inspecting` if a new module is not justified.
**Classification:** `legacy-contract` — preserve `()` (no arguments).
**Effort:** trivial — zero-arity facade; fixed options forwarded to command class.

#### `repack`

**Current implementation:** `Git::Base#repack` (base.rb:695) → `lib.repack`. `Git::Lib#repack` (lib.rb:1774) → `Git::Commands::Repack.new(self).call(a: true, d: true)`. `Git::Commands::Repack` ✅ exists.
**Proposed destination:** New `Git::Repository::Maintenance` topic module (pair with `gc`).
**Classification:** `legacy-contract` — preserve `()` (no arguments).
**Effort:** trivial — zero-arity facade; fixed options forwarded to command class.

#### `apply`

**Current implementation:** `Git::Base#apply(file)` (base.rb:754) — applies patch only when `File.exist?(file)`; delegates to `lib.apply(file)`. `Git::Lib#apply` (lib.rb:1248) → `Git::Commands::Apply.new(self).call(...)`. `Git::Commands::Apply` ✅ exists.
**Proposed destination:** `Git::Repository::Staging` — already owns low-level index operations; `apply` is a patch-application operation closely related to staging.
**Classification:** `legacy-contract` — preserve `(file)` signature and the `File.exist?` guard in `Git::Base`.
**Effort:** moderate — must preserve the `File.exist?` guard and the `chdir: @git_work_dir` execution option. Tests must cover both the case where the file exists (patch applied) and where it does not (no-op).

#### `apply_mail`

**Current implementation:** `Git::Base#apply_mail(file)` (base.rb:760) — applies `git am` only when `File.exist?(file)`; delegates to `lib.apply_mail(file)`. `Git::Lib#apply_mail` (lib.rb:1252) → `Git::Commands::Am::Apply.new(self).call(...)`. `Git::Commands::Am` ✅ exists.
**Proposed destination:** `Git::Repository::Staging` — alongside `apply`.
**Classification:** `legacy-contract` — preserve `(file)` signature and the `File.exist?` guard.
**Effort:** moderate — same concerns as `apply`. Tests must cover both the case where the file exists (patch applied) and where it does not (no-op).

#### `read_tree`

**Current implementation:** `Git::Base#read_tree(treeish, opts = {})` (base.rb:813) → `lib.read_tree(treeish, opts)`. `Git::Lib#read_tree` (lib.rb:1798) → `Git::Commands::ReadTree.new(self).call(...)`. `Git::Commands::ReadTree` ✅ exists.
**Proposed destination:** `Git::Repository::Staging` — already owns `checkout_index`, `write_tree`, etc.
**Classification:** `legacy-contract` — preserve `(treeish, opts = {})`.
**Effort:** trivial — thin orchestration; the option allowlist (`:prefix`) is already defined in `Git::Lib::READ_TREE_ALLOWED_OPTS`.

---

## 4. ❌ Intentional Removals

> There are no intentional removals in Buckets 1–5. All deprecated methods
> from 4.x must be present on `Git::Repository` as deprecated stubs so callers
> receive a `Git::Deprecation.warn` rather than a `NoMethodError` when
> `Git.open` switches to return `Git::Repository`.

---

## 5. ⚠️ Signature Gaps

Six gaps are `legacy-contract` violations. Five are cases where the facade
method uses `**opts` or anonymous `**` keyword-splat where the 4.x predecessor
used a positional `opts = {}` hash — in Ruby 3, passing a bare `Hash` variable
as the last positional argument to a `**`-accepting method raises `ArgumentError`.
One (`checkout`) uses explicit named parameters where 4.x used an all-splat form.

**Note on `add`:** `Git::Base#add(paths = '.', **)` already uses `**` (see
base.rb:198), so `Git::Repository::Staging#add(paths = '.', **)` is consistent
with the existing `Git::Base` signature and is **not** a legacy-contract
violation. `add` does not appear in the fixes below.

### `Git::Repository::Branching#checkout`

**Current signature:** `checkout(branch = nil, options = {})` (branching.rb:116)
**Corrected signature:** `checkout(*args, **kwargs)` (legacy-contract)
**C1c-1 rule violated:** Rule 1 — `Git::Base#checkout` in 4.x used `(*, **)`. The explicit `(branch = nil, options = {})` in the facade does not accept keyword arguments; callers passing keyword-style options (e.g. `checkout('main', force: true)`) will receive `ArgumentError` in Ruby 3 because there is no `**` acceptor in the signature.
**Action:** This fix is more involved than the other five gaps — the implementation body must not be discarded. Change the signature to `(*args, **kwargs)` and unpack into named locals at the top of the method body:

```ruby
def checkout(*args, **kwargs)
  branch  = args[0]
  options = (args[1] || {}).merge(kwargs)
  # ... rest of current logic unchanged (is_a?(Hash) guard, assert_valid_opts!, translate_checkout_opts)
end
```

The `(args[1] || {}).merge(kwargs)` unpacking correctly handles all three calling conventions in Ruby 3:
- Positional-hash callers: `checkout('branch', opts_hash)` → `args[1] = opts_hash`, `kwargs = {}`
- Keyword callers: `checkout('branch', force: true)` → `args[1] = nil`, `kwargs = {force: true}`
- Mixed (both positional hash and keyword args): `checkout('branch', {a: 1}, b: 2)` → merged correctly

Using `args[1] || kwargs` (without merge) would silently drop `kwargs` whenever `args[1]` is truthy. The internal validation and option-translation logic (`assert_valid_opts!`, `translate_checkout_opts`) must be preserved unchanged.

### `Git::Repository::Staging#reset`

**Current signature:** `reset(commitish = nil, **)` (staging.rb:88)
**Corrected signature:** `reset(commitish = nil, opts = {})` (legacy-contract)
**C1c-1 rule violated:** Rule 1. `Git::Base#reset` used positional `opts = {}`.
**Action:** Change `**)` to `opts = {})`.

### `Git::Repository::Committing#commit`

**Current signature:** `commit(message = nil, **opts)` (committing.rb:77)
**Corrected signature:** `commit(message, opts = {})` (legacy-contract)
**C1c-1 rule violated:** Rule 1. `Git::Base#commit` used `(message, opts = {})` — `message` is required. The facade also relaxed `message` to optional, which is a silent API drift.
**Action:** Remove default from `message`; change `**opts` to `opts = {}`.

### `Git::Repository::Committing#commit_all`

**Current signature:** `commit_all(*, **)` (committing.rb:110)
**Corrected signature:** `commit_all(message, opts = {})` (legacy-contract)
**C1c-1 rule violated:** Rule 1. `Git::Base#commit_all` used `(message, opts = {})`. The current splatted form accepts anything and makes the public contract invisible.
**Action:** Restore explicit positional parameters.

### `Git::Repository::Committing#commit_tree`

**Current signature:** `commit_tree(tree, **opts)` (committing.rb:147)
**Corrected signature:** `commit_tree(tree = nil, opts = {})` (legacy-contract)
**C1c-1 rule violated:** Rule 1. `Git::Base#commit_tree` used `(tree = nil, opts = {})` — `tree` is optional in the legacy API.
**Action:** Add default `= nil` to `tree`; change `**opts` to `opts = {}`.

### `Git::Repository::Committing#write_and_commit_tree`

**Current signature:** `write_and_commit_tree(**)` (committing.rb:186)
**Corrected signature:** `write_and_commit_tree(opts = {})` (legacy-contract)
**C1c-1 rule violated:** Rule 1. `Git::Base#write_and_commit_tree` in 4.x used `(opts = {})`. The current anonymous `**` splat is a legacy-contract violation.
**Action:** Change `**)` to `opts = {})` and pass `opts` as a keyword splat to the delegated call: `commit_tree(write_tree, **opts)`.

---

## 6. 🔍 Human Decisions Needed

### `cat_file` (Bucket 3)

**Background:** `Git::Base#cat_file(objectish)` (base.rb:925) delegates to `lib.cat_file(objectish)`. However, **`Git::Lib` contains no `cat_file` method**. The method is effectively broken at runtime (calling it raises `NoMethodError`). `Git::Repository::ObjectOperations` provides `cat_file_contents(object)` which returns the raw content of a git object — the most plausible intended behavior.

**Specific question:** Should `cat_file` be:

**Option A — Alias for `cat_file_contents`:** Add `alias cat_file cat_file_contents` to `Git::Repository::ObjectOperations` and wire `Git::Base#cat_file` to delegate there. Preserves a broken API under a new implementation.

**Option B — Deprecated stub:** Add a `@deprecated` tag to `Git::Base#cat_file` directing callers to `cat_file_contents`, emit a `Git::Deprecation.warn`, and do not promote it to `Git::Repository`. The method was silently broken; promoting it may confuse callers who never successfully used it.

**Option C — Silent removal:** Remove `Git::Base#cat_file` in v5 with an upgrade note. It was broken in the current codebase and therefore has no legitimate callers.

**Recommended default if no human input:** Option B — issue a deprecation warning and point to `cat_file_contents`, which is the clear successor.

**Decision:** In 4.x, `Git::Base#cat_file` delegated to `Git::Lib#cat_file_contents`, so `cat_file` is the established public name. To preserve backward compatibility, add `alias cat_file cat_file_contents` to `Git::Repository::ObjectOperations` (keeping `cat_file_contents` as the primary 5.x-native method name), and add a `Git::Base#cat_file` delegator that forwards to the facade. Add tests for both the alias and the delegator.

---

### `branch_delete` (Bucket 6 orphan — classification decision)

**Background:** `Git::Repository::Branching#branch_delete(*branches, **options)` uses keyword-arg splat. `Git::Lib#branch_delete(*branches, **options)` also uses `**options`. There is no `Git::Base#branch_delete` delegator (the method is not publicly accessible via `g.branch_delete` — it is a Bucket 6 orphan exposed only via `g.lib.branch_delete`). Because there is no 4.x `Git::Base` predecessor with a `opts = {}` signature, the `legacy-contract` rule may not apply.

**Specific question:** Should `branch_delete` be classified as:

**Option A — `5.x-native`:** The method was added to `Git::Lib` with keyword args and was never part of the public `Git::Base` surface. The `**options` signature in `Git::Repository` is therefore correct and intentional. Document as `5.x-native`.

**Option B — `legacy-contract` with signature fix:** Treat `Git::Lib#branch_delete` as the public contract source (Pattern B) and require the `Git::Repository` facade to mirror `(*branches, **options)` exactly. No change needed — the signatures already match.

**Option C — `legacy-contract` with reversion to `opts = {}`:** Revert to a positional options hash for consistency with other methods. This would break any callers already using `branch_delete` with keyword args.

**Recommended default if no human input:** Option A or B — both are acceptable since the lib.rb signature already uses keyword args. Option A is cleaner because it gives `5.x-native` status.

**Decision:** In 4.x, `Git::Lib#branch_delete(branch)` accepted a single branch with no options. The v5 signature added `*branches` (multi-branch support) and `**options` (to control `--force`). Classify as `legacy-contract`. Change the `**options` keyword splat to a positional `opts = {}` hash for Ruby 3 safety and consistency with the C1c-1 policy. The `*branches` variadic argument is a legitimate v5 improvement and should be kept. Final signature: `branch_delete(*branches, opts = {})`.

---

### `fsck` (Bucket 5)

**Background:** `Git::Base#fsck(*objects, **opts)` (base.rb:749) and `Git::Repository::Inspecting#fsck(*objects, **)` (inspecting.rb:146) both accept keyword args. The only difference is anonymous `**` vs named `**opts`. For external callers the behavior is identical. However, the named form `**opts` is more conventional and matches the base.rb signature.

**Specific question:** Should `fsck` be:

**Option A — `legacy-contract` with minor fix:** Change `**` to `**opts` in the facade signature for clarity and consistency. Functionally equivalent; cosmetic improvement.

**Option B — `5.x-native`:** `fsck` was migrated early and the `**` anonymous form was intentional per the facade-implementation conventions. Classify as `5.x-native` and leave the signature as-is.

**Recommended default if no human input:** Option A — the named `**opts` is more readable and matches the base.rb public contract. The change is purely cosmetic.

**Decision:** In 4.x, `Git::Base#fsck` already used `*objects, **opts` (keyword args). The v5 facade `Git::Repository::Inspecting#fsck(*objects, **)` is functionally identical for all callers — the only difference is the anonymous `**` vs named `**opts`, which has no effect on the public API. Classify as `legacy-contract` (4.x signature is keyword-based). Leave the signature as-is; no change required.

---

## 7. Bucket 6 — `Git::Lib` Orphaned Public Methods

> ⚠️ **SIZE WARNING:** This bucket contains **more than 40 genuine orphaned
> public methods**. Per the audit instructions this warrants a companion
> document. **Recommendation: do not embed the full Bucket 6 remediation in
> PR 2–4. Create a separate document `redesign/c1c2_bucket6_lib_orphans.md`
> and address promotions in a dedicated PR 5.**

The subsections below provide a high-level triage. The companion document
should contain the full per-method analysis.

### 7.1 Scope

`Git::Lib` is declared `@api private` but `Git::Base#lib` is a public accessor,
making every public method on `Git::Lib` reachable as `g.lib.method_name`. When
`Git::Lib` is deleted in Phase 4, all such call sites silently break.

The criterion for inclusion in this bucket:
- Public instance method in `lib/git/lib.rb` (i.e., appears before `private` at line 2200)
- **No same-named delegator on `Git::Base`** (methods already covered by a
  `Git::Base` wrapper appear in Buckets 1–5)

### 7.2 Methods Already Migrated to `Git::Repository` (trivial base.rb wiring needed)

These orphans exist on `Git::Lib` and have already been migrated to a
`Git::Repository` module. The remediation is a trivial one-line delegator in
`Git::Base`. They should be batched into PR 2 or a separate lightweight PR.

| `Git::Lib` method | `Git::Repository` home | Status |
|-------------------|------------------------|--------|
| `branches_all` | `Git::Repository::Branching` | ✅ `Git::Base` delegator added (PR 2d) |
| `branch_contains(commit, branch_name = '')` | `Git::Repository::Branching` | ✅ `Git::Base` delegator added (PR 2d) |
| `branch_delete(*branches, **options)` | `Git::Repository::Branching` | ✅ `Git::Base` delegator added (PR 2d) |
| `branch_new(branch, start_point = nil, options = {})` | `Git::Repository::Branching` | ✅ `Git::Base` delegator added (PR 2d) |
| `cat_file_commit(object)` | `Git::Repository::ObjectOperations` | ✅ `Git::Base` delegator added (PR 2d) |
| `cat_file_contents(object)` | `Git::Repository::ObjectOperations` | ✅ `Git::Base` delegator added; `alias cat_file cat_file_contents` added (PR 2d) |
| `cat_file_size(object)` | `Git::Repository::ObjectOperations` | ✅ `Git::Base` delegator added (PR 2d) |
| `cat_file_tag(object)` | `Git::Repository::ObjectOperations` | ✅ `Git::Base` delegator added (PR 2d) |
| `cat_file_type(object)` | `Git::Repository::ObjectOperations` | ✅ `Git::Base` delegator added (PR 2d) |
| `config_remote(name)` | `Git::Repository::RemoteOperations` | ✅ `Git::Base` delegator added (PR 2d) |
| `diff_index(treeish)` | `Git::Repository::Diffing` | ✅ `Git::Base` delegator added (PR 2d) |
| `full_tree(sha)` | `Git::Repository::ObjectOperations` | ✅ `Git::Base` delegator added (PR 2d) |
| `name_rev(commit_ish)` | `Git::Repository::ObjectOperations` | ✅ `Git::Base` delegator added (PR 2d) |
| `stash_apply(id = nil)` | `Git::Repository::Stashing` | ✅ `Git::Base` delegator added (PR 2d) |
| `stash_clear` | `Git::Repository::Stashing` | ✅ `Git::Base` delegator added (PR 2d) |
| `stash_save(message)` | `Git::Repository::Stashing` | ✅ `Git::Base` delegator added (PR 2d) |
| `stashes_all` | `Git::Repository::Stashing` | ✅ `Git::Base` delegator added (PR 2d) |
| `tag_sha(tag_name)` | `Git::Repository::ObjectOperations` | ✅ `Git::Base` delegator added (PR 2d) |
| `untracked_files` | `Git::Repository::StatusOperations` | ✅ `Git::Base` delegator added (PR 2d) |
| `worktree_add(dir, commitish = nil)` | `Git::Repository::WorktreeOperations` | ✅ `Git::Base` delegator added (PR 2d) |
| `worktree_prune` | `Git::Repository::WorktreeOperations` | ✅ `Git::Base` delegator added (PR 2d) |
| `worktree_remove(dir)` | `Git::Repository::WorktreeOperations` | ✅ `Git::Base` delegator added (PR 2d) |
| `worktrees_all` | `Git::Repository::WorktreeOperations` | ✅ `Git::Base` delegator added (PR 2d) |

Also note name-mismatch cases where `Git::Lib` uses a different name than `Git::Repository`:

| `Git::Lib` method | `Git::Repository` equivalent | Action |
|-------------------|-------------------------------|--------|
| `conflicts` (yields file, your, their) | `Git::Repository::Merging#each_conflict` | 🔍 `conflicts` yields paths to temporary files containing staged content; `each_conflict` does too — verify behavioral equivalence |
| `empty?` | `Git::Repository::StatusOperations#no_commits?` | 🔍 keep `empty?` as a deprecated alias on `Git::Base`, pointing to `no_commits?` |
| `remote_add(name, url, opts)` | `Git::Repository::RemoteOperations#add_remote` | 🔍 name mismatch; `add_remote` is already on `Git::Base` — `remote_add` is the lib name; mark as internal |
| `remote_remove(name)` | `Git::Repository::RemoteOperations#remove_remote` | 🔍 name mismatch; `remove_remote` is already on `Git::Base` |
| `remote_set_url(name, url, opts)` | `Git::Repository::RemoteOperations#set_remote_url` | 🔍 name mismatch; `set_remote_url` is already on `Git::Base` |
| `namerev` (alias for `name_rev`) | `Git::Repository::ObjectOperations#name_rev` | ✅ `alias namerev name_rev` added (PR 2e) |
| `object_contents` (alias for `cat_file_contents`) | `Git::Repository::ObjectOperations#cat_file_contents` | ✅ `alias object_contents cat_file_contents` added (PR 2e) |
| `object_type` (alias for `cat_file_type`) | `Git::Repository::ObjectOperations#cat_file_type` | ✅ `alias object_type cat_file_type` added (PR 2e) |
| `object_size` (alias for `cat_file_size`) | `Git::Repository::ObjectOperations#cat_file_size` | ✅ `alias object_size cat_file_size` added (PR 2e) |
| `commit_data` (alias for `cat_file_commit`) | `Git::Repository::ObjectOperations#cat_file_commit` | ✅ `alias commit_data cat_file_commit` added (PR 2e) |
| `tag_data` (alias for `cat_file_tag`) | `Git::Repository::ObjectOperations#cat_file_tag` | ✅ `alias tag_data cat_file_tag` added (PR 2e) |
| `revparse` (alias for `rev_parse`) | (covered in Bucket 2) | ✅ covered |
| `branch_current` | `Git::Repository::Branching#current_branch` | ✅ `alias branch_current current_branch` added to `Git::Base` (name mismatch: `Git::Lib` defines `branch_current`; `Git::Repository` exposes `current_branch`) |

### 7.3 Methods NOT Yet in `Git::Repository` (new facade work required)

These require a new facade method before a base.rb delegator can be added.

| `Git::Lib` method | Assessment | Recommended status |
|-------------------|------------|--------------------|
| `change_head_branch(branch_name)` | Low-level `git symbolic-ref HEAD refs/heads/<name>`; used internally for branch renaming and orphan checkout. Plausible external use by tooling. | ✅ promoted — facade in `Git::Repository::Branching` + `Git::Base` delegator added (PR 5h-1) |
| `config_get(name)` | Returns a single config value. Used by tooling. Part of the existing `config()` facade which reads/writes. | 🔍 human decision — expose as `config_get` or fold into `config(name)`? |
| `config_list` | Returns full config hash. Used by tooling. | 🔍 human decision — expose separately or fold into `config()`? |
| `config_set(name, value, options)` | Sets a config value. | 🔍 human decision — expose separately or fold into `config(name, value)`? |
| `global_config_get(name)` | Gets a global config value. | ✅ promoted — `global_config` facade + deprecated aliases in `Git::Repository::Configuring` + `Git::Base` delegators added (PR 5h-3) |
| `global_config_list` | Returns the full global config hash. | ✅ promoted — `global_config` facade + deprecated aliases in `Git::Repository::Configuring` + `Git::Base` delegators added (PR 5h-3) |
| `global_config_set(name, value)` | Sets a global config value. | ✅ promoted — `global_config` facade + deprecated aliases in `Git::Repository::Configuring` + `Git::Base` delegators added (PR 5h-3) |
| `git_version` | Returns `Git::Version` for the current binary. Useful for tooling that conditionally enables features. Not a repository concern; `Git.git_version` is the canonical API. | ✅ delegator added to `Git::Base` — delegates to `Git.git_version` |
| `list_files(ref_dir)` | Lists files under `.git/refs/{ref_dir}`. Internal ref-filesystem access. No plausible clean public use. | ❌ remove — internal plumbing; direct callers should migrate to `Git::Repository` ref-inspection methods |
| `ls_remote(location = nil, opts = {})` | Lists remote refs. Clearly useful externally. | ✅ promoted — facade in `Git::Repository::RemoteOperations` + `Git::Base` delegator added (PR 5f) |
| `mv(source, destination, options = {})` | Wraps `git mv`. Externally useful. | ⬜ promote — new facade in `Git::Repository::Staging`; `Git::Commands::Mv` ✅ exists; trivial effort |
| `parse_config(file)` | Parses a config file from path. | 🔍 human decision — expose or fold into `config()` with `:file` option? |
| `stash_list` | Returns a formatted string `"stash@{0}: ...\n..."` — distinct from `stashes_all` which returns structured data. | ✅ promoted as deprecated method — `Git::Repository::Stashing#stash_list` + `Git::Base` delegator added (PR 5h-5); remove in v6 |
| `unmerged` | Returns paths with unresolved merge conflicts. Already partially covered by `each_conflict` (yields paths to temporary files for staged content). Pure path list is useful. | ✅ promoted — public method in `Git::Repository::Merging` + `Git::Base` delegator added (PR 5h-6) |
| `current_branch_state` | Returns a `HeadState` value object with `:state` (`:active`/`:unborn`/`:detached`) and `:name`. Richer than `current_branch`. Legacy `Git::Lib` implementation used a mutable `Struct`; promoted facade uses an immutable `Data` object. | ✅ promoted — `HeadState` Data object defined in `Git::Repository::Branching`; facade in `Git::Repository::Branching` + `Git::Base` delegator added (PR 5g) |

### 7.4 Internal Plumbing — Mark as ❌ Remove

These methods are technically public (defined before `private` in lib.rb) but are
clearly internal helpers with no plausible external use. They should appear in the
upgrade notes as "unsupported; remove any `g.lib.X` calls."

| Method | Reason |
|--------|--------|
| `assert_args_are_not_options(arg_name, *args)` | Input validation helper |
| `assert_valid_opts(opts, allowed)` | Option validation helper |
| `cat_file_object_meta(object)` | Internal batch cat-file helper |
| `command_capturing(*, **options_hash)` | Low-level command execution infrastructure |
| `command_streaming(*, **options_hash)` | Low-level command execution infrastructure |
| `each_cat_file_header(data)` | Parsing helper |
| `handle_deprecated_path_option(opts)` | Deprecation handling helper |
| `normalize_pathspecs(pathspecs, arg_name)` | Input normalization helper |
| `parse_cat_file_meta(output, object)` | Parsing helper |
| `parse_config_list(lines)` | Internal config parsing helper |
| `process_commit_data(data, sha)` | Parsing helper (used by `cat_file_commit`) |
| `validate_pathspec_types(pathspecs, arg_name)` | Input validation helper |

### 7.5 Bucket 6 Count Summary

| Status | Count |
|--------|-------|
| ✅ promote (repo already had it, `Git::Base` delegator added — PR 2d; or alias added) | 29 |
| ⬜ promote (new facade work required) | 1 |
| ❌ remove (internal plumbing) | 12 |
| 🔍 human decision | 11 |
| **Total orphaned methods** | **56** |

> **Recommendation:** The 24 "trivial wiring" promotions can be handled in PR 5a
> as a batch. The 1 "new facade" promotion and 11 human-decision items should be
> addressed in a companion document (`redesign/c1c2_bucket6_lib_orphans.md`)
> before PR 5b begins.

---

## 8. Recommended PR Split for Remediation

### PR 2 — Aliases / Wrappers (Bucket 2 + Bucket 6 trivial wiring)

**Scope:**
- Add aliases `remove`, `revparse` to the corresponding
  `Git::Repository` modules (2 trivial changes; `diff_name_status` is already
  aliased in `Git::Repository::Diffing` and requires no further action).
- Add deprecated wrapper `reset_hard` to `Git::Repository::Staging` (calls
  `reset` with `hard: true`; `@deprecated` tag already present in `Git::Base`).
- Add deprecated stubs `is_branch?`, `is_local_branch?`, `is_remote_branch?`
  to `Git::Repository::Branching`; add missing YARD `@deprecated` tags to all
  three in both `Git::Base` and the new stubs.
- Batch-add `Git::Base` delegators for the 24 Bucket 6 "trivial wiring" orphans
  from §7.2 that already have a `Git::Repository` home.
- Add legacy aliases to `Git::Repository::ObjectOperations` for `namerev`,
  `object_contents`, `object_type`, `object_size`, `commit_data`, `tag_data`.

**Dependency:** None — can be merged first.

**Effort:** Small (mostly one-line additions, no new command classes or parsers).

### PR 3 — Low-Level Methods (Bucket 3)

**Scope:**
- Implement facade methods for `describe`, `repack`, `gc`, `apply`, `apply_mail`,
  `read_tree` in `Git::Repository`.
- Create a new `Git::Repository::Maintenance` module for `repack` and `gc`.
- Add `Git::Base` delegators for all six methods.
- Resolve `cat_file` per the human decision in §6.
- Add facade methods for `mv`, `ls_remote`, `current_branch_state`
  from Bucket 6 §7.3 (new facade work needed).

**Dependency:** PR 3 is independent of PR 2 but should be merged after PR 2
to keep the base.rb delegator surface tidy.

**Effort:** Moderate (6 facade methods + 4 new bucket-6 facades + optional new module).

### PR 4 — Signature Sweep (Bucket 5)

**Scope:**
- Fix 6 `⚠️` signatures:
  - `checkout` in `Git::Repository::Branching`: change `(branch = nil, options = {})` → `(*args, **kwargs)` and unpack into named locals; preserve all internal validation logic
  - `reset` in `Git::Repository::Staging`: change `**)` → `opts = {})`
  - `commit` in `Git::Repository::Committing`: change `(message = nil, **opts)` → `(message, opts = {})`
  - `commit_all` in `Git::Repository::Committing`: change `(*, **)` → `(message, opts = {})`
  - `commit_tree` in `Git::Repository::Committing`: change `(tree, **opts)` → `(tree = nil, opts = {})`
  - `write_and_commit_tree` in `Git::Repository::Committing`: change `(**)` → `(opts = {})`
  (`add` is already aligned with `Git::Base` and requires no change.)
- Resolve human decision for `fsck` classification.

**Dependency:** PR 4 can be merged in any order relative to PR 2 and PR 3,
**but must be merged before** `Git.open`/`.clone`/`.init`/`.bare` are changed
to return `Git::Repository` directly — the signature fixes prevent Ruby 3
`ArgumentError` regressions for callers who pass a positional `Hash` variable
to `reset`, `commit`, `commit_all`, `commit_tree`, or `write_and_commit_tree`,
and prevent call-shape regressions for `checkout`. (`add` is exempt: both
`Git::Base#add` and `Git::Repository::Staging#add` already use `**`.)

**Effort:** Small (signature changes only; no new logic). Tests for the
legacy call shapes must be added or verified.

### PR 5 — Bucket 6 Companion Document + Remaining Promotions

**Scope:**
- Author `redesign/c1c2_bucket6_lib_orphans.md` to capture the full Bucket 6
  analysis for the 16 human-decision items and the 7 new-facade-required items.
- Implement the 7 new facade promotions once human decisions are resolved.
- Mark the 12 internal plumbing methods as `@api private` or move them behind
  `private` in `Git::Lib` as a preparatory step for Phase 4 deletion.

**Dependency:** PR 5 depends on PR 2 (trivial wiring PR sets the delegation
baseline), and on the companion document review for the 16 human-decision items.

**Effort:** Moderate-to-large; primarily gated on human decisions.

### Dependency Graph

```
PR 2 (aliases + trivial wiring)
  └─→ PR 3 (low-level facades) ──┐
  └─→ PR 4 (signature sweep) ────┤──→ Phase C1d (switch Git.open to return Git::Repository)
PR 5 (bucket-6 companion + new facades) (can proceed in parallel with PR 3/4)
```

No circular dependencies. PR 2 unblocks everything else and should be merged
first.
