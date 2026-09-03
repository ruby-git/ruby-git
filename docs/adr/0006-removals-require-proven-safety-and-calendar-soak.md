# Removals require proven safety and calendar soak

Superseded by [ADR-0007](0007-removals-require-one-normal-release-of-deprecation-not-calendar-soak.md)

A major release deletes a deprecated API only when two conditions both hold. First, a
Safety Proof per the breaking-change-analysis skill: the single fact the removal is
safe because of, proven by running real code — reverse-dependency evidence, not
reasoning. Second, soak, scaled by what the proof finds: when the proof shows external
usage, the deprecation must have shipped in a released minor at least six months
before the major that removes it; when it shows none, in at least one released minor
before the final minor of the series. An API that fails either condition ships in the
major still deprecated and is removed in the following major. The first application is
v6.0.0, gating the removals deprecated by issues 1637, 1639, 1640, 1643, and 1709.

The rejected alternative was measuring soak in releases rather than calendar time,
and it fails on this project's own numbers: seven releases shipped in the three weeks
around v5.0.0, so "deprecated for two minors" could mean nine days. A warning only
does its job for a caller who upgrades into it, exercises the code path, and acts
before the removal ships, and callers move on their own dependency-update rhythm —
typically weeks to months — not on this gem's release cadence. Calendar time is the
honest proxy for warning reach; release count is not.

Two consequences are worth recording. The soak clock, not the implementation work,
sets the earliest date of a removing major: deprecations must ship early in the
preceding series, and a major wanted sooner simply carries more APIs forward as
deprecated. And soak only protects adopters of the deprecating series — users who
jump from an older major straight to the new one never see the warnings, which no
soak length can fix; UPGRADING.md is the instrument for them.
