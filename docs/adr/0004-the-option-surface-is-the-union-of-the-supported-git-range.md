# The option surface is the union of the supported git range

A command class exposes every option that does something on at least one git version in
the supported range, from `Git::MINIMUM_GIT_VERSION` to the latest release. Options
introduced after the floor are included, and options git has retired stay until the
floor reaches the point of retirement.

Three narrower surfaces were rejected.

Tracking only the latest docs drops options that still work at the floor, abandoning
callers pinned to an older git inside the range the gem claims to support. Tracking
only the floor withholds new git features from every caller running a current git. And
gating individual options with Ruby-side version checks duplicates git's own knowledge
of its options, which goes stale exactly the way constraints do (ADR-0003). Version
gating stops at command granularity: `requires_git_version` marks a whole class whose
command does not exist at the floor, and below that, git speaks for itself.

Delegation is what makes the union rule cheap. At both edges git handles the mismatch:
a git older than an option rejects it as an unknown option, and a git newer than a
retired option rejects it or accepts it as a no-op. No Ruby-side version table exists
to maintain or to trust.

Removal is triggered by the floor, not by git's latest. An option stays while any
supported git honors it, because a caller pinned to an older git inside the range is
exactly who the range promise serves. When a major release raises
`Git::MINIMUM_GIT_VERSION` to or past the version where git retired an option, the
option is dead across the whole range and enters the normal deprecation cadence. A floor raise
therefore carries an audit: list the options the new floor kills, deprecate them in
that major, remove them in the next.

The case that prompted the rule: git 2.50 retired `--allow-unknown-type`, leaving the
`allow_unknown_type:` option of `Git::Commands::CatFile::Raw` meaningful only below
2.50. It stays because the floor is 2.28.0. Issue #1709 holds its deprecation trigger.

The scaffolding and audit mechanics live in
[Command Implementation - Options completeness](../../.github/skills/command-implementation/REFERENCE.md#options-completeness--consult-the-latest-version-docs-first).
