<!--
# @markup markdown
# @title Governance
-->

# Governance

This document explains how we steward the project with a light, principles-first
approach: enable trusted people, minimize dormant access, and keep decisions
transparent.

## Roles

A **Maintainer** is a trusted leader with write access who stewards the project's
health and direction. Responsibilities center on triage, review, merge, and
helping the community stay unblocked.

A **Project Lead** is a maintainer with additional administrative scope (repo
Admin, org Owner). They handle settings, secrets, access, and tie-breaks when
needed.

## Becoming a Maintainer

Maintainers invite contributors who consistently ship, review, and model our
values to become maintainers. Anyone can nominate themselves or others in an
issue or via a private note. Current maintainers discuss nominations (see
[Decision Making](#decision-making)) with a focus on contribution quality,
alignment with project goals, and communication style.

## Access Principles

- Stewardship: Maintainer access exists to keep the project healthy and responsive.
- Least privilege: Elevated access is temporary and kept only while it’s needed.
- Continuity: Dormant access is paused to protect the project and unblock
  contributors.
- Respect: Status changes are transparent, reversible, and acknowledge past
  contributions.

## How We Apply Them

- Staying active: Maintainers keep elevated access while participating (shipping,
  reviewing, triaging, or governance).
- When access is paused: If there’s no project activity for about a year, we’ll
  check in. If we don’t hear back after a short window, we move the maintainer to
  Emeritus and pause Owner/Admin/Write/package access (including CODEOWNERS
  entries).
- Coming back: Emeritus maintainers can be re-added quickly after a brief period of
  renewed participation to refresh context.
- Recognition: Emeritus maintainers remain listed to honor prior contributions.

Access changes are communicated openly (e.g., PRs or issues) and reflected in the
Maintainers list.

## Decision Making

Decisions are usually made by consensus among the active maintainers. If consensus
cannot be reached, the decision is made by a majority vote. If a vote results in a
tie, the Project Lead has the final say.

## Continuity

The project must be able to ship releases and respond to security issues even if
individual maintainers become unavailable.

### RubyGems Ownership

RubyGems ownership (the ability to push new gem versions) is granted to a subset
of active maintainers—typically the Project Lead and at least one other
maintainer—to balance security with continuity. Not all maintainers require
RubyGems access.

RubyGems owners follow the same activity principles as other elevated access: if
an owner becomes inactive, their ownership is paused alongside other permissions.

### Minimum Thresholds

To avoid single points of failure:

- At least two active maintainers should have RubyGems ownership for the `git` gem.
- At least two active maintainers should have GitHub org Owner or repo Admin
  access.

If thresholds drop below these levels, remaining maintainers should prioritize
onboarding or re-activating someone to restore redundancy.

### Access Audits

Periodically (at least annually), maintainers review access across all systems:

- GitHub organization membership and roles
- GitHub repository admin/write permissions
- RubyGems gem ownership
- GitHub Actions release automation: PATs/OIDC tokens (e.g., `AUTO_RELEASE_TOKEN` scope),
  environment protection rules/approvers for RubyGems deployments, and any OIDC
  trust configuration

The Project Lead (or a delegated maintainer) schedules and drives this review so
continuity checks do not slip.

Audits ensure access reflects current activity and that continuity thresholds are
met.

## Code of Conduct

All maintainers and contributors must adhere to the project's [Code of
Conduct](./CODE_OF_CONDUCT.md).
