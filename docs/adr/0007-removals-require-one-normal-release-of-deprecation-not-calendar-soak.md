# Removals require one normal release of deprecation, not calendar soak

This record supersedes
[ADR-0006](0006-removals-require-proven-safety-and-calendar-soak.md) and first applies
to v6.0.0.

A removal PR merges to main only when its deprecation warning and `UPGRADING.md` entry
are contained in a previous normal release. Once any removal has merged to main, main
becomes the release line for the next major version. If another release of the previous
major is needed, it is cut from a branch created for that major (e.g. `4.x` or `5.x`).
"Normal release" is semver's term for a non-pre-release version.

The gate sets the earliest major a removal may land in, not the one it must land in. A
removal may land in any major after the gate is met, and which one is a roadmap decision
recorded on the API's issue. The warning names that major once it is decided, for
example "will be removed in v6.0.0", and otherwise says "will be removed in a future
major release". The `UPGRADING.md` entry agrees with the warning. Deciding or changing
the named major later is a documentation change that ships in a minor.

A warning is added only when removal in a future major is intended. An API that will be
kept but discouraged is documented as legacy with no warning, as ADR-0002 did for the
hollow shells. Removing a warning, which un-deprecates the API, is a non-breaking change.

This record rejects ADR-0006's six-month calendar soak because the supported upgrade
procedure is deliberate rather than incidental. A user upgrades to the latest minor of
the current major, sets `GIT_DEPRECATION_BEHAVIOR=raise`, clears every warning, then
upgrades to the next major. The latest minor carries every warning, so the time between
a deprecating minor and the major does not matter. ADR-0006 assumed users discover
warnings by chance during routine minor bumps. Its "before the final minor of the
series" condition is also only knowable in retrospect and could force an empty release.

The Safety Proof is no longer a removal condition. The deprecation period is the safety
mechanism. The "prove it by running real code" discipline in the breaking-change-analysis
skill stays for hard breaks and behavior changes that have no deprecation path.
Reverse-dependency evidence is still useful, for example for outreach to dependents, but
is not part of the gate. The evidence recorded on issue 1718 stands. The accepted risk is
that a capability gap in a replacement API, found after the major ships, has no fallback
and becomes a feature request.

One consequence carries over from ADR-0006. Warnings only reach adopters of the
deprecating series. Users who jump from an older major straight to the new one never see
them, and `UPGRADING.md` is the instrument for them.

ADR-0004 is unchanged. The options its floor-raise audit finds are deprecated under this
policy, and the issue 1718 evidence it cites stands.
