# GitHub Copilot Instructions for ruby-git

## Project Overview

A Ruby gem providing an interface to Git repositories by wrapping system calls to the
`git` CLI.

Read the "Project Context" skill (`.github/skills/project-context/SKILL.md`) for
design philosophy, technical details, and compatibility requirements.

Durable decisions (design, policy, process) are recorded as ADRs in `docs/adr/`.
Read the ADRs covering an area before changing it, and flag any contradiction
between a change and an ADR rather than silently overriding the decision.

This project enforces Conventional Commits. See `.commitlintrc.yml` for allowed types
and scopes. Never use `#` in the commit message body. Doing so will cause
commitlint to incorrectly parse the commit message body as a footer. If you need to
refer to an issue in the body, use `issue 999` instead of `issue #999`. It is still
fine to use `#` in footer values such as `Closes: #999` or `Refs: #999`.

## Terminology & Writing Style

- Use American English.
- **Version strings:** Use `vN.x` for major series compatibility (e.g., `v4.x`) and
  `vN.0.0` for specific releases (e.g., `v5.0.0`). Never use the ambiguous `vN.0`.
- **RuboCop:** Use `RuboCop` for prose and `rubocop` for CLI or gem names. Never use
  `Rubocop`.

## Branch & PR Strategy

| Target | When |
| --- | --- |
| `main` | New features, breaking changes, all active development. Its next release is v6.0.0; every further v5.x release is cut from `5.x` |
| `5.x` | Security fixes, backward-compatible bug fixes, and backward-compatible features at the maintainers' discretion for the v5.x series |
| `4.x` | Security fixes, backward-compatible bug fixes, and backward-compatible features at the maintainers' discretion for the v4.x series |
