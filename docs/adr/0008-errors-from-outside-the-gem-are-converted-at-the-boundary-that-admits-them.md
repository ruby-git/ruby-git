# Errors from outside the gem are converted at the boundary that admits them

The README promises that the gem raises only `ArgumentError` or errors that subclass
`Git::Error`. The rule that keeps the promise: any error a standard library or gem call
can raise is converted at the boundary where it enters, to whichever of the two
contract classes fits. A caller mistake becomes `ArgumentError`. A failure at run time
becomes `Git::Error` or a subclass, with the underlying error as `cause`. The class the
library chose does not decide which one: `Time.iso8601` reports a malformed date as an
`ArgumentError`, but a malformed date in git's output is not a caller mistake, so the
parsers convert it to `Git::UnexpectedResultError`. The subprocess layer converts
process_executer's errors the same way, and `Git::SystemCallGuard` converts
`SystemCallError` from the gem's own filesystem calls (issues 1804 and 1806, PR 1805).
The guard covers only that family. A call that can raise something else, such as a
`Zlib::Error`, needs its own conversion. The guard is the case that forced the rule to
be written down.

The rule covers errors from operations the gem chose to perform. It does not cover a
defect in the gem, which raises whatever Ruby raises because wrapping a `NoMethodError`
would hide the defect. It does not cover an error raised inside a caller's block, which
the gem relays rather than raises, so `Git::SystemCallGuard#unguarded` marks the region
where a facade method such as `chdir` yields to the caller. And it does not cover
`Git::Deprecation.warn`, which raises `ActiveSupport::DeprecationException` under the
`raise` deprecation behavior: the caller asked for that, so the gem relays it too.

Within that scope there are no carve-outs. A site is not exempt because its failure is
unlikely, and a path is not exempt because the caller chose it. Issue 1804 reported two
`File.read` sites that let a bare `Errno` escape, and three cheaper fixes were rejected.
Wrapping only the two reported reads leaves every other filesystem call the gem makes
leaking the same way. Wrapping only the paths the gem chooses itself, such as temporary
files, draws a line the README sentence does not draw. Documenting the leak keeps the
code and changes the sentence. Each option turns "raises only" into "raises only,
except", and a caller who has to enumerate the exceptions gains nothing from rescuing
`Git::Error`.

Two classes are kept out of the `Git::Error` hierarchy on purpose, so that a broad
`rescue Git::Error` around a git operation cannot hide a programming error. That is
why `ArgumentError` is the contract's second class rather than a `Git::Error` subclass,
and why a deprecated call under the `raise` deprecation behavior raises
`ActiveSupport::DeprecationException` rather than a gem error.

## Consequences

The exception class follows the kind of failure, not the path and not the class the
library raised. Validating an argument raises `ArgumentError`, and a filesystem
operation that fails raises `Git::Error`, even when both stem from the same missing
directory. `with_working` does both in turn.

A site may recover instead of raise when it has a fallback. `tag_sha` reads the loose
ref file only to avoid forking git, and falls through to `git show-ref` when the read
fails.

A change of exception class has no deprecation path, because a `rescue` clause cannot
see a warning. It is backward compatible only when every rescue clause that caught the
old class still catches the new one. This change fails that test. A caller who rescued
`Errno::EACCES` around the affected methods, which `UPGRADING.md` lists, loses the
catch, and the new error cannot also be a `SystemCallError`. So the fix ships in
v6.0.0 only. Issue 1804 records the withdrawn backport, and issue 1809 the
documentation fix for the v4.x and v5.x series, whose README makes a promise the code
there does not keep. The test is policy in
[Branch & PR Strategy](../../.github/copilot-instructions.md#branch--pr-strategy).

The operational rules are normative policy in
[Project Context - Error Hierarchy](../../.github/skills/project-context/SKILL.md#error-hierarchy).
