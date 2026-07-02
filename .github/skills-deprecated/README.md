# Deprecated skills

This directory holds skills that have been **retired** from active use. They are
kept on disk for historical reference only — they are intentionally located outside
`.github/skills/` so they are not auto-discovered or loaded into agent context.

## Retired skills

- **`extract-command-from-lib/`** — guided migrating a `Git::Lib` `#command` call
  into a `Git::Commands::*` class during the v5.0.0 architectural redesign.
- **`extract-facade-from-base-lib/`** — guided migrating a public method from
  `Git::Base` / `Git::Lib` into a `Git::Repository::*` facade method during the same
  redesign.
- **`review-backward-compatibility/`** — audited `Git::Lib` methods for backward
  compatibility during the migration to `Git::Commands::*`. `Git::Lib` was deleted in
  PR #1456 as part of Phase 4 Step A; this workflow no longer applies.

The extract-* skills describe migration work that is now complete: `Git::Base` and
`Git::Lib` have been removed from the codebase, so there is nothing left to extract.
All three skills remain here as a record of the workflow used during the migration,
in case similar work is needed again in the future.
