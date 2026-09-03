---
name: roadmap-tickets
description: "Publishes a plan, spec, or decision set as GitHub issues with native blocking edges, sub-issue umbrellas, and milestones, keeping existing issues reconciled. Use when turning a plan or conversation into tracker tickets, building or extending a release roadmap, adding blocking edges or an umbrella issue, or querying the frontier of workable issues."
---

# Roadmap Tickets

Publish a plan as tracker tickets and keep the roadmap structure — umbrella,
edges, milestones, and the issue bodies the plan touches — consistent on the
tracker. Ported from the mattpocock `to-tickets` convention after the v6.0.0
roadmap trial (issue 1717); this file is the repository's own record of how
plans become tickets here.

## Contents

- [Contents](#contents)
- [How to use this skill](#how-to-use-this-skill)
- [Related skills](#related-skills)
- [Where the mechanics live](#where-the-mechanics-live)
- [Conventions](#conventions)
  - [Tickets](#tickets)
  - [Umbrella issues](#umbrella-issues)
  - [Reconciliation](#reconciliation)
- [Workflow](#workflow)
- [Ticket template](#ticket-template)

## How to use this skill

Attach this file to your context and invoke it with the plan, spec, or
conversation to publish. The tracker work is done with the `gh` CLI; the
maintainer approves the breakdown before anything is published.

## Related skills

- [Development Workflow](../development-workflow/SKILL.md) — implements a
  published ticket (triage through PR)
- [Breaking Change Analysis](../breaking-change-analysis/SKILL.md) — the
  [deprecation policy](../breaking-change-analysis/SKILL.md#step-4-deprecation-policy)
  that removal tickets follow, recorded in
  [ADR-0007](../../../docs/adr/0007-removals-require-one-normal-release-of-deprecation-not-calendar-soak.md)
- [Project Context](../project-context/SKILL.md) — domain vocabulary for ticket
  titles and bodies

## Where the mechanics live

The `gh` command conventions and the native-relationship API calls (sub-issues,
blocked-by edges with database ids, the frontier query) are recorded once, in
[`docs/agents/issue-tracker.md` — "Wayfinding operations"](../../../docs/agents/issue-tracker.md#wayfinding-operations),
which is the authority. This skill states the process;
consult that file for the exact commands rather than reconstructing them.

## Conventions

### Tickets

- A ticket is a vertical slice: complete and verifiable on its own, sized to fit
  one fresh agent session. Each declares its blocking edges; a ticket with no
  blockers is immediately workable.
- Blocking edges are GitHub's native issue dependencies. The ticket body's
  "Blocked by" section documents the same edges for readers, but only the
  native edge gates — prose alone cannot render the frontier. A ticket is
  unblocked when every blocker is closed; `is:open -is:blocked` in the issues
  search renders the workable set.
- Publish in dependency order (blockers first) so every "Blocked by" section
  references real issue numbers.
- Apply no triage labels — this repository has not adopted a triage label
  vocabulary.
- The maintainer reviews every ticket before it posts; per
  [`AI_POLICY.md`](../../../AI_POLICY.md), no AI-disclosure line is added.

### Umbrella issues

- An umbrella is an index, not a store: it gists each decision in one or two
  lines and links to the sub-issue that holds the detail. Detail lives in
  exactly one place.
- Every roadmap item is a sub-issue of the umbrella (GitHub renders the
  progress bar from this). A release umbrella stays **gates-only**: work that
  does not gate the release is linked from prose, not added as a sub-issue.
- Record decisions with their date. Durable decisions with a rejected
  alternative go to `docs/adr/` per its README; the umbrella links the ADR
  rather than restating it.

### Reconciliation

- Before drafting, list the open issues in the plan's area: reference existing
  issues instead of recreating them, and give them milestones and edges rather
  than duplicate tickets.
- When the plan contradicts an existing issue body (a timeline, a scope, a
  version number), update that body in the same publication — a dated note at
  the top stating the re-mapping — so no issue contradicts the roadmap. Stale
  bodies that outlive their plans are the failure mode this whole convention
  exists to prevent.
- Milestone assignments are part of publication, not an afterthought; create or
  retire milestones as the roadmap requires.

## Workflow

1. **Gather** the plan from the conversation or the referenced document/issue,
   and read the ADRs covering the area.
2. **Reconcile first**: list existing issues in the area; decide per item
   whether it is referenced, re-milestoned, body-updated, or genuinely new.
3. **Draft** the tickets with the template below, each with its blocking edges.
4. **Quiz the maintainer**: present the breakdown (title, blocked-by, what it
   delivers per ticket) and iterate until approved. Nothing posts before
   approval.
5. **Publish** in dependency order; then wire sub-issues, edges, and milestones
   per the issue-tracker doc.
6. **Verify**: the frontier query returns exactly the tickets that should be
   workable, and nothing meant to be gated appears in it. The publication is
   complete when the verification matches the approved breakdown and every
   contradicted issue body has its re-map note.

## Ticket template

```markdown
## Parent

Part of <the umbrella/roadmap issue>. (Omit when there is no parent.)

## What to build

The end-to-end behavior this ticket makes work, from the caller's perspective —
not a layer-by-layer implementation list. Name classes and methods, not file
paths, which go stale.

## Acceptance criteria

- [ ] Checkable criterion
- [ ] ...

## Blocked by

- The blocking issues — each is also wired as a native blocked-by edge at
  publication — or "None — can start immediately".
```
