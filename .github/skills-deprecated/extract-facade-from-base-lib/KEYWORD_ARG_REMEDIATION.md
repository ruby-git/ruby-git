# Keyword-arg remediation list

The following facade methods are known to use `**opts`/`**` keyword-splat where
the legacy `Git::Base` or `Git::Lib` predecessor used a positional options hash
(`opts = {}`). Each is a candidate `legacy-contract` violation that must be
resolved before `Git.open`/`.clone`/`.init`/`.bare` are changed to return
`Git::Repository`: either fix the signature or
record an explicit `5.x-native` justification.

| Facade method | Current signature | Expected classification | Action needed |
| --- | --- | --- | --- |
| `Git::Repository::Staging#add` | `add(paths = '.', **)` | `legacy-contract` | Verify against 4.x `Git::Lib#add`; change to `opts = {}` if legacy |
| `Git::Repository::Staging#reset` | `reset(commitish = nil, **)` | `legacy-contract` | Verify against 4.x `Git::Lib#reset`; change to `opts = {}` if legacy |
| `Git::Repository::Committing#commit` | `commit(message = nil, **opts)` | `legacy-contract` | Verify against 4.x `Git::Base#commit`; change to `opts = {}` if legacy |
| `Git::Repository::Committing#commit_all` | `commit_all(*, **)` | `legacy-contract` | Verify against 4.x `Git::Base#commit_all`; change to `opts = {}` if legacy |
| `Git::Repository::Committing#commit_tree` | `commit_tree(tree, **opts)` | needs classification | Classify; if 5.x-native confirm; if legacy-contract fix signature |
| `Git::Repository::Committing#write_and_commit_tree` | `write_and_commit_tree(**)` | needs classification | Classify; if 5.x-native confirm; if legacy-contract fix signature |
| `Git::Repository::Branching#branch_delete` | `branch_delete(*branches, **options)` | needs classification | Verify against 4.x `Git::Base#branch_delete`; classify and fix or confirm |
| `Git::Repository::Inspecting#fsck` | `fsck(*objects, **)` | needs classification | Verify against 4.x `Git::Lib#fsck`; classify and fix or confirm |

This list is seeded from a static scan of `lib/git/repository/**/*.rb` and may be
incomplete. A full public-method inventory is required before closing the sweep.
