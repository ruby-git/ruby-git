# Domain Docs

How the engineering skills should consume this repo's domain documentation when exploring the codebase.

## Before exploring, read these

- **The Project Context skill** (`.github/skills/project-context/SKILL.md`) — this
  repo's domain reference: architecture, design philosophy, layered
  command/parser/facade structure, and compatibility requirements. This repo uses
  it in place of a root `CONTEXT.md`; do not create a `CONTEXT.md`.
- **`docs/adr/`** — read the ADRs that touch the area you're about to work in.
  `docs/adr/README.md` states when a decision earns an ADR and what belongs on the
  issue tracker instead.

## Use the project's vocabulary

When your output names a domain concept (in an issue title, a refactor proposal, a
hypothesis, a test name), use the term as the Project Context skill defines it —
command class, parser, facade, topic module, Info object. Don't drift to synonyms.

If the concept you need isn't defined there, that's a signal — either you're
inventing language the project doesn't use (reconsider) or there's a real gap
(note it so the skill can be extended).

## Flag ADR conflicts

If your output contradicts an existing ADR, surface it explicitly rather than silently overriding:

> _Contradicts ADR-0003 (validation is delegated to git) — but worth reopening because…_
