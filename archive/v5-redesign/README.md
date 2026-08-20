# Archive: the v5.x architectural redesign

This directory is the record of a finished project. Between July 2025 and the v5.0.0
release, ruby-git was restructured from `Git::Base` / `Git::Lib` into the three-layer
design it uses today: `Git::Commands::*` classes that define the CLI surface,
`Git::Parsers::*` that turn git output into value objects, and a `Git::Repository`
facade assembled from topic modules. `Git::Base` and `Git::Lib` were deleted, and all
four phases are complete.

**Nothing here is current policy.** These documents describe the code as it was before
and during the migration, and the plans they contain were carried out, abandoned, or
superseded years of commits ago. Reading them to learn how to write a command class or
a facade method will teach you the wrong thing.

Current standards live in [`.github/skills/`](../../.github/skills/) — start with
[`project-context`](../../.github/skills/project-context/SKILL.md) for the
architecture, [`command-implementation`](../../.github/skills/command-implementation/SKILL.md)
for command classes, and [`facade-implementation`](../../.github/skills/facade-implementation/SKILL.md)
for facade methods. Decisions and their reasoning live in
[`docs/adr/`](../../docs/adr/README.md). Work still to be done lives on the issue
tracker.

## What is here

| File | Contents |
| --- | --- |
| [`index.md`](index.md) | The announcement page the README linked to |
| [`1_architecture_existing.md`](1_architecture_existing.md) | Analysis of the v4.x design and its problems |
| [`2_architecture_redesign.md`](2_architecture_redesign.md) | The proposed three-layer architecture |
| [`3_architecture_implementation.md`](3_architecture_implementation.md) | The phased migration plan and progress tracker |
| [`phase-4-step-a.md`](phase-4-step-a.md) | Removing `Git::Base` and `Git::Lib` |
| [`phase-4-step-b.md`](phase-4-step-b.md) | Porting the Test::Unit suite to RSpec |
| [`phase-4-step-c.md`](phase-4-step-c.md) | The documentation pass |
| [`branch_parse_refactor_plan.md`](branch_parse_refactor_plan.md) | Branch parsing rework, completed |
| [`c1c2_audit.md`](c1c2_audit.md), [`c1c2_bucket6_lib_orphans.md`](c1c2_bucket6_lib_orphans.md) | Public-API scope audits from Step C |
| [`c1a-public-api-scope.tsv`](c1a-public-api-scope.tsv), [`phase-4-step-b-test-audit.tsv`](phase-4-step-b-test-audit.tsv) | The audit data those documents worked from |
| [`config_design.rb`](config_design.rb) | Sketch of the config API; the v5.x half shipped, the rest is the v6.x deprecation horizon |

The `Phase 4 - Step *.md` files were renamed to slugs during the move, because spaces
in filenames break shell tooling. Their content is unchanged apart from the internal
links that pointed at the old names.
