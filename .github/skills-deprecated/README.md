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

Both describe migration work that is now complete: `Git::Base` and `Git::Lib` have
been removed from the codebase, so there is nothing left to extract. They remain
here as a record of the workflow used during the migration, in case similar
extraction work is needed again in the future.
