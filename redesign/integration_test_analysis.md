# Excessive Integration Tests

- [Summary](#summary)
- [Integration elapsed time data](#integration-elapsed-time-data)
- [Success criteria](#success-criteria)
- [Criteria used](#criteria-used)
- [Tests to remove](#tests-to-remove)
- [Controversial removals](#controversial-removals)

## Summary

The integration test suite takes **3m 6s** when run sequentially and **4m 22s** on the Windows CI build (which runs tests in parallel). Many of those tests do not add signal beyond what the unit tests already cover — they test git's own behavior, duplicate other integration tests, exercise option variants whose argument building is already verified by unit specs, or exercise single-command delegators that are already covered by the underlying command's own integration spec. Removing them will reduce sequential and CI build times without reducing meaningful coverage.

This document identifies **350 tests** in the [Tests to remove](#tests-to-remove) section that do not satisfy the criteria in the project's three test-standards skills
([`rspec-unit-testing-standards`](../.github/skills/rspec-unit-testing-standards/SKILL.md),
[`command-test-conventions`](../.github/skills/command-test-conventions/SKILL.md), and
[`facade-test-conventions`](../.github/skills/facade-test-conventions/SKILL.md)).

Of those 350, **22 are flagged as [Controversial removals](#controversial-removals)** — tests where a reasonable engineer could argue for keeping them, typically because no dedicated parser integration spec exists for the underlying parser or because a spec comment explicitly documents why the test is present. Those 22 should be discussed before removal.

**Analysis based on commit [`7de996a`](https://github.com/ruby-git/ruby-git/commit/7de996a45b1850edd7e68337ec11e1d8cb7a386b) (main, 2026-07-14)**

## Integration elapsed time data

The integration test suite takes 3m 6s when run locally:

```bash
$ time bundle exec rake spec:integration
Finished in 3 minutes 5.5 seconds (files took 0.29591 seconds to load)
885 examples, 0 failures, 8 pending

Randomized with seed 19563
Coverage report generated for RSpec to /Users/james/github/ruby-git/ruby-git/coverage.
Line Coverage: 92.81% (12603 / 13580)
Branch Coverage: 49.66% (582 / 1172)

Test coverage is below the low coverage threshold of 100%


real    3m6.560s
user    0m46.039s
sys     1m53.131s
$
```

When running integration tests in parallel locally, it takes 31s:

```bash
$ time bundle exec rake spec:integration:parallel
Line Coverage: 92.81% (12603 / 13580)
Branch Coverage: 49.66% (582 / 1172)

885 examples, 0 failures, 8 pendings

Took 30 seconds

real    0m30.917s
user    1m16.136s
sys     2m18.696s
$
```

On the Windows CI builds, when running the tests in parallel, the build takes 4m 22s:

```text
Line Coverage: 92.86% (12597 / 13566)

Branch Coverage: 49.57% (581 / 1172)


Lcov style coverage report generated for RSpec-, RSpec-2, RSpec-3, RSpec-4 to D:/a/ruby-git/ruby-git/coverage/lcov

Test coverage is below the low coverage threshold of 100%


884 examples, 0 failures, 5 pendings

Took 262 seconds (4:22)
```

In the TruffleRuby build, running integration tests in parallel takes 2m 04s.

On the JRuby 10.0.0.1 build, running integration tests takes 1m 52s.

## Success criteria

**Scope of the deletion work:** remove all 328 tests listed in [Tests to remove](#tests-to-remove) that
are *not* also listed in [Controversial removals](#controversial-removals). The 22 controversial
tests are explicitly out of scope and should not be touched until a separate discussion has reached
a disposition on each one. This document records the analysis and rationale; the deletions are
implemented in [PR #1622](https://github.com/ruby-git/ruby-git/pull/1622).

328 deletions from a suite of 885 leaves **557 integration tests** (885 − 328 = 557).

Removing 328 tests (≈37% by count) will not yield a proportional time reduction. The removed tests
skew toward cheap operations — type checks, duplicate invocations of the same git command, and
pure-Ruby guard assertions — rather than the expensive ones (clone, fetch, push) that dominate
build time. On parallel builds the slowest shard determines wall time, so savings are further
diluted. A realistic estimate is **25–35% reduction in sequential runs** and **15–25% in parallel
builds**.

The primary success target is the Windows CI parallel build, the current worst-case at 4m 22s.

| Build | Before | After (measured) | Reduction | Target | Success |
| ----- | ------ | ---------------- | --------- | ------ | ------- |
| Sequential (local, macOS) | 3m 06s | 1m 54s | 38% | < 2m 00s | YES |
| Parallel (local, macOS) | 0m 31s | 0m 18s | 42% | < 0m 25s | YES |
| Parallel (Windows CI) | 4m 22s | 3m 11s | 35% | < 3m 00s | **NO** |
| Parallel (TruffleRuby CI) | 2m 04s | 1m 19s | 36% | < 1m 30s | YES |
| Serial (JRuby CI) | 1m 52s | 1m 20s | 29% | < 1m 20s | **NO** |
| Integration test count | 885 | 557 | 37% | 557 | YES |

The work is considered successful when:

1. All time targets in the table above are met on the first full CI run after the deletions.
2. The test suite passes with no behavioral regressions.
3. The 22 [controversial removals](#controversial-removals) remain untouched pending a separate
   review.

## Criteria used

| Label | Meaning |
| ----- | ------- |
| Option variant | Tests a different flag or operand on an already-covered code path; argument building is verified by the unit spec |
| Git state/output assertion | Verifies git's behavior or output after the call; tests git, not the Ruby command or facade |
| Duplicate invocation | Same arguments and exit code as a retained test; no independent failure mode under Rule 24 |
| Command error path | `Git::FailedError` wrapping is the command layer's concern and is covered by the command's own integration spec |
| Second failure path | A command's integration spec needs only one `FailedError` scenario to confirm error wrapping |
| Pure-Ruby guard | The `ArgumentError` is raised before any git call; no real git is needed; unit spec is sufficient |
| Type-only assertion | `be_a(X)` or string type check has no independent failure mode; any adjacent test that uses the value would fail first (Rule 24) |
| Single-command delegator | The facade method forwards directly to one command with no post-processing; covered by the underlying command's integration spec |
| Single-command + parser | The underlying parser has its own dedicated integration spec, making facade-level re-exercise redundant |
| Result factory | Constructs a domain object with no git call; covered by unit spec |
| Rule 24 violation | `not_to raise_error` asserts nothing observable; any real behavioral test would fail before this |
| Structural detail | Tests a git output delimiter, field count, or field order that is already implied by every successful parse in the same file |
| Synthetic input | Uses a hand-crafted string instead of real git output; duplicates unit spec coverage |

## Tests to remove

| File | Line | Reason |
| ---- | ---- | ------ |
| spec/integration/git/commands/add_spec.rb | 32 | Option variant (`all:` flag) |
| spec/integration/git/commands/am/apply_spec.rb | 39 | Git state/output assertion (verifies the applied commit, not argument building) |
| spec/integration/git/commands/apply_spec.rb | 44 | Option variant (`:check` flag) |
| spec/integration/git/commands/apply_spec.rb | 38 | Git state/output assertion (patch applied to working tree) |
| spec/integration/git/commands/archive_spec.rb | 36 | Option variant (`out:` execution option) |
| spec/integration/git/commands/branch/delete_spec.rb | 37 | Duplicate exit-code-1 coverage; simpler nonexistent-branch failure already covers error wrapping |
| spec/integration/git/commands/branch/delete_spec.rb | 19 | Duplicate invocation; explicit exit-0 test already provides the required smoke coverage |
| spec/integration/git/commands/branch/list_spec.rb | 24 | Git state/output assertion (empty output when no branches exist) |
| spec/integration/git/commands/branch/set_upstream_spec.rb | 42 | Second failure path |
| spec/integration/git/commands/branch/unset_upstream_spec.rb | 44 | Second failure path |
| spec/integration/git/commands/cat_file/batch_spec.rb | 50 | Option variant (`--batch-all-objects` flag) |
| spec/integration/git/commands/cat_file/batch_spec.rb | 42 | Option variant (multiple operands) |
| spec/integration/git/commands/cat_file/batch_spec.rb | 35 | Option variant (`--batch-check` mode) |
| spec/integration/git/commands/cat_file/batch_spec.rb | 27 | Git state/output assertion (missing-object inline reporting) |
| spec/integration/git/commands/cat_file/filtered_spec.rb | 36 | Duplicate invocation; same code path as the retained smoke test |
| spec/integration/git/commands/cat_file/filtered_spec.rb | 27 | Option variant (`--path=` flag) |
| spec/integration/git/commands/cat_file/raw_spec.rb | 77 | Second failure path |
| spec/integration/git/commands/cat_file/raw_spec.rb | 62 | Option variant (type-check mode) |
| spec/integration/git/commands/cat_file/raw_spec.rb | 53 | Option variant (`-p` pretty-print mode) |
| spec/integration/git/commands/cat_file/raw_spec.rb | 44 | Option variant (`-s` size mode) |
| spec/integration/git/commands/cat_file/raw_spec.rb | 35 | Option variant (`-t` type mode) |
| spec/integration/git/commands/checkout/branch_spec.rb | 27 | Option variant (`-b` create-branch flag) |
| spec/integration/git/commands/checkout_index_spec.rb | 31 | Option variant (path operand) |
| spec/integration/git/commands/checkout_index_spec.rb | 25 | Option variant (`force:` flag) |
| spec/integration/git/commands/clean_spec.rb | 34 | Option variant (directory-cleaning flags) |
| spec/integration/git/commands/clone_spec.rb | 66 | Outside permitted scope; logger behavior is not a smoke, exit-code, or error-path test |
| spec/integration/git/commands/clone_spec.rb | 46 | Option variant (`bare:` flag) |
| spec/integration/git/commands/clone_spec.rb | 39 | Option variant (`chdir:` execution option) |
| spec/integration/git/commands/commit_spec.rb | 27 | Option variant (`allow_empty:` flag) |
| spec/integration/git/commands/commit_tree_spec.rb | 41 | Git state/output assertion (merge-commit parent SHAs) |
| spec/integration/git/commands/commit_tree_spec.rb | 32 | Git state/output assertion (single parent SHA) |
| spec/integration/git/commands/config_option_syntax/get_all_spec.rb | 19 | Git state/output assertion (stdout content) |
| spec/integration/git/commands/config_option_syntax/get_color_spec.rb | 29 | Option variant (default operand) |
| spec/integration/git/commands/config_option_syntax/get_color_spec.rb | 23 | Duplicate invocation of preceding smoke test |
| spec/integration/git/commands/config_option_syntax/get_regexp_spec.rb | 13 | Duplicate invocation of the natural exit-0 example |
| spec/integration/git/commands/config_option_syntax/get_spec.rb | 13 | Duplicate invocation of the natural exit-0 example |
| spec/integration/git/commands/config_option_syntax/remove_section_spec.rb | 32 | Git state/output assertion (section absent in config) |
| spec/integration/git/commands/config_option_syntax/remove_section_spec.rb | 26 | Duplicate invocation of retained smoke test |
| spec/integration/git/commands/config_option_syntax/rename_section_spec.rb | 29 | Git state/output assertion (section renamed in config) |
| spec/integration/git/commands/config_option_syntax/rename_section_spec.rb | 23 | Duplicate invocation of retained smoke test |
| spec/integration/git/commands/config_option_syntax/set_spec.rb | 33 | Option variant (`type:` flag with git-side normalization) |
| spec/integration/git/commands/config_option_syntax/set_spec.rb | 26 | Git state/output assertion (value persisted to config) |
| spec/integration/git/commands/config_option_syntax/set_spec.rb | 20 | Duplicate invocation of retained smoke test |
| spec/integration/git/commands/config_option_syntax/unset_all_spec.rb | 20 | Duplicate invocation of the natural exit-0 example |
| spec/integration/git/commands/config_option_syntax/unset_spec.rb | 32 | Git state/output assertion (entry absent from config) |
| spec/integration/git/commands/config_option_syntax/unset_spec.rb | 20 | Duplicate invocation of the natural exit-0 example |
| spec/integration/git/commands/describe_spec.rb | 34 | Option variant (`:always` flag in a specific repository state) |
| spec/integration/git/commands/describe_spec.rb | 27 | Option variant (`:long` flag) |
| spec/integration/git/commands/diff_files_spec.rb | 33 | Option variant (path operand) |
| spec/integration/git/commands/diff_files_spec.rb | 25 | Git state/output assertion (diff output content); also does not exercise the allowed exit code 1 |
| spec/integration/git/commands/diff_index_spec.rb | 43 | Duplicate invocation; second exit-0 example with no independent failure mode |
| spec/integration/git/commands/diff_index_spec.rb | 31 | Option variant (path operand) |
| spec/integration/git/commands/diff_index_spec.rb | 25 | Option variant (`cached:` flag) |
| spec/integration/git/commands/diff_spec.rb | 13 | Duplicate invocation; redundant with the dedicated exit-0 test at line 22 |
| spec/integration/git/commands/fsck/fsck_spec.rb | 39 | Option variant (specific-object operand) |
| spec/integration/git/commands/fsck/fsck_spec.rb | 31 | Option variant (option combination) |
| spec/integration/git/commands/grep_spec.rb | 92 | Option variant (`--not` compound pattern) |
| spec/integration/git/commands/grep_spec.rb | 84 | Option variant (`--or` compound pattern) |
| spec/integration/git/commands/grep_spec.rb | 77 | Option variant (`--and` compound pattern) |
| spec/integration/git/commands/grep_spec.rb | 71 | Pure-Ruby guard (`ArgumentError` before git call); DSL validation belongs in unit spec |
| spec/integration/git/commands/grep_spec.rb | 52 | Option variant (`:pathspec`) |
| spec/integration/git/commands/grep_spec.rb | 44 | Option variant (`:extended_regexp`) |
| spec/integration/git/commands/grep_spec.rb | 37 | Option variant (`:invert_match`) |
| spec/integration/git/commands/grep_spec.rb | 28 | Option variant (`:ignore_case`) |
| spec/integration/git/commands/init_spec.rb | 27 | Option variant (`bare:` flag) |
| spec/integration/git/commands/log_spec.rb | 31 | Option variant (revision range operand) |
| spec/integration/git/commands/ls_files_spec.rb | 75 | Pure-Ruby guard (`ArgumentError`); DSL validation belongs in unit spec |
| spec/integration/git/commands/ls_files_spec.rb | 61 | Option variant (`chdir:` execution option with output assertion) |
| spec/integration/git/commands/ls_files_spec.rb | 53 | Option variant (additional option combination) |
| spec/integration/git/commands/ls_files_spec.rb | 38 | Option variant (`others:`/`exclude_standard:` combination) |
| spec/integration/git/commands/ls_files_spec.rb | 28 | Option variant (`stage:` + pathspec combination) |
| spec/integration/git/commands/ls_tree_spec.rb | 45 | Option variant (path operand) |
| spec/integration/git/commands/ls_tree_spec.rb | 37 | Option variant (`name_only:` flag) |
| spec/integration/git/commands/ls_tree_spec.rb | 29 | Option variant (`r:` recursive flag) |
| spec/integration/git/commands/maintenance/register_spec.rb | 38 | Duplicate invocation of retained smoke test |
| spec/integration/git/commands/maintenance/run_spec.rb | 34 | Duplicate invocation of retained smoke test |
| spec/integration/git/commands/maintenance/start_spec.rb | 57 | Duplicate invocation of retained smoke test |
| spec/integration/git/commands/maintenance/stop_spec.rb | 39 | Duplicate invocation of retained smoke test |
| spec/integration/git/commands/maintenance/unregister_spec.rb | 42 | Duplicate invocation of retained smoke test |
| spec/integration/git/commands/merge/continue_spec.rb | 48 | Second failure path |
| spec/integration/git/commands/merge/quit_spec.rb | 41 | Rule 24 violation; `not_to raise_error` asserts nothing observable |
| spec/integration/git/commands/merge/start_spec.rb | 35 | Second failure path |
| spec/integration/git/commands/merge_base_spec.rb | 27 | Duplicate invocation; same exit-0 code path as the retained ancestor test at line 34 |
| spec/integration/git/commands/name_rev_spec.rb | 26 | Option variant (`:tags` flag) |
| spec/integration/git/commands/push_spec.rb | 34 | Duplicate invocation of the preceding smoke test at line 28 |
| spec/integration/git/commands/remote/prune_spec.rb | 26 | Option variant (`--dry-run` flag) |
| spec/integration/git/commands/remote/set_branches_spec.rb | 30 | Option variant (`:add` flag) |
| spec/integration/git/commands/remote/set_head_spec.rb | 44 | Option variant (`:delete` flag) |
| spec/integration/git/commands/remote/set_head_spec.rb | 35 | Option variant (`:auto` flag) |
| spec/integration/git/commands/remote/set_url_add_spec.rb | 35 | Option variant (`:push` flag) |
| spec/integration/git/commands/remote/set_url_delete_spec.rb | 37 | Option variant (`:push` flag) |
| spec/integration/git/commands/remote/set_url_spec.rb | 36 | Option variant (`:push` flag) |
| spec/integration/git/commands/repack_spec.rb | 20 | Option variant (`:a` + `:d` flags); duplicate of base smoke path |
| spec/integration/git/commands/reset_spec.rb | 43 | Option variant (`:pathspec` operand) |
| spec/integration/git/commands/reset_spec.rb | 36 | Git state/output assertion (index and working tree state after hard reset) |
| spec/integration/git/commands/reset_spec.rb | 30 | Duplicate invocation of retained smoke test |
| spec/integration/git/commands/rev_parse_spec.rb | 26 | Option variant (`--show-toplevel` flag) |
| spec/integration/git/commands/revert/quit_spec.rb | 36 | Redundant scenario; the no-op case at line 44 is the simpler retained smoke test |
| spec/integration/git/commands/rm_spec.rb | 26 | Option variant (`:cached` flag) |
| spec/integration/git/commands/show_ref/exclude_existing_spec.rb | 37 | Git state/output assertion (output filtering); tests git, not the command |
| spec/integration/git/commands/show_ref/exclude_existing_spec.rb | 31 | Option variant (mixed existing/nonexistent refs) |
| spec/integration/git/commands/show_ref/exclude_existing_spec.rb | 25 | Duplicate invocation of retained smoke test |
| spec/integration/git/commands/show_ref/exists_spec.rb | 19 | Duplicate invocation; same exit-0 code path as the retained test at line 25 |
| spec/integration/git/commands/show_ref/list_spec.rb | 63 | Option variant (`:dereference` flag) |
| spec/integration/git/commands/show_ref/list_spec.rb | 57 | Option variant (`:head` flag) |
| spec/integration/git/commands/show_ref/list_spec.rb | 50 | Option variant (`:branches` flag) |
| spec/integration/git/commands/show_ref/list_spec.rb | 44 | Option variant (`:heads` flag) |
| spec/integration/git/commands/show_ref/list_spec.rb | 38 | Option variant (`:tags` flag) |
| spec/integration/git/commands/show_ref/list_spec.rb | 20 | Duplicate invocation; same exit-0 code path as the retained test at line 26 |
| spec/integration/git/commands/show_ref/verify_spec.rb | 38 | Second failure path |
| spec/integration/git/commands/show_ref/verify_spec.rb | 25 | Duplicate invocation of the retained smoke test at line 19 |
| spec/integration/git/commands/show_spec.rb | 27 | Option variant (`out:` execution option) |
| spec/integration/git/commands/stash/branch_spec.rb | 37 | Second failure path |
| spec/integration/git/commands/stash/create_spec.rb | 31 | Git state/output assertion (empty stdout when nothing to stash) |
| spec/integration/git/commands/stash/list_spec.rb | 22 | Git state/output assertion (empty output in a clean repository) |
| spec/integration/git/commands/stash/push_spec.rb | 34 | Git state/output assertion (no-changes repository state) |
| spec/integration/git/commands/stash/show_spec.rb | 36 | Option variant (`--raw` format flag) |
| spec/integration/git/commands/stash/show_spec.rb | 29 | Option variant (`--patch` format flag) |
| spec/integration/git/commands/status_spec.rb | 25 | Option variant (path operand) |
| spec/integration/git/commands/symbolic_ref/read_spec.rb | 20 | Option variant (`:short` flag) |
| spec/integration/git/commands/symbolic_ref/update_spec.rb | 23 | Option variant (`:m` message flag) |
| spec/integration/git/commands/tag/delete_spec.rb | 27 | Duplicate invocation of the retained exit-0 smoke test |
| spec/integration/git/commands/tag/list_spec.rb | 25 | Git state/output assertion (empty stdout when no tags exist) |
| spec/integration/git/commands/tag/verify_spec.rb | 58 | Option variant plus failure; one failure path is sufficient |
| spec/integration/git/commands/tag/verify_spec.rb | 51 | Second failure path (multi-operand variant) |
| spec/integration/git/commands/tag/verify_spec.rb | 41 | Second failure path (unsigned annotated tag) |
| spec/integration/git/commands/tag/verify_spec.rb | 35 | Second failure path (unsigned lightweight tag) |
| spec/integration/git/commands/tag/verify_spec.rb | 26 | Rule 24 violation; test is permanently skipped (no GPG setup) and never executes |
| spec/integration/git/commands/update_ref/batch_spec.rb | 42 | Option variant (combined update+delete instructions) |
| spec/integration/git/commands/update_ref/batch_spec.rb | 32 | Option variant (delete-refs-via-stdin instructions) |
| spec/integration/git/commands/version_spec.rb | 24 | Pure-Ruby guard (`ArgumentError`); DSL validation belongs in unit spec |
| spec/integration/git/commands/worktree/add_spec.rb | 46 | Option variant (`--detach` flag) |
| spec/integration/git/commands/worktree/add_spec.rb | 35 | Git state/output assertion (`.git` file created in worktree) |
| spec/integration/git/commands/worktree/add_spec.rb | 30 | Git state/output assertion (worktree directory created on disk) |
| spec/integration/git/commands/worktree/list_spec.rb | 41 | Option variant (`:expire` value option) |
| spec/integration/git/commands/worktree/list_spec.rb | 35 | Option variant (`:z` + `:porcelain` combination) |
| spec/integration/git/commands/worktree/list_spec.rb | 29 | Option variant (`:verbose` flag) |
| spec/integration/git/commands/worktree/list_spec.rb | 24 | Option variant (`:porcelain` flag) |
| spec/integration/git/commands/worktree/lock_spec.rb | 31 | Option variant (`--reason` value option) |
| spec/integration/git/commands/worktree/prune_spec.rb | 29 | Option variant (`--verbose` flag) |
| spec/integration/git/commands/worktree/prune_spec.rb | 24 | Option variant (`--dry-run` flag) |
| spec/integration/git/commands/worktree/remove_spec.rb | 32 | Git state/output assertion (worktree directory removed from disk) |
| spec/integration/git/commands/write_tree_spec.rb | 27 | Option variant (`:prefix` value option) |
| spec/integration/git/git_spec.rb | 326 | Type-only assertion (`be_a(Git::Repository)`); Rule 24 violation — adjacent attribute tests would fail first |
| spec/integration/git/git_spec.rb | 307 | Type-only assertion (`be_a(Git::Repository)`); Rule 24 violation |
| spec/integration/git/git_spec.rb | 288 | Type-only assertion (`be_a(Git::Repository)`); Rule 24 violation |
| spec/integration/git/git_spec.rb | 263 | Type-only assertion (`be_a(Git::Repository)`); Rule 24 violation |
| spec/integration/git/git_spec.rb | 239 | Type-only assertion (`be_a(Git::Repository)`); Rule 24 violation |
| spec/integration/git/git_spec.rb | 223 | Type-only assertion (`be_a(Git::Repository)`); Rule 24 violation |
| spec/integration/git/git_spec.rb | 208 | Type-only assertion (`be_a(Git::Repository)`); Rule 24 violation |
| spec/integration/git/git_spec.rb | 187 | Type-only assertion (`be_a(Git::Repository)`); Rule 24 violation |
| spec/integration/git/git_spec.rb | 164 | Type-only assertion (`be_a(Git::Repository)`); Rule 24 violation |
| spec/integration/git/git_spec.rb | 128 | Type-only assertion (`be_a(Git::Repository)`); Rule 24 violation |
| spec/integration/git/git_spec.rb | 21 | Type-only assertion (`be_a(Git::Repository)`); Rule 24 violation |
| spec/integration/git/parsers/branch_spec.rb | 197 | Synthetic input; duplicates unit spec coverage |
| spec/integration/git/parsers/branch_spec.rb | 74 | Synthetic input; duplicates unit spec coverage |
| spec/integration/git/parsers/branch_spec.rb | 47 | Structural detail (field order); implied by every successful parse in this file |
| spec/integration/git/parsers/branch_spec.rb | 36 | Structural detail (field count); implied by every successful parse in this file |
| spec/integration/git/parsers/branch_spec.rb | 31 | Structural detail (pipe delimiter); implied by every successful parse in this file |
| spec/integration/git/parsers/config_entry_spec.rb | 134 | Duplicate invocation; parsing detail already covered by the preceding real-output test in the same context |
| spec/integration/git/parsers/fsck_spec.rb | 183 | Structural detail; tests `TAGGED_PATTERN` regex constant directly, already exercised through other parse tests |
| spec/integration/git/parsers/fsck_spec.rb | 163 | Structural detail; tests `ROOT_PATTERN` regex constant directly |
| spec/integration/git/parsers/fsck_spec.rb | 144 | Structural detail; tests `OBJECT_PATTERN` regex constant directly |
| spec/integration/git/parsers/fsck_spec.rb | 114 | Duplicate invocation; same tagged object validated by adjacent test |
| spec/integration/git/parsers/fsck_spec.rb | 70 | Duplicate invocation; same dangling object already identified by preceding test |
| spec/integration/git/parsers/fsck_spec.rb | 63 | Git state/output assertion; tests git's deterministic SHA computation, not parser logic |
| spec/integration/git/parsers/fsck_spec.rb | 35 | Duplicate invocation; same clean-repository assertion as the preceding healthy-repository test |
| spec/integration/git/parsers/stash_spec.rb | 190 | Structural detail (field order); implied by every successful parse in this file |
| spec/integration/git/parsers/stash_spec.rb | 180 | Structural detail (field count); implied by every successful parse in this file |
| spec/integration/git/parsers/stash_spec.rb | 175 | Structural detail (unit-separator delimiter); implied by every successful parse in this file |
| spec/integration/git/parsers/stash_spec.rb | 139 | Git state/output assertion; tests git's object ID uniqueness, not parser logic |
| spec/integration/git/parsers/stash_spec.rb | 40 | Type-only assertion (`be_a(StashInfo)`); Rule 24 violation |
| spec/integration/git/parsers/stash_spec.rb | 28 | Synthetic input; duplicates unit spec coverage |
| spec/integration/git/parsers/tag_spec.rb | 245 | Structural detail (field order); implied by every successful parse in this file |
| spec/integration/git/parsers/tag_spec.rb | 234 | Structural detail (field count); implied by every successful parse in this file |
| spec/integration/git/parsers/tag_spec.rb | 229 | Structural detail (record separator); implied by every successful parse in this file |
| spec/integration/git/parsers/tag_spec.rb | 224 | Structural detail (field delimiter); implied by every successful parse in this file |
| spec/integration/git/parsers/tag_spec.rb | 206 | Synthetic input; duplicates unit spec coverage |
| spec/integration/git/parsers/tag_spec.rb | 127 | Duplicate invocation; exact multiline-message equality already asserted by the preceding example in the same context |
| spec/integration/git/parsers/tag_spec.rb | 64 | Duplicate invocation; repeats `target_oid` assertion from the adjacent populated-metadata example |
| spec/integration/git/parsers/tag_spec.rb | 22 | Synthetic input; duplicates unit spec coverage |
| spec/integration/git/repository/branching_spec.rb | 516 | Result factory (`#branch`); no facade-owned processing, covered by unit spec |
| spec/integration/git/repository/branching_spec.rb | 510 | Result factory (`#branch`); no facade-owned processing, covered by unit spec |
| spec/integration/git/repository/branching_spec.rb | 499 | Type-only assertion (`Git::CommandLine::Result`); Rule 24 violation |
| spec/integration/git/repository/branching_spec.rb | 493 | Git state/output assertion; `#update_ref` is a single-command delegator covered by `update_ref/update_spec.rb` |
| spec/integration/git/repository/branching_spec.rb | 473 | Single-command + parser (`#branches_all`); `Git::Parsers::Branch` has a dedicated integration spec |
| spec/integration/git/repository/branching_spec.rb | 460 | Single-command + parser (`#branches_all`); `Git::Parsers::Branch` has a dedicated integration spec |
| spec/integration/git/repository/branching_spec.rb | 453 | Single-command + parser (`#branches_all`); `Git::Parsers::Branch` has a dedicated integration spec |
| spec/integration/git/repository/branching_spec.rb | 435 | Single-command + parser (`#branches_all`); `Git::Parsers::Branch` has a dedicated integration spec |
| spec/integration/git/repository/branching_spec.rb | 429 | Single-command + parser (`#branches_all`); `Git::Parsers::Branch` has a dedicated integration spec |
| spec/integration/git/repository/branching_spec.rb | 423 | Single-command + parser (`#branches_all`); `Git::Parsers::Branch` has a dedicated integration spec |
| spec/integration/git/repository/branching_spec.rb | 398 | Option variant (`#branch_contains` non-matching pattern); single-command delegator |
| spec/integration/git/repository/branching_spec.rb | 390 | Single-command delegator (`#branch_contains`); basic smoke path covered by `branch/list_spec.rb` |
| spec/integration/git/repository/branching_spec.rb | 370 | Single-command delegator (`#change_head_branch`); post-commit case covered by `symbolic_ref/update_spec.rb` line 13 |
| spec/integration/git/repository/branching_spec.rb | 337 | Option variant (`#branch_delete` multiple-arg form); argument building covered by unit spec |
| spec/integration/git/repository/branching_spec.rb | 281 | Command error path (`#branch_new`); covered by `branch/create_spec.rb` |
| spec/integration/git/repository/branching_spec.rb | 271 | Single-command delegator (`#branch_new` with start point); covered by `branch/create_spec.rb` |
| spec/integration/git/repository/branching_spec.rb | 256 | Single-command delegator (`#branch_new`); return-value contract covered by unit spec |
| spec/integration/git/repository/branching_spec.rb | 249 | Git state/output assertion (`#branch_new`); single-command delegator covered by `branch/create_spec.rb` |
| spec/integration/git/repository/branching_spec.rb | 154 | Duplicate invocation; redundant with line 150 in the same "no remotes configured" context |
| spec/integration/git/repository/branching_spec.rb | 127 | Type-only assertion (`#checkout_index` with `path_limiter:`); option variant, no independent failure mode |
| spec/integration/git/repository/branching_spec.rb | 120 | Type-only assertion (`#checkout_index` with `all:`); single-command delegator, no independent failure mode |
| spec/integration/git/repository/branching_spec.rb | 106 | Command error path (`#checkout`); covered by `checkout/branch_spec.rb` |
| spec/integration/git/repository/branching_spec.rb | 87 | Option variant (`#checkout` with `new_branch:`); single-command delegator covered by `checkout/branch_spec.rb` |
| spec/integration/git/repository/branching_spec.rb | 80 | Git state/output assertion (`#checkout`); single-command delegator covered by `checkout/branch_spec.rb` |
| spec/integration/git/repository/branching_spec.rb | 68 | Type-only assertion (`#checkout_file`); single-command delegator, no independent failure mode |
| spec/integration/git/repository/branching_spec.rb | 62 | Git state/output assertion (`#checkout_file`); single-command delegator covered by `checkout/files_spec.rb` |
| spec/integration/git/repository/committing_spec.rb | 85 | Single-command delegator (`#set_index`); spec header states only `#write_and_commit_tree` warrants facade integration tests |
| spec/integration/git/repository/committing_spec.rb | 70 | Single-command delegator (`#commit`); spec header states this is covered by `commit_spec.rb` |
| spec/integration/git/repository/committing_spec.rb | 63 | Command error path (`#commit`); spec header states this is covered by `commit_spec.rb` |
| spec/integration/git/repository/configuring_spec.rb | 165 | Single-command + parser (`#config_list`); `Git::Parsers::ConfigEntry` has a dedicated integration spec |
| spec/integration/git/repository/configuring_spec.rb | 158 | Single-command + parser (`#config_list`); `Git::Parsers::ConfigEntry` has a dedicated integration spec |
| spec/integration/git/repository/configuring_spec.rb | 150 | Single-command + parser (`#config_get`); `Git::Parsers::ConfigEntry` has a dedicated integration spec |
| spec/integration/git/repository/configuring_spec.rb | 143 | Single-command + parser (`#config_get`); `Git::Parsers::ConfigEntry` has a dedicated integration spec |
| spec/integration/git/repository/configuring_spec.rb | 124 | Single-command delegator (`#global_config` set mode); spec header states covered by command integration specs |
| spec/integration/git/repository/configuring_spec.rb | 118 | Single-command delegator (`#global_config` get mode); spec header states covered by command integration specs |
| spec/integration/git/repository/configuring_spec.rb | 86 | Git state/output assertion; tests git's `include.path` chaining behavior, not facade dispatch |
| spec/integration/git/repository/configuring_spec.rb | 76 | Single-command delegator (`#config` set + file: mode); spec header states covered by command integration specs |
| spec/integration/git/repository/configuring_spec.rb | 46 | Single-command delegator (`#config` get mode); spec header states covered by command integration specs |
| spec/integration/git/repository/diffing_spec.rb | 224 | Git state/output assertion; tests git's single-entry output for an unstaged rename, not facade post-processing |
| spec/integration/git/repository/diffing_spec.rb | 219 | Git state/output assertion; tests git's omission of untracked paths from diff-files output |
| spec/integration/git/repository/diffing_spec.rb | 213 | Git state/output assertion; tests git's representation of an unstaged rename as a delete, not facade post-processing |
| spec/integration/git/repository/logging_spec.rb | 84 | Git state/output assertion; tests git log's reverse-chronological ordering, not facade processing |
| spec/integration/git/repository/logging_spec.rb | 48 | Option variant (`path_limiter:`) for `#full_log_commits`; argument forwarding covered by unit spec |
| spec/integration/git/repository/logging_spec.rb | 41 | Option variant (`between:`) for `#full_log_commits`; argument forwarding covered by unit spec |
| spec/integration/git/repository/merging_spec.rb | 434 | Git state/output assertion (`#revert`); single-command delegator covered by `revert/start_spec.rb` |
| spec/integration/git/repository/merging_spec.rb | 427 | Git state/output assertion (`#revert`); single-command delegator covered by `revert/start_spec.rb` |
| spec/integration/git/repository/merging_spec.rb | 422 | Type-only assertion (`#revert`); single-command delegator, no independent failure mode |
| spec/integration/git/repository/merging_spec.rb | 330 | Type-only assertion (`#unmerged`); Rule 24 violation |
| spec/integration/git/repository/merging_spec.rb | 288 | Type-only assertion (`#merge_base` with `all:true`); Rule 24 violation |
| spec/integration/git/repository/merging_spec.rb | 231 | Type-only assertion (`#merge_base`); Rule 24 violation |
| spec/integration/git/repository/merging_spec.rb | 226 | Type-only assertion (`#merge_base`); Rule 24 violation |
| spec/integration/git/repository/merging_spec.rb | 194 | Git state/output assertion (`#merge` with `no_commit:`); single-command delegator covered by `merge/start_spec.rb` |
| spec/integration/git/repository/merging_spec.rb | 188 | Git state/output assertion (`#merge` with `no_commit:`); single-command delegator covered by `merge/start_spec.rb` |
| spec/integration/git/repository/merging_spec.rb | 156 | Git state/output assertion; tests git's behavior of ignoring `-m` on fast-forward merges |
| spec/integration/git/repository/merging_spec.rb | 151 | Git state/output assertion (`#merge` fast-forward); single-command delegator covered by `merge/start_spec.rb` |
| spec/integration/git/repository/merging_spec.rb | 146 | Type-only assertion (`#merge` fast-forward); no independent failure mode |
| spec/integration/git/repository/merging_spec.rb | 126 | Git state/output assertion (`#merge` with `no_ff:`); single-command delegator covered by `merge/start_spec.rb` |
| spec/integration/git/repository/merging_spec.rb | 120 | Git state/output assertion (`#merge` with `no_ff:` + message); tests git commit message behavior |
| spec/integration/git/repository/merging_spec.rb | 100 | Type-only assertion (`#merge` octopus); no independent failure mode |
| spec/integration/git/repository/merging_spec.rb | 94 | Git state/output assertion (`#merge` octopus); single-command delegator covered by `merge/start_spec.rb` |
| spec/integration/git/repository/merging_spec.rb | 66 | Git state/output assertion (`#merge` with `Git::Branch` coercion); single-command delegator covered by `merge/start_spec.rb` |
| spec/integration/git/repository/merging_spec.rb | 44 | Git state/output assertion (`#merge`); single-command delegator covered by `merge/start_spec.rb` |
| spec/integration/git/repository/merging_spec.rb | 39 | Git state/output assertion (`#merge`); single-command delegator covered by `merge/start_spec.rb` |
| spec/integration/git/repository/merging_spec.rb | 34 | Type-only assertion (`#merge`); no independent failure mode |
| spec/integration/git/repository/object_operations_spec.rb | 856 | Command error path (`#tag_delete`); covered by `tag/delete_spec.rb` |
| spec/integration/git/repository/object_operations_spec.rb | 850 | Git state/output assertion (`#tag_delete`); tests git's deletion confirmation message format |
| spec/integration/git/repository/object_operations_spec.rb | 845 | Git state/output assertion (`#tag_delete`); single-command delegator covered by `tag/delete_spec.rb` |
| spec/integration/git/repository/object_operations_spec.rb | 794 | Single-command + parser (`#tags`); `Git::Parsers::Tag` has a dedicated integration spec |
| spec/integration/git/repository/object_operations_spec.rb | 790 | Single-command + parser (`#tags`); `Git::Parsers::Tag` has a dedicated integration spec |
| spec/integration/git/repository/object_operations_spec.rb | 779 | Single-command + parser (`#tags`); `Git::Parsers::Tag` has a dedicated integration spec |
| spec/integration/git/repository/object_operations_spec.rb | 761 | Command error path (`#grep`); covered by `grep_spec.rb` |
| spec/integration/git/repository/object_operations_spec.rb | 754 | Pure-Ruby guard (`#grep` unknown option); no git involved, covered by unit spec |
| spec/integration/git/repository/object_operations_spec.rb | 739 | Option variant (`#grep` with `object:` option); same parser code path as retained tests |
| spec/integration/git/repository/object_operations_spec.rb | 732 | Option variant (`#grep` with `:extended_regexp`) |
| spec/integration/git/repository/object_operations_spec.rb | 724 | Option variant (`#grep` with `:invert_match`) |
| spec/integration/git/repository/object_operations_spec.rb | 717 | Git state/output assertion; tests git's case-sensitive matching, not parser behavior |
| spec/integration/git/repository/object_operations_spec.rb | 712 | Option variant (`#grep` with `:ignore_case`) |
| spec/integration/git/repository/object_operations_spec.rb | 705 | Option variant (`#grep` with Array `path_limiter`); same parser code path |
| spec/integration/git/repository/object_operations_spec.rb | 698 | Option variant (`#grep` with String `path_limiter`); same parser code path |
| spec/integration/git/repository/object_operations_spec.rb | 643 | Pure-Ruby guard (`#archive` directory destination); no git involved, covered by unit spec |
| spec/integration/git/repository/object_operations_spec.rb | 586 | Pure-Ruby guard (`#archive` unknown option); no git involved, covered by unit spec |
| spec/integration/git/repository/object_operations_spec.rb | 571 | Option variant (`#archive` with `prefix:`) |
| spec/integration/git/repository/object_operations_spec.rb | 555 | Option variant (`#archive` tar format); same code path as retained zip test |
| spec/integration/git/repository/object_operations_spec.rb | 515 | Command error path (`#ls_tree`); covered by `ls_tree_spec.rb` |
| spec/integration/git/repository/object_operations_spec.rb | 509 | Pure-Ruby guard (`#ls_tree` unknown option); no git involved, covered by unit spec |
| spec/integration/git/repository/object_operations_spec.rb | 501 | Option variant (`#ls_tree` with `path:` option) |
| spec/integration/git/repository/object_operations_spec.rb | 449 | Pure-Ruby guard (`#name_rev`); no git involved, covered by unit spec |
| spec/integration/git/repository/object_operations_spec.rb | 441 | Type-only assertion (`#name_rev`); Rule 24 violation |
| spec/integration/git/repository/object_operations_spec.rb | 427 | Type-only assertion (`#name_rev`); Rule 24 violation |
| spec/integration/git/repository/object_operations_spec.rb | 418 | Command error path (`#tree_depth`); covered by `ls_tree_spec.rb` |
| spec/integration/git/repository/object_operations_spec.rb | 411 | Duplicate invocation (`#tree_depth`); same counting code path as the retained test at line 403 |
| spec/integration/git/repository/object_operations_spec.rb | 388 | Command error path (`#full_tree`); covered by `ls_tree_spec.rb` |
| spec/integration/git/repository/object_operations_spec.rb | 380 | Option variant (`#full_tree` with treeish specifier); same splitting code path |
| spec/integration/git/repository/object_operations_spec.rb | 372 | Git state/output assertion; tests git's `ls-tree` line format, not the facade's split |
| spec/integration/git/repository/object_operations_spec.rb | 359 | Type-only assertion (`#full_tree`); Rule 24 violation |
| spec/integration/git/repository/object_operations_spec.rb | 343 | Duplicate invocation (`#tag_sha`); consistency check has no independent failure mode |
| spec/integration/git/repository/object_operations_spec.rb | 325 | Command error path (`#rev_parse`); covered by `rev_parse_spec.rb` |
| spec/integration/git/repository/object_operations_spec.rb | 318 | Git state/output assertion (`#rev_parse`); single-command delegator, tests git tree-SHA resolution |
| spec/integration/git/repository/object_operations_spec.rb | 310 | Git state/output assertion (`#rev_parse`); single-command delegator, tests git SHA expansion |
| spec/integration/git/repository/object_operations_spec.rb | 304 | Type-only assertion (`#rev_parse`); Rule 24 violation |
| spec/integration/git/repository/object_operations_spec.rb | 299 | Git state/output assertion (`#rev_parse`); tests git's SHA output format, not the facade |
| spec/integration/git/repository/object_operations_spec.rb | 275 | Command error path (`#cat_file_tag`); covered by `cat_file/raw_spec.rb` |
| spec/integration/git/repository/object_operations_spec.rb | 268 | Pure-Ruby guard (`#cat_file_tag`); no git involved, covered by unit spec |
| spec/integration/git/repository/object_operations_spec.rb | 254 | Duplicate invocation (`#cat_file_tag`); subset of the key-check at line 246 |
| spec/integration/git/repository/object_operations_spec.rb | 250 | Duplicate invocation (`#cat_file_tag`); subset of the key-check at line 246 |
| spec/integration/git/repository/object_operations_spec.rb | 238 | Type-only assertion (`#cat_file_tag`); Rule 24 violation |
| spec/integration/git/repository/object_operations_spec.rb | 195 | Duplicate invocation (`#cat_file_commit`); same structure covered by line 153 in the same context |
| spec/integration/git/repository/object_operations_spec.rb | 179 | Command error path (`#cat_file_commit`); covered by `cat_file/raw_spec.rb` |
| spec/integration/git/repository/object_operations_spec.rb | 161 | Duplicate invocation (`#cat_file_commit`); message-format detail is a subset of line 153 |
| spec/integration/git/repository/object_operations_spec.rb | 157 | Duplicate invocation (`#cat_file_commit`); parent-type detail is a subset of line 153 |
| spec/integration/git/repository/object_operations_spec.rb | 145 | Type-only assertion (`#cat_file_commit`); Rule 24 violation |
| spec/integration/git/repository/object_operations_spec.rb | 134 | Command error path (`#cat_file_type`); covered by `cat_file/raw_spec.rb` |
| spec/integration/git/repository/object_operations_spec.rb | 127 | Pure-Ruby guard (`#cat_file_type`); no git involved, covered by unit spec |
| spec/integration/git/repository/object_operations_spec.rb | 121 | Duplicate invocation (`#cat_file_type`); same code path as line 108, different object type |
| spec/integration/git/repository/object_operations_spec.rb | 114 | Duplicate invocation (`#cat_file_type`); same code path as line 108, different object type |
| spec/integration/git/repository/object_operations_spec.rb | 99 | Command error path (`#cat_file_size`); covered by `cat_file/raw_spec.rb` |
| spec/integration/git/repository/object_operations_spec.rb | 92 | Pure-Ruby guard (`#cat_file_size`); no git involved, covered by unit spec |
| spec/integration/git/repository/object_operations_spec.rb | 83 | Duplicate invocation (`#cat_file_size`); same `.to_i` code path as line 76, different object type |
| spec/integration/git/repository/object_operations_spec.rb | 68 | Duplicate invocation (`#cat_file_size`); same `.to_i` code path as line 76, different object type |
| spec/integration/git/repository/object_operations_spec.rb | 59 | Command error path (`#cat_file_contents`); covered by `cat_file/raw_spec.rb` |
| spec/integration/git/repository/object_operations_spec.rb | 52 | Pure-Ruby guard (`#cat_file_contents`); no git involved, covered by unit spec |
| spec/integration/git/repository/object_operations_spec.rb | 28 | Single-command delegator (`#cat_file_contents` non-block, commit object); covered by `cat_file/raw_spec.rb` |
| spec/integration/git/repository/object_operations_spec.rb | 20 | Single-command delegator (`#cat_file_contents` non-block, blob object); covered by `cat_file/raw_spec.rb` |
| spec/integration/git/repository/remote_operations_spec.rb | 382 | Rule 24 violation (`#ls_remote` with `tags:`); `not_to raise_error` asserts nothing observable |
| spec/integration/git/repository/remote_operations_spec.rb | 365 | Type-only assertion (`#ls_remote`); Rule 24 violation |
| spec/integration/git/repository/remote_operations_spec.rb | 343 | Type-only assertion (`#remote_set_branches`); `nil` return adds no signal |
| spec/integration/git/repository/remote_operations_spec.rb | 331 | Type-only assertion (`#remote_set_url`); result-factory check redundant with the side-effect test at line 326 |
| spec/integration/git/repository/remote_operations_spec.rb | 296 | Type-only assertion (`#remotes`); Rule 24 violation — adjacent tests exercise the result |
| spec/integration/git/repository/remote_operations_spec.rb | 285 | Result factory; tests `Git::Remote#url` attribute, no facade-owned processing |
| spec/integration/git/repository/remote_operations_spec.rb | 279 | Result factory (`#remote` default-argument form); no facade-owned processing |
| spec/integration/git/repository/remote_operations_spec.rb | 273 | Result factory (`#remote`); no facade-owned processing, covered by unit spec |
| spec/integration/git/repository/remote_operations_spec.rb | 249 | Type-only assertion (`#config_remote`); Rule 24 violation |
| spec/integration/git/repository/remote_operations_spec.rb | 238 | Command error path (`#remote_remove`); covered by `remote/remove_spec.rb` |
| spec/integration/git/repository/remote_operations_spec.rb | 233 | Type-only assertion (`#remote_remove`); Rule 24 violation |
| spec/integration/git/repository/remote_operations_spec.rb | 216 | Pure-Ruby guard (`#remote_add` unknown option); no git involved, covered by unit spec |
| spec/integration/git/repository/remote_operations_spec.rb | 210 | Rule 24 violation (`#remote_add` deprecated `:with_fetch` alias); `not_to raise_error` asserts nothing |
| spec/integration/git/repository/remote_operations_spec.rb | 204 | Rule 24 violation (`#remote_add` with `track:`); `not_to raise_error` asserts nothing |
| spec/integration/git/repository/remote_operations_spec.rb | 198 | Rule 24 violation (`#remote_add` with `fetch:`); `not_to raise_error` asserts nothing |
| spec/integration/git/repository/remote_operations_spec.rb | 186 | Type-only assertion (`#remote_add`); Rule 24 violation — line 192 already verifies the side effect |
| spec/integration/git/repository/remote_operations_spec.rb | 165 | Pure-Ruby guard (`#pull` unknown option); no git involved, covered by unit spec |
| spec/integration/git/repository/remote_operations_spec.rb | 160 | Command error path (`#pull`); covered by `pull_spec.rb` |
| spec/integration/git/repository/remote_operations_spec.rb | 155 | Pure-Ruby guard (`#pull` branch without remote); no git involved, covered by unit spec |
| spec/integration/git/repository/remote_operations_spec.rb | 150 | Single-command delegator (`#pull`); type check covered by `pull_spec.rb` |
| spec/integration/git/repository/remote_operations_spec.rb | 138 | Command error path (`#push` tracking-branch workflow); covered by `push_spec.rb` |
| spec/integration/git/repository/remote_operations_spec.rb | 123 | Single-command delegator (`#push` tracking-branch workflow); type check covered by `push_spec.rb` |
| spec/integration/git/repository/remote_operations_spec.rb | 97 | Type-only assertion (`#push` with `tags:`); no meaningful assertion |
| spec/integration/git/repository/remote_operations_spec.rb | 86 | Pure-Ruby guard (`#push` unknown option); no git involved, covered by unit spec |
| spec/integration/git/repository/remote_operations_spec.rb | 79 | Pure-Ruby guard (`#push` branch without remote); no git involved, covered by unit spec |
| spec/integration/git/repository/remote_operations_spec.rb | 73 | Command error path (`#push`); covered by `push_spec.rb` |
| spec/integration/git/repository/remote_operations_spec.rb | 68 | Single-command delegator (`#push`); type check covered by `push_spec.rb` |
| spec/integration/git/repository/remote_operations_spec.rb | 56 | Pure-Ruby guard (`#fetch` unknown option); no git involved, covered by unit spec |
| spec/integration/git/repository/remote_operations_spec.rb | 43 | Command error path (`#fetch`); covered by `fetch_spec.rb` |
| spec/integration/git/repository/remote_operations_spec.rb | 38 | Single-command delegator (`#fetch` default remote); type check covered by `fetch_spec.rb` |
| spec/integration/git/repository/remote_operations_spec.rb | 33 | Single-command delegator (`#fetch`); type check covered by `fetch_spec.rb` |
| spec/integration/git/repository/staging_spec.rb | 183 | Single-command delegator (`#rm`); spec header states this is covered by `rm_spec.rb` |
| spec/integration/git/repository/staging_spec.rb | 169 | Pure-Ruby argument handling (`#read_tree` positional hash compatibility); covered by unit spec |
| spec/integration/git/repository/staging_spec.rb | 162 | Pure-Ruby guard (`#read_tree` unknown option); no git involved, covered by unit spec |
| spec/integration/git/repository/staging_spec.rb | 156 | Rule 24 violation (`#read_tree` with `prefix:`); `not_to raise_error` asserts nothing observable |
| spec/integration/git/repository/staging_spec.rb | 151 | Type-only assertion (`#read_tree`); Rule 24 violation |
| spec/integration/git/repository/staging_spec.rb | 147 | Rule 24 violation (`#read_tree` base call); `not_to raise_error` asserts nothing observable |
| spec/integration/git/repository/staging_spec.rb | 123 | Type-only assertion (`#apply_mail` success case); redundant with line 118 which already exercises the code path |
| spec/integration/git/repository/staging_spec.rb | 83 | Type-only assertion (`#apply` success case); redundant with line 78 which already exercises the code path |
| spec/integration/git/repository/stashing_spec.rb | 147 | Single-command delegator (`#stash_apply`); covered by `stash/apply_spec.rb` |
| spec/integration/git/repository/stashing_spec.rb | 132 | Command error path (`#stash_save`); covered by `stash/push_spec.rb` |
| spec/integration/git/repository/stashing_spec.rb | 103 | Type-only assertion (`#stash_list`); deprecated method, type check has no independent failure mode |
| spec/integration/git/repository/stashing_spec.rb | 98 | Mock assertion in integration test (`#stash_list` deprecation warning); belongs in unit spec |
| spec/integration/git/repository/stashing_spec.rb | 30 | Type-only assertion (`#stashes_all`); the index-0 assignment is trivially true and is covered by the multi-stash ordering test |
| spec/integration/git/repository/status_operations_spec.rb | 179 | Git state/output assertion; tests git's `gitignore` filtering behavior, not the facade's `exclude_standard:` option |
| spec/integration/git/repository/status_operations_spec.rb | 94 | Duplicate invocation (`#status`); same `be_a(Git::Status)` assertion as line 82, no independent failure mode |

## Controversial removals

These tests are included in the deletion list above but could be argued either way.
A reasonable engineer reviewing this list might push back on deleting them.

| File | Line | Counter-argument for keeping |
| ---- | ---- | ---------------------------- |
| spec/integration/git/repository/branching_spec.rb | 473 | `#branches_all` spec comment explicitly states the tests "verify the end-to-end Ruby return value against real git output." The `Git::Parsers::Branch` integration spec tests the parser in isolation; these tests validate the facade's `Array<Git::BranchInfo>` pipeline — a layer not tested elsewhere at the integration level. The same rationale was used to retain `#cat_file_commit` and `#ls_tree` tests in object_operations_spec.rb. |
| spec/integration/git/repository/branching_spec.rb | 460 | Same as L473. |
| spec/integration/git/repository/branching_spec.rb | 453 | Same as L473. |
| spec/integration/git/repository/branching_spec.rb | 435 | Same as L473. |
| spec/integration/git/repository/branching_spec.rb | 429 | Same as L473. |
| spec/integration/git/repository/branching_spec.rb | 423 | Same as L473. |
| spec/integration/git/repository/branching_spec.rb | 370 | The spec comment covers both the unborn and post-commit cases as a stated rationale. Keeping L363 (unborn) while deleting L370 (post-commit) is inconsistent with the spec author's documented intent, and the standard doesn't clearly distinguish between the two scenarios. |
| spec/integration/git/repository/configuring_spec.rb | 124 | `#global_config` operates on a different configuration scope (`GIT_CONFIG_GLOBAL`) than local config. The `with_isolated_global_config` helper performs real env-var isolation that could silently break across Ruby or git upgrades; a round-trip test provides coverage of the mechanism itself. |
| spec/integration/git/repository/configuring_spec.rb | 118 | Same as L124. |
| spec/integration/git/repository/diffing_spec.rb | 224 | No `Parsers::DiffFiles` integration spec exists. These three tests document a non-obvious behavioral boundary: an unstaged rename shows as a delete entry, not a rename entry. The same reasoning used to retain `#ls_tree` integration tests (no dedicated parser spec) applies here. |
| spec/integration/git/repository/diffing_spec.rb | 219 | Same as L224. |
| spec/integration/git/repository/diffing_spec.rb | 213 | Same as L224. |
| spec/integration/git/repository/merging_spec.rb | 156 | Documents a non-obvious caller contract: a message passed to `#merge` during a fast-forward merge is silently ignored by git. Removing this test leaves no integration-level documentation of that behavior, which is a common source of user confusion. |
| spec/integration/git/repository/merging_spec.rb | 66 | The facade's `merge` method does `Array(branch).map(&:to_s)` — explicit `Git::Branch`-to-string coercion that is facade-owned preprocessing. If that coercion were removed, this would be the only test to catch it immediately; the other merge tests all pass a String directly. |
| spec/integration/git/repository/object_operations_spec.rb | 739 | No `Parsers::Grep` integration spec exists. This and the six entries below verify that different option combinations produce different parsed result structures against real git output — coverage that is absent from both the unit spec (which stubs the parser) and the command integration spec (which returns raw `CommandLineResult`). |
| spec/integration/git/repository/object_operations_spec.rb | 732 | Same as L739. |
| spec/integration/git/repository/object_operations_spec.rb | 724 | Same as L739. |
| spec/integration/git/repository/object_operations_spec.rb | 717 | Same as L739. |
| spec/integration/git/repository/object_operations_spec.rb | 712 | Same as L739. |
| spec/integration/git/repository/object_operations_spec.rb | 705 | Same as L739. |
| spec/integration/git/repository/object_operations_spec.rb | 698 | Same as L739. |
| spec/integration/git/repository/stashing_spec.rb | 98 | The deprecation warning is facade behavior: if `Git::Deprecation.warn` stopped being called, no other test would catch it. A mock assertion in an integration spec is unusual, but this is the only coverage that verifies the deprecation mechanism actually fires. |
