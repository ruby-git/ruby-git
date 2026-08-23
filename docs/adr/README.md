# Decision records (ADRs)

Each file here records one decision and the reason for it. A plan says what we intend to
do next, and goes stale the moment reality diverges from it. A decision stays true even
when the work it justified changes shape.

Where each kind of thing lives:

| Artifact | Holds | Home |
| --- | --- | --- |
| Issue | what and whether, current state | GitHub |
| ADR | why, decided once | `docs/adr/` |
| Skill | how, normative policy | `.github/skills/` |

Supersede an ADR, never edit it. When a decision is reversed, write a new ADR saying so
and add a `Superseded by ADR-NNNN` line to the old one. The record is worth keeping
because it says what was believed at the time.

## When to write one

All three must be true.

1. The decision is hard to reverse. If changing your mind later is cheap, skip the
   record. You will just change your mind.
2. A future reader would look at the code and wonder why it is like that. If the choice
   is the obvious one, nobody wonders.
3. There was a real alternative, rejected for a reason worth keeping. "We did the
   obvious thing" is not a decision.

Keeping the count low is the point. This directory works while a new maintainer can read
all of it in an afternoon. At a hundred entries nobody reads any of it, and the project
has swapped one pile of unread documents for another.

## What does not belong here

Three things look like ADRs and are not.

**Audit findings.** "We checked every method on `Git::Branch` and found no capability
gap" states a fact about the code at one point in time. It belongs on the issue that
prompted the audit.

**Design intent for work not started.** "The new value object will carry every field the
porcelain format reports" describes a plan. Plans go on the issue tracker, and this one
gets settled by the pull request that writes the parser.

**Reminders about what a future change must say.** "The deprecation warning has to
mention that the old method auto-created the branch" is a task. Put it on the issue that
does the deprecation, where someone can check it off.

## Adding one

Name the file `NNNN-slug.md`, where `NNNN` is one past the highest number here. Keep it
short. A paragraph is a legitimate ADR. Add a considered-options or consequences section
only when the rejected alternative or the downstream effect is worth remembering on its
own.

State the decision in the title rather than the topic. "No branch-scoped stash API" tells
the reader what was decided. "Stashes" does not.

Write the general rule when the general rule is the real reason and the concrete case
only illustrates it. Keep the record concrete when the decision turns on something
peculiar to that case. A procedure that generalizes belongs in a skill instead.
