# Validation of git semantics is delegated to git

Command classes translate the caller's arguments into argv and run git. They do not
check whether a combination of git-visible arguments makes sense together. Git answers
that, and its rejections surface as `Git::FailedError` carrying git's own message.

The rejected alternative was Ruby-side constraint declarations raising `ArgumentError`
before git runs. The arguments DSL supports them (`conflicts`, `requires_one_of`, and
the rest), and the earlier, clearer error is a real benefit. It loses to three costs.

Duplicated rules go stale. Git's semantics move under a constraint that snapshots them.
The case that proved it: `Git::Commands::CatFile::Raw` constrained `--allow-unknown-type`
to the `-t` and `-s` modes, duplicating a check git 2.28-2.49 performs itself
(`cat-file` dies with "use with -s or -t" in any other mode). Git 2.50 then retired the
unknown-type feature, dropped its own check, and kept the flag as an accepted no-op in
every mode, so the constraint was enforcing a distinction git had erased. PR #1708
removed it.

Partial coverage is a false promise. Git has more option interactions than any wrapper
will encode, so a gem that validates some of them teaches callers that the absence of
an `ArgumentError` means a combination is valid.

A constraint violation is a programming error either way. The developer has to fix the
call whichever exception reports it, so the earlier error buys little.

Two narrow exceptions exist, both for errors git cannot report. Arguments with no argv
representation (`skip_cli: true` operands, `execution_option` entries) leave git no
token to object to, so Ruby must enforce their interactions. And a combination git
accepts while silently discarding data or producing a wrong answer may be constrained,
with proof. A flag git accepts and silently ignores is neither exception: that leniency
is deliberate, git can retire a flag by turning it into a no-op, and guarding ignored
flags walks straight back into the staleness cost above.

The operational rules, the argv-presence test, and the burden of proof for the second
exception are normative policy in
[Project Context - Validation Boundaries](../../.github/skills/project-context/SKILL.md#validation-boundaries).
