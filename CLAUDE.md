# CLAUDE.md

This file exists so Claude Code picks up the same project instructions as every
other AI coding agent used in this repository.

**Do not add project guidance here.** The canonical instructions live in
[`.github/copilot-instructions.md`](.github/copilot-instructions.md) and are
imported below. Edit that file so all agents stay in sync. Reserve this file for
guidance that applies *only* to Claude Code.

@.github/copilot-instructions.md

## Agent skills

Configuration for the mattpocock engineering skills (`/to-tickets`, `/to-spec`,
`/wayfinder`), which run only in Claude Code. Guidance that applies to all agents
stays in `.github/copilot-instructions.md`.

### Issue tracker

Work is tracked in this repo's GitHub Issues via the `gh` CLI. See
`docs/agents/issue-tracker.md`.

### Domain docs

Single-context: the Project Context skill serves as the domain reference and ADRs
live in `docs/adr/` (no root `CONTEXT.md`). See `docs/agents/domain.md`.
